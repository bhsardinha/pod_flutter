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
import '../theme/pod_theme.dart';
import '../utils/value_formatters.dart';
import '../modals/connection_modal.dart';
import '../modals/patch_list_modal.dart';
import '../modals/gate_modal.dart';
import '../modals/cab_modal.dart';
import '../modals/mic_modal.dart';
import '../modals/amp_modal.dart';
import '../modals/comp_modal.dart';
import '../modals/wah_modal.dart';
import '../modals/stomp_modal.dart';
import '../modals/mod_modal.dart';
import '../modals/delay_modal.dart';
import '../modals/reverb_modal.dart';
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

  // Patch state
  int _currentProgram = 0;
  String _currentPatchName = 'Not Connected';

  // Amp/Cab state
  String _currentAmp = '--';
  String _currentCab = '--';
  String _currentMic = '--';

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

  // Gate and mic parameters
  int _gateThreshold = 0;
  int _gateDecay = 64;
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

  // Subscriptions
  StreamSubscription<PodConnectionState>? _connectionSubscription;
  StreamSubscription<EditBuffer>? _editBufferSubscription;
  StreamSubscription<int>? _programChangeSubscription;
  StreamSubscription<SyncProgress>? _syncProgressSubscription;

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
    _connectionSubscription = widget.podController.onConnectionStateChanged.listen((state) {
      setState(() {
        _isConnected = state == PodConnectionState.connected;
        _isConnecting = state == PodConnectionState.connecting;
        if (!_isConnected) {
          _currentPatchName = 'Not Connected';
          _currentAmp = '--';
          _currentCab = '--';
          _currentMic = '--';
        }
      });
    });

    // Subscribe to edit buffer changes
    _editBufferSubscription = widget.podController.onEditBufferChanged.listen((buffer) {
      setState(() {
        _updateFromEditBuffer();
        _isModified = widget.podController.editBufferModified;
      });
    });

    // Subscribe to program changes
    _programChangeSubscription = widget.podController.onProgramChanged.listen((program) {
      setState(() {
        _currentProgram = program;
        _updateFromEditBuffer();
      });
    });

    // Subscribe to sync progress
    _syncProgressSubscription = widget.podController.onSyncProgress.listen((progress) {
      setState(() {
        _patchesSynced = progress.isComplete;
        _syncedCount = progress.current;
      });
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
    _currentMic = MicModels.byPosition(micPosition, isBass: isBXCab)?.name ?? '--';
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

    // Update gate and room parameters
    _gateThreshold = widget.podController.gateThreshold;
    _gateDecay = widget.podController.getParameter(PodXtCC.gateDecay);
    _roomValue = widget.podController.room;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PodColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
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
                  onGateToggle: () => widget.podController.setSwitch(PodXtCC.noiseGateEnable, !_gateEnabled),
                  onAmpToggle: () => widget.podController.setSwitch(PodXtCC.ampEnable, !_ampEnabled),
                  onGateLongPress: _showGateModal,
                  onPreviousAmp: _previousAmp,
                  onNextAmp: _nextAmp,
                  onAmpTap: _showAmpPicker,
                  onChainLinkToggle: () => setState(() => _ampChainLinked = !_ampChainLinked),
                  onCabTap: _showCabPicker,
                  onMicTap: _showMicPicker,
                ),
              ),
              const SizedBox(height: 12),

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
                  onPresenceChanged: (v) => widget.podController.setPresence(v),
                  onVolumeChanged: (v) => widget.podController.setChannelVolume(v),
                  onReverbMixChanged: (v) => widget.podController.setParameter(PodXtCC.reverbLevel, v),
                ),
              ),
              const SizedBox(height: 12),

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
                  onStompToggle: () => widget.podController.setStompEnabled(!_stompEnabled),
                  onStompLongPress: _showStompModal,
                  onEqToggle: () => widget.podController.setEqEnabled(!_eqEnabled),
                  onEqLongPress: () {}, // No modal for EQ (inline controls)
                  onCompToggle: () => widget.podController.setCompressorEnabled(!_compEnabled),
                  onCompLongPress: _showCompModal,
                  onModToggle: () => widget.podController.setModEnabled(!_modEnabled),
                  onModLongPress: _showModModal,
                  onDelayToggle: () => widget.podController.setDelayEnabled(!_delayEnabled),
                  onDelayLongPress: _showDelayModal,
                  onReverbToggle: () => widget.podController.setReverbEnabled(!_reverbEnabled),
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
                    onEq1GainChanged: (v) => widget.podController.setParameter(PodXtCC.eq1Gain, dbToMidi(v)),
                    onEq2GainChanged: (v) => widget.podController.setParameter(PodXtCC.eq2Gain, dbToMidi(v)),
                    onEq3GainChanged: (v) => widget.podController.setParameter(PodXtCC.eq3Gain, dbToMidi(v)),
                    onEq4GainChanged: (v) => widget.podController.setParameter(PodXtCC.eq4Gain, dbToMidi(v)),
                    onEq1FreqChanged: (v) => widget.podController.setParameter(PodXtCC.eq1Freq, v),
                    onEq2FreqChanged: (v) => widget.podController.setParameter(PodXtCC.eq2Freq, v),
                    onEq3FreqChanged: (v) => widget.podController.setParameter(PodXtCC.eq3Freq, v),
                    onEq4FreqChanged: (v) => widget.podController.setParameter(PodXtCC.eq4Freq, v),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Row 4: Control Bar
              Expanded(
                flex: 1,
                child: ControlBarSection(
                  isConnected: _isConnected,
                  wahEnabled: _wahEnabled,
                  loopEnabled: _loopEnabled,
                  isModified: _isModified,
                  currentProgram: _currentProgram,
                  currentPatchName: _currentPatchName,
                  onSettings: _showSettingsModal,
                  onWahToggle: () => widget.podController.setWahEnabled(!_wahEnabled),
                  onWahLongPress: _showWahModal,
                  onLoopToggle: () => widget.podController.setLoopEnabled(!_loopEnabled),
                  onPreviousPatch: _previousPatch,
                  onNextPatch: _nextPatch,
                  onPatchTap: _showPatchListModal,
                  onTap: () {}, // TODO: Tap tempo
                  onMidiTap: _showConnectionModal,
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
    showPodModal(
      context: context,
      title: 'Patch Library',
      child: PatchListModal(
        podController: widget.podController,
        currentProgram: _currentProgram,
        patchesSynced: _patchesSynced,
        syncedCount: _syncedCount,
        onSelectPatch: (program) {
          widget.podController.selectProgram(program);
          Navigator.of(context).pop();
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
      barrierColor: PodColors.modalOverlay,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Center(
          child: Container(
            decoration: BoxDecoration(
              color: PodColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: PodColors.surfaceLight, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: PodColors.surfaceLight, width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select Cabinet',
                        style: TextStyle(
                          color: PodColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: PodColors.textSecondary),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                // Content
                CabModal(
                  currentCabId: widget.podController.getParameter(PodXtCC.cabSelect),
                  podController: widget.podController,
                  isConnected: _isConnected,
                ),
              ],
            ),
          ),
        ),
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
        onViewModeChanged: (tiles) => setState(() => _ampPickerTilesView = tiles),
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
      title: 'Wah',
      child: WahModal(
        podController: widget.podController,
        isConnected: _isConnected,
      ),
    );
  }

  void _showStompModal() {
    showPodModal(
      context: context,
      title: 'Stomp',
      child: StompModal(
        podController: widget.podController,
        isConnected: _isConnected,
      ),
    );
  }

  void _showModModal() {
    showPodModal(
      context: context,
      title: 'Modulation',
      child: ModModal(
        podController: widget.podController,
        isConnected: _isConnected,
      ),
    );
  }

  void _showDelayModal() {
    showPodModal(
      context: context,
      title: 'Delay',
      child: DelayModal(
        podController: widget.podController,
        isConnected: _isConnected,
      ),
    );
  }

  void _showReverbModal() {
    showPodModal(
      context: context,
      title: 'Reverb',
      child: ReverbModal(
        podController: widget.podController,
        isConnected: _isConnected,
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

  void _previousPatch() {
    if (!_isConnected) return;
    final newProgram = (_currentProgram - 1).clamp(0, 127);
    widget.podController.selectProgram(newProgram);
  }

  void _nextPatch() {
    if (!_isConnected) return;
    final newProgram = (_currentProgram + 1).clamp(0, 127);
    widget.podController.selectProgram(newProgram);
  }
}
