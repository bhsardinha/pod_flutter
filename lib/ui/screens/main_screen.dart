import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../services/pod_controller.dart';
import '../../models/app_settings.dart';
import '../../models/patch.dart';
import '../../models/amp_models.dart';
import '../../models/cab_models.dart';
import '../../protocol/cc_map.dart';
import '../widgets/pod_modal.dart';
import '../widgets/brushed_metal_background.dart';
import '../theme/pod_theme.dart';
import '../utils/value_formatters.dart';
import '../modals/connection_modal.dart';
import '../modals/patch_library_modal.dart';
import '../modals/gate_modal.dart';
import '../modals/cab_modal.dart';
import '../modals/mic_modal.dart';
import '../modals/amp_modal.dart';
import '../modals/comp_modal.dart';
import '../widgets/effect_modal.dart';
import '../../protocol/effect_param_mappers.dart';
import '../sections/amp_selector_section.dart';
import '../sections/tone_controls_section.dart';
import '../sections/eq_section.dart';
import '../sections/effects_columns_section.dart';
import '../sections/control_bar_section.dart';
import 'settings_screen.dart';

/// Main screen for POD XT Pro controller (MODULARIZED VERSION)
class MainScreen extends StatefulWidget {
  final PodController podController;
  final AppSettings settings;

  const MainScreen({
    super.key,
    required this.podController,
    required this.settings,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Connection state
  bool _isConnected = false;
  bool _isConnecting = false;
  bool _editBufferLoaded = false; // True once we've received the initial edit buffer

  // Patch state
  int _currentProgram = 0;
  String _currentPatchName = 'Not Connected';

  // Amp/Cab state
  String _currentAmp = '--';
  String _currentCab = '--';
  String _currentMic = '--';

  // Tempo state
  int _currentBpm = 120;
  bool _isDelayTempoSynced = true;

  // Local settings (mutable copy)
  late AppSettings _settings;

  // Effect states
  bool _gateEnabled = false;
  bool _ampEnabled = true;
  bool _wahEnabled = false;
  bool _compEnabled = false;
  bool _stompEnabled = false;
  bool _modEnabled = false;
  bool _delayEnabled = false;
  bool _reverbEnabled = false;
  bool _eqEnabled = false;
  bool _loopEnabled = false;

  // Effect model names
  String? _stompModel;
  String? _modModel;
  String? _delayModel;
  String? _reverbModel;

  // Mic parameters
  int _roomValue = 64;

  // Knob values (0-127)
  int _drive = 64;
  int _bass = 64;
  int _mid = 64;
  int _treble = 64;
  int _presence = 64;
  int _volume = 100;
  int _reverbMix = 64;

  // EQ values
  double _eq1Gain = 0.0;
  double _eq2Gain = 0.0;
  double _eq3Gain = 0.0;
  double _eq4Gain = 0.0;
  int _eq1Freq = 30;
  int _eq2Freq = 50;
  int _eq3Freq = 70;
  int _eq4Freq = 90;

  // Sync progress
  bool _patchesSynced = false;
  int _syncedCount = 0;
  bool _isModified = false;

  // Amp settings
  bool _ampChainLinked = true;
  bool _ampPickerTilesView = false;
  double _ampPickerListScrollPosition = 0.0;
  double _ampPickerTilesScrollPosition = 0.0;

  // Cab picker view mode and scroll positions
  bool _cabPickerTilesView = false;
  double _cabPickerListScrollPosition = 0.0;
  double _cabPickerTilesScrollPosition = 0.0;

  // Subscriptions
  StreamSubscription<PodConnectionState>? _connectionSubscription;
  StreamSubscription<EditBuffer>? _editBufferSubscription;
  StreamSubscription<int>? _programChangeSubscription;
  StreamSubscription<SyncProgress>? _syncProgressSubscription;
  StreamSubscription<ParameterChange>? _parameterChangeSubscription;

  @override
  void initState() {
    super.initState();

    // Initialize local settings
    _settings = widget.settings;

    // Force landscape orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Subscribe to connection state changes
    _connectionSubscription = widget.podController.onConnectionStateChanged
        .listen((state) {
          setState(() {
            _isConnected = state == PodConnectionState.connected;
            _isConnecting = state == PodConnectionState.connecting;
            if (!_isConnected) {
              _editBufferLoaded = false; // Reset on disconnect
              _currentPatchName = 'Not Connected';
              _currentAmp = '--';
              _currentCab = '--';
              _currentMic = '--';
            }
          });
        });

    // Subscribe to edit buffer changes
    _editBufferSubscription = widget.podController.onEditBufferChanged.listen((
      buffer,
    ) {
      setState(() {
        _editBufferLoaded = true; // Mark as loaded once we receive first edit buffer
        _updateFromEditBuffer();
        _isModified = widget.podController.editBufferModified;
      });
    });

    // Subscribe to program changes
    _programChangeSubscription = widget.podController.onProgramChanged.listen((
      program,
    ) {
      setState(() {
        _currentProgram = program;
        // Don't call _updateFromEditBuffer() here - edit buffer update will follow
      });
    });

    // Subscribe to sync progress
    _syncProgressSubscription = widget.podController.onSyncProgress.listen((
      progress,
    ) {
      setState(() {
        _patchesSynced = progress.isComplete;
        _syncedCount = progress.current;
      });
    });

    // Subscribe to parameter changes (for real-time tempo updates)
    _parameterChangeSubscription = widget.podController.onParameterChanged
        .listen((change) {
          // Update tempo when tempo MSB or LSB changes
          if (change.param == PodXtCC.tempoMsb ||
              change.param == PodXtCC.tempoLsb) {
            setState(() {
              _currentBpm = widget.podController.currentTempoBpm;
            });
          }
          // Update delay tempo sync state when delay note select changes
          if (change.param == PodXtCC.delayNoteSelect) {
            setState(() {
              _isDelayTempoSynced = widget.podController.isDelayTempoSynced;
            });
          }
        });

    // Open connection modal on startup if not connected
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isConnected && mounted) {
        _showConnectionModal();
      }
    });
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    _editBufferSubscription?.cancel();
    _programChangeSubscription?.cancel();
    _syncProgressSubscription?.cancel();
    _parameterChangeSubscription?.cancel();

    // Reset orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    super.dispose();
  }

  void _updateFromEditBuffer() {
    // Update all state from edit buffer
    final ampId = widget.podController.getParameter(PodXtCC.ampSelect);
    final cabId = widget.podController.getParameter(PodXtCC.cabSelect);
    final micPosition = widget.podController.getParameter(PodXtCC.micSelect);

    // Sync program number from controller (fixes startup showing wrong program)
    _currentProgram = widget.podController.currentProgram;

    // Determine cab type to get correct mic name
    final cab = CabModels.byId(cabId);
    final isBXCab = cab?.pack == 'BX';

    _currentAmp = AmpModels.byId(ampId)?.name ?? '--';
    _currentCab = cab?.name ?? '--';
    _currentMic =
        MicModels.byPosition(micPosition, isBass: isBXCab)?.name ?? '--';
    _currentPatchName = widget.podController.editBuffer.patch.name.isEmpty
        ? 'Untitled'
        : widget.podController.editBuffer.patch.name;

    // Update effect states
    _gateEnabled = widget.podController.noiseGateEnabled;
    _ampEnabled = widget.podController.getSwitch(PodXtCC.ampEnable);
    _wahEnabled = widget.podController.wahEnabled;
    _compEnabled = widget.podController.compressorEnabled;
    _stompEnabled = widget.podController.stompEnabled;
    _modEnabled = widget.podController.modEnabled;
    _delayEnabled = widget.podController.delayEnabled;
    _reverbEnabled = widget.podController.reverbEnabled;
    _eqEnabled = widget.podController.eqEnabled;
    _loopEnabled = widget.podController.loopEnabled;

    // Update knob values
    _drive = widget.podController.drive;
    _bass = widget.podController.bass;
    _mid = widget.podController.mid;
    _treble = widget.podController.treble;
    _presence = widget.podController.presence;
    _volume = widget.podController.channelVolume;
    _reverbMix = widget.podController.getParameter(PodXtCC.reverbLevel);

    // Update tempo
    _currentBpm = widget.podController.currentTempoBpm;
    _isDelayTempoSynced = widget.podController.isDelayTempoSynced;

    // Update EQ
    _eq1Gain = midiToDb(widget.podController.getParameter(PodXtCC.eq1Gain));
    _eq2Gain = midiToDb(widget.podController.getParameter(PodXtCC.eq2Gain));
    _eq3Gain = midiToDb(widget.podController.getParameter(PodXtCC.eq3Gain));
    _eq4Gain = midiToDb(widget.podController.getParameter(PodXtCC.eq4Gain));
    _eq1Freq = widget.podController.getParameter(PodXtCC.eq1Freq);
    _eq2Freq = widget.podController.getParameter(PodXtCC.eq2Freq);
    _eq3Freq = widget.podController.getParameter(PodXtCC.eq3Freq);
    _eq4Freq = widget.podController.getParameter(PodXtCC.eq4Freq);

    // Update effect model names
    _stompModel = widget.podController.stompModel?.name;
    _modModel = widget.podController.modModel?.name;
    _delayModel = widget.podController.delayModel?.name;
    _reverbModel = widget.podController.reverbModel?.name;

    // Update room parameter
    _roomValue = widget.podController.room;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PodColors.background,
      body: BrushedMetalBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
              children: [
                // Row 1: Amp Selector
                Expanded(
                  flex: 2,
                  child: AmpSelectorSection(
                    podController: widget.podController,
                    isConnected: _isConnected,
                    gateEnabled: _gateEnabled,
                    ampEnabled: _ampEnabled,
                    currentAmp: _currentAmp,
                    currentCab: _currentCab,
                    currentMic: _currentMic,
                    ampChainLinked: _ampChainLinked,
                    settings: _settings,
                    onGateToggle: () => widget.podController.setSwitch(
                      PodXtCC.noiseGateEnable,
                      !_gateEnabled,
                    ),
                    onAmpToggle: () => widget.podController.setSwitch(
                      PodXtCC.ampEnable,
                      !_ampEnabled,
                    ),
                    onGateLongPress: _showGateModal,
                    onPreviousAmp: _previousAmp,
                    onNextAmp: _nextAmp,
                    onAmpTap: _showAmpPicker,
                    onChainLinkToggle: () =>
                        setState(() => _ampChainLinked = !_ampChainLinked),
                    onCabTap: _showCabPicker,
                    onMicTap: _showMicPicker,
                    onMidiTap: _showConnectionModal,
                  ),
                ),
                const SizedBox(height: 6),

                // Row 2: Tone Controls
                Expanded(
                  flex: 2,
                  child: ToneControlsSection(
                    drive: _drive,
                    bass: _bass,
                    mid: _mid,
                    treble: _treble,
                    presence: _presence,
                    volume: _volume,
                    reverbMix: _reverbMix,
                    onDriveChanged: (v) => widget.podController.setDrive(v),
                    onBassChanged: (v) => widget.podController.setBass(v),
                    onMidChanged: (v) => widget.podController.setMid(v),
                    onTrebleChanged: (v) => widget.podController.setTreble(v),
                    onPresenceChanged: (v) =>
                        widget.podController.setPresence(v),
                    onVolumeChanged: (v) =>
                        widget.podController.setChannelVolume(v),
                    onReverbMixChanged: (v) => widget.podController
                        .setParameter(PodXtCC.reverbLevel, v),
                  ),
                ),
                const SizedBox(height: 6),

                // Row 3: Effects + EQ
                Expanded(
                  flex: 4,
                  child: EffectsColumnsSection(
                    stompEnabled: _stompEnabled,
                    eqEnabled: _eqEnabled,
                    compEnabled: _compEnabled,
                    modEnabled: _modEnabled,
                    delayEnabled: _delayEnabled,
                    reverbEnabled: _reverbEnabled,
                    stompModel: _stompModel,
                    modModel: _modModel,
                    delayModel: _delayModel,
                    reverbModel: _reverbModel,
                    onStompToggle: () =>
                        widget.podController.setStompEnabled(!_stompEnabled),
                    onStompLongPress: _showStompModal,
                    onEqToggle: () =>
                        widget.podController.setEqEnabled(!_eqEnabled),
                    onEqLongPress: () {}, // No modal for EQ (inline controls)
                    onCompToggle: () => widget.podController
                        .setCompressorEnabled(!_compEnabled),
                    onCompLongPress: _showCompModal,
                    onModToggle: () =>
                        widget.podController.setModEnabled(!_modEnabled),
                    onModLongPress: _showModModal,
                    onDelayToggle: () =>
                        widget.podController.setDelayEnabled(!_delayEnabled),
                    onDelayLongPress: _showDelayModal,
                    onReverbToggle: () =>
                        widget.podController.setReverbEnabled(!_reverbEnabled),
                    onReverbLongPress: _showReverbModal,
                    eqSection: EqSection(
                      eq1Gain: _eq1Gain,
                      eq2Gain: _eq2Gain,
                      eq3Gain: _eq3Gain,
                      eq4Gain: _eq4Gain,
                      eq1Freq: _eq1Freq,
                      eq2Freq: _eq2Freq,
                      eq3Freq: _eq3Freq,
                      eq4Freq: _eq4Freq,
                      onEq1GainChanged: (v) => widget.podController
                          .setParameter(PodXtCC.eq1Gain, dbToMidi(v)),
                      onEq2GainChanged: (v) => widget.podController
                          .setParameter(PodXtCC.eq2Gain, dbToMidi(v)),
                      onEq3GainChanged: (v) => widget.podController
                          .setParameter(PodXtCC.eq3Gain, dbToMidi(v)),
                      onEq4GainChanged: (v) => widget.podController
                          .setParameter(PodXtCC.eq4Gain, dbToMidi(v)),
                      onEq1FreqChanged: (v) =>
                          widget.podController.setParameter(PodXtCC.eq1Freq, v),
                      onEq2FreqChanged: (v) =>
                          widget.podController.setParameter(PodXtCC.eq2Freq, v),
                      onEq3FreqChanged: (v) =>
                          widget.podController.setParameter(PodXtCC.eq3Freq, v),
                      onEq4FreqChanged: (v) =>
                          widget.podController.setParameter(PodXtCC.eq4Freq, v),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Row 4: Control Bar
                Expanded(
                  flex: 1,
                  child: ControlBarSection(
                    wahEnabled: _wahEnabled,
                    loopEnabled: _loopEnabled,
                    isModified: _isModified,
                    currentProgram: _currentProgram,
                    currentPatchName: _currentPatchName,
                    currentBpm: _currentBpm,
                    isDelayTempoSynced: _isDelayTempoSynced,
                    enableTempoScrolling: _settings.enableTempoScrolling,
                    onSettings: _showSettingsModal,
                    onWahToggle: () =>
                        widget.podController.setWahEnabled(!_wahEnabled),
                    onWahLongPress: _showWahModal,
                    onLoopToggle: () =>
                        widget.podController.setLoopEnabled(!_loopEnabled),
                    onPreviousPatch: _previousPatch,
                    onNextPatch: _nextPatch,
                    onPatchTap: _showPatchListModal,
                    onModifiedTap: _showModifiedIndicatorDialog,
                    onTap: () => widget.podController.sendTapTempo(),
                    onTempoChanged: (newBpm) =>
                        widget.podController.setTempo(newBpm),
                  ),
                ),
              ],
            ),
          ),
          // Loading overlay when connected but edit buffer not yet loaded
          if (_isConnected && !_editBufferLoaded)
            Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading patch data...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
        ),
      ),
    );
  }

  // Modal launchers
  void _showSettingsModal() {
    showPodModal(
      context: context,
      title: 'Settings',
      child: SettingsScreen(
        settings: _settings,
        onSettingsChanged: (newSettings) async {
          setState(() {
            _settings = newSettings;
          });
          await newSettings.save();
        },
      ),
    );
  }

  void _showConnectionModal() {
    showPodModal(
      context: context,
      title: 'Connection',
      child: ConnectionModal(
        podController: widget.podController,
        isConnected: _isConnected,
        isConnecting: _isConnecting,
        onDisconnect: () => widget.podController.disconnect(),
      ),
    );
  }

  void _showPatchListModal() {
    showDialog(
      context: context,
      barrierColor: PodColors.modalOverlay,
      builder: (dialogContext) => PatchLibraryModal(
        podController: widget.podController,
        currentProgram: _currentProgram,
        patchesSynced: _patchesSynced,
        syncedCount: _syncedCount,
        onSelectPatch: (program) async {
          // Check for unsaved changes before switching
          if (!await _checkUnsavedChanges()) return;

          widget.podController.selectProgram(program);
          if (dialogContext.mounted) Navigator.of(dialogContext).pop();
        },
      ),
    );
  }

  void _showGateModal() {
    showPodModal(
      context: context,
      title: 'Noise Gate',
      child: GateModal(
        podController: widget.podController,
        isConnected: _isConnected,
      ),
    );
  }

  void _showCabPicker() {
    showDialog(
      context: context,
      builder: (context) => CabModal(
        currentCabId: widget.podController.getParameter(PodXtCC.cabSelect),
        podController: widget.podController,
        isConnected: _isConnected,
        settings: _settings,
        initialTilesView: _cabPickerTilesView,
        initialListScrollPosition: _cabPickerListScrollPosition,
        initialTilesScrollPosition: _cabPickerTilesScrollPosition,
        onViewModeChanged: (tiles) =>
            setState(() => _cabPickerTilesView = tiles),
        onScrollPositionChanged: (list, tiles) {
          _cabPickerListScrollPosition = list;
          _cabPickerTilesScrollPosition = tiles;
        },
      ),
    );
  }

  void _showMicPicker() {
    final micPosition = widget.podController.getParameter(PodXtCC.micSelect);
    final currentCab = widget.podController.cabModel;
    final isBXCab = currentCab?.pack == 'BX';

    // Get the appropriate mic list based on cab type (guitar or bass)
    final availableMics = MicModels.forCabType(isBass: isBXCab);

    showPodModal(
      context: context,
      title: 'Select Microphone',
      child: MicModal(
        availableMics: availableMics,
        currentMicPosition: micPosition, // Always 0-3
        currentRoomValue: _roomValue,
        podController: widget.podController,
        isConnected: _isConnected,
      ),
    );
  }

  void _showAmpPicker() {
    showDialog(
      context: context,
      barrierColor: PodColors.modalOverlay,
      builder: (context) => AmpModal(
        podController: widget.podController,
        settings: _settings,
        ampChainLinked: _ampChainLinked,
        initialTilesView: _ampPickerTilesView,
        initialListScrollPosition: _ampPickerListScrollPosition,
        initialTilesScrollPosition: _ampPickerTilesScrollPosition,
        onViewModeChanged: (tiles) =>
            setState(() => _ampPickerTilesView = tiles),
        onScrollPositionChanged: (list, tiles) {
          _ampPickerListScrollPosition = list;
          _ampPickerTilesScrollPosition = tiles;
        },
      ),
    );
  }

  void _showCompModal() {
    showPodModal(
      context: context,
      title: 'Compressor',
      child: CompModal(
        podController: widget.podController,
        isConnected: _isConnected,
      ),
    );
  }

  void _showWahModal() {
    showPodModal(
      context: context,
      title: WahParamMapper().modalTitle,
      maxWidth: 750,
      child: EffectModal(
        podController: widget.podController,
        isConnected: _isConnected,
        settings: widget.settings,
        mapper: WahParamMapper(),
      ),
    );
  }

  void _showStompModal() {
    showPodModal(
      context: context,
      title: StompParamMapper().modalTitle,
      maxWidth: 750,
      child: EffectModal(
        podController: widget.podController,
        isConnected: _isConnected,
        settings: widget.settings,
        mapper: StompParamMapper(),
      ),
    );
  }

  void _showModModal() {
    showPodModal(
      context: context,
      title: ModParamMapper().modalTitle,
      maxWidth: 750,
      child: EffectModal(
        podController: widget.podController,
        isConnected: _isConnected,
        settings: widget.settings,
        mapper: ModParamMapper(),
      ),
    );
  }

  void _showDelayModal() {
    showPodModal(
      context: context,
      title: DelayParamMapper().modalTitle,
      maxWidth: 750,
      child: EffectModal(
        podController: widget.podController,
        isConnected: _isConnected,
        settings: widget.settings,
        mapper: DelayParamMapper(),
      ),
    );
  }

  void _showReverbModal() {
    showPodModal(
      context: context,
      title: ReverbParamMapper().modalTitle,
      maxWidth: 750,
      child: EffectModal(
        podController: widget.podController,
        isConnected: _isConnected,
        settings: widget.settings,
        mapper: ReverbParamMapper(),
      ),
    );
  }

  // Navigation helpers
  Future<void> _previousAmp() async {
    if (!_isConnected) return;
    final currentId = widget.podController.getParameter(PodXtCC.ampSelect);
    int newId = currentId - 1;
    if (newId < 0) newId = AmpModels.all.last.id;

    if (_ampChainLinked) {
      await widget.podController.setAmpModel(newId);
      // Request updated parameters from POD (cab, mic, EQ, etc.)
      await widget.podController.refreshEditBuffer();
    } else {
      await widget.podController.setAmpModelNoDefaults(newId);
    }
  }

  Future<void> _nextAmp() async {
    if (!_isConnected) return;
    final currentId = widget.podController.getParameter(PodXtCC.ampSelect);
    int newId = currentId + 1;
    if (newId > AmpModels.all.last.id) newId = 0;

    if (_ampChainLinked) {
      await widget.podController.setAmpModel(newId);
      // Request updated parameters from POD (cab, mic, EQ, etc.)
      await widget.podController.refreshEditBuffer();
    } else {
      await widget.podController.setAmpModelNoDefaults(newId);
    }
  }

  /// Check for unsaved changes and show warning dialog if needed
  /// Returns true if should proceed, false if cancelled
  Future<bool> _checkUnsavedChanges() async {
    // Skip check if setting is disabled or patch is not modified
    if (!_settings.warnOnUnsavedChanges || !_isModified) {
      return true;
    }

    final result = await showDialog<String>(
      context: context,
      barrierColor: PodColors.modalOverlay,
      builder: (context) => Dialog(
        backgroundColor: PodColors.background,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.6,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 56,
              ),
              const SizedBox(height: 16),
              const Text(
                'Unsaved Changes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: PodColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'The current patch has been modified.\nWhat would you like to do?',
                style: TextStyle(
                  color: PodColors.textSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, 'save_current'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PodColors.accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'SAVE TO CURRENT',
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, 'save_other'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PodColors.accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'SAVE TO OTHER',
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, 'discard'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PodColors.surfaceLight,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'DISCARD',
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context, 'cancel'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'CANCEL',
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (result == 'save_current') {
      // Save to current slot then proceed
      await _saveToCurrentSlot();
      return true; // Proceed with patch change
    } else if (result == 'save_other') {
      // Show save dialog
      await _showSaveBeforeChangeDialog();
      return false; // Don't proceed - save dialog handles it
    }

    // Return true for 'discard', false for 'cancel' or null
    return result == 'discard';
  }

  /// Show modified indicator dialog when clicking the asterisk (*)
  Future<void> _showModifiedIndicatorDialog() async {
    final result = await showDialog<String>(
      context: context,
      barrierColor: PodColors.modalOverlay,
      builder: (context) => Dialog(
        backgroundColor: PodColors.background,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.55,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.edit_outlined,
                color: PodColors.accent,
                size: 56,
              ),
              const SizedBox(height: 16),
              const Text(
                'Patch Modified',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: PodColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This patch has unsaved changes.\nWhat would you like to do?',
                style: TextStyle(
                  color: PodColors.textSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, 'save_current'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PodColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'SAVE TO CURRENT SLOT',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, 'save_other'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PodColors.surfaceLight,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'SAVE TO OTHER SLOT',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, 'discard'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'DISCARD CHANGES',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context, 'cancel'),
                    child: const Text(
                      'CANCEL',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (result == 'save_current') {
      await _saveToCurrentSlot();
    } else if (result == 'save_other') {
      await _showSaveBeforeChangeDialog();
    } else if (result == 'discard') {
      await _discardChanges();
    }
  }

  /// Save current edit buffer to the current slot
  Future<void> _saveToCurrentSlot() async {
    try {
      await widget.podController.savePatchToHardware(_currentProgram);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Discard changes and reload original patch from library
  Future<void> _discardChanges() async {
    if (_patchesSynced && _currentProgram >= 0 && _currentProgram < 128) {
      // Reload the patch from the library
      await widget.podController.selectProgram(_currentProgram);
    }
  }

  /// Show save dialog before changing patch
  Future<void> _showSaveBeforeChangeDialog() async {
    final controller = TextEditingController(text: widget.podController.editBuffer.patch.name);

    await showDialog(
      context: context,
      barrierColor: PodColors.modalOverlay,
      builder: (context) => Dialog(
        backgroundColor: PodColors.background,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Save Current Patch',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: PodColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: PodColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Editable patch name field
              TextField(
                controller: controller,
                maxLength: 16,
                style: const TextStyle(color: PodColors.textPrimary, fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Patch Name',
                  labelStyle: const TextStyle(color: PodColors.textSecondary),
                  filled: true,
                  fillColor: PodColors.surfaceLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  counterStyle: const TextStyle(color: PodColors.textSecondary),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _buildPatchGridForSave((program) {
                  Navigator.pop(context);
                  _savePatchToSlot(program, controller.text);
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Save patch to a specific slot
  Future<void> _savePatchToSlot(int slotNumber, String patchName) async {
    // Update patch name in edit buffer before saving
    widget.podController.editBuffer.patch.name = patchName;

    try {
      await widget.podController.savePatchToHardware(slotNumber);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Build patch grid for save dialog
  Widget _buildPatchGridForSave(ValueChanged<int> onTap) {
    return ListView.builder(
      itemCount: 32, // 32 banks
      itemBuilder: (context, bankIndex) {
        return _buildBankRowForSave(bankIndex, onTap);
      },
    );
  }

  Widget _buildBankRowForSave(int bankIndex, ValueChanged<int> onTap) {
    final bankNum = bankIndex + 1;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: List.generate(4, (slotIndex) {
          final program = bankIndex * 4 + slotIndex;
          final patch = widget.podController.patchLibrary[program];
          final isSelected = program == _currentProgram;
          final letter = String.fromCharCode('A'.codeUnitAt(0) + slotIndex);
          final slotLabel = '$bankNum$letter';

          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(program),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? PodColors.accent.withValues(alpha: 0.25)
                      : PodColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? PodColors.accent
                        : PodColors.surfaceLight,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      slotLabel,
                      style: TextStyle(
                        color: isSelected
                            ? PodColors.accent
                            : PodColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        patch.name.isEmpty ? '(empty)' : patch.name,
                        style: TextStyle(
                          color: isSelected
                              ? PodColors.textPrimary
                              : patch.name.isEmpty
                                  ? PodColors.textSecondary.withValues(alpha: 0.6)
                                  : PodColors.textPrimary,
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  void _previousPatch() async {
    if (!_isConnected) return;

    // Check for unsaved changes
    if (!await _checkUnsavedChanges()) return;

    final newProgram = (_currentProgram - 1).clamp(0, 127);
    widget.podController.selectProgram(newProgram);
  }

  void _nextPatch() async {
    if (!_isConnected) return;

    // Check for unsaved changes
    if (!await _checkUnsavedChanges()) return;

    final newProgram = (_currentProgram + 1).clamp(0, 127);
    widget.podController.selectProgram(newProgram);
  }
}
