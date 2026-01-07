import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/pod_theme.dart';
import '../widgets/effect_button.dart';
import '../widgets/rotary_knob.dart';
import '../widgets/vertical_fader.dart';
import '../widgets/connection_indicator.dart';
import '../widgets/patch_browser.dart';
import '../widgets/pod_modal.dart';
import '../widgets/dot_matrix_lcd.dart';
import 'settings_screen.dart';
import '../../services/ble_midi_service.dart';
import '../../services/pod_controller.dart';
import '../../services/midi_service.dart';
import '../../protocol/cc_map.dart';
import '../../models/patch.dart';
import '../../models/app_settings.dart';
import '../../models/amp_models.dart';
import '../../models/cab_models.dart';

/// Main screen of the POD XT Pro controller app.
///
/// Horizontal/landscape layout with:
/// - Top row: GATE button, AMP selector, CAB/MIC
/// - Knobs row: Drive, Bass, Mid, Treble, Presence, Vol
/// - EQ row: 4-band bipolar faders with freq knobs, EQ button
/// - Effects row: WAH, STOMP, MOD, DELAY, REVERB
/// - Bottom bar: Patch browser, connection indicator
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // EQ frequency ranges (Hz) for each band - from pod-ui config
  static const _eq1FreqRange = (min: 50.0, max: 690.0); // LOW
  static const _eq2FreqRange = (min: 50.0, max: 6050.0); // LO MID
  static const _eq3FreqRange = (min: 100.0, max: 11300.0); // HI MID
  static const _eq4FreqRange = (min: 500.0, max: 9300.0); // HIGH

  // MIDI Services
  late final BleMidiService _midiService;
  late final PodController _podController;
  final List<StreamSubscription> _subscriptions = [];

  /// Format a MIDI value (0-127) as a 0.0-10.0 scale
  String _formatKnobValue(int value) {
    final scaled = (value / 127.0 * 10.0);
    return scaled.toStringAsFixed(1);
  }

  /// Format EQ frequency value using the device's stepped scaling per band.
  ///
  /// The mapping follows the piecewise increments you described for each band.
  String _formatEqFreq(
    int midiValue,
    int band,
    ({double min, double max}) range,
  ) {
    int freq = _midiEqFreqToHz(midiValue, band, range);
    if (freq >= 1000) {
      return '${(freq / 1000).toStringAsFixed(1)}k';
    }
    return '$freq';
  }

  /// Convert a MIDI 0-127 EQ frequency value to Hz using stepped rules.
  int _midiEqFreqToHz(
    int midiValue,
    int band,
    ({double min, double max}) range,
  ) {
    // Ensure midiValue in [0,127]
    final steps = midiValue.clamp(0, 127);

    // Starting frequency depends on band (use provided range.min where appropriate)
    int freq;
    if (band == 1) {
      // Band 1: start 50 Hz, +5 Hz per step
      // Special-case: ensure maximum step (127) maps to 690 Hz
      if (steps >= 127) {
        return 690;
      }
      freq = 50 + steps * 5;
      return freq.clamp(range.min.toInt(), range.max.toInt());
    }

    // For bands 2-4 start from the band's minimum frequency
    freq = range.min.toInt();

    for (int i = 0; i < steps; i++) {
      int stepSize;
      if (band == 2) {
        // Band 2: 5Hz until <130, then 10Hz until <450, then 50Hz until <2900, then 100Hz afterwards
        if (freq < 130) {
          stepSize = 5;
        } else if (freq < 450) {
          stepSize = 10;
        } else if (freq < 2900) {
          stepSize = 50;
        } else if (freq < 5800) {
          stepSize = 100;
        } else {
          stepSize = 200;
        }
      } else if (band == 3) {
        // Band 3: 50Hz steps until <1700, then 100Hz
        stepSize = freq < 1700 ? 50 : 100;
      } else if (band == 4) {
        // Band 4: four lanes with arbitrary thresholds for manual tuning.
        // Lane thresholds are intentionally 'random' so you can adjust them.
        if (freq < 1300) {
          // lane 1: fine-grain first step
          stepSize = 25;
        } else if (freq < 2900) {
          // lane 2
          stepSize = 50;
        } else if (freq < 9100) {
          stepSize = 100;
        } else {
          stepSize = 200;
        }
      } else {
        // Fallback: linear logarithmic-ish step
        stepSize = 1;
      }

      freq += stepSize;
      // Cap at band's max
      if (freq >= range.max) {
        freq = range.max.toInt();
        break;
      }
    }

    return freq;
  }

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

  // Effect states
  bool _gateEnabled = false;
  bool _ampEnabled = true; // Amp enabled (true = amp ON)
  bool _wahEnabled = false;
  bool _compEnabled = false;
  bool _stompEnabled = false;
  bool _modEnabled = false;
  bool _delayEnabled = false;
  bool _reverbEnabled = false;
  bool _eqEnabled = false;
  bool _loopEnabled = false;

  // Effect model names
  String _wahModel = '';
  String _stompModel = '';
  String _modModel = '';
  String _delayModel = '';
  String _reverbModel = '';

  // Knob values (0-127)
  int _drive = 64;
  int _bass = 64;
  int _mid = 64;
  int _treble = 64;
  int _presence = 64;
  int _volume = 100;
  int _reverbMix = 64; // REVERB knob for Row 2
  int _roomValue = 64; // Room percentage for mic modal
  int _gateThreshold = 0; // Gate threshold (0-96)
  int _gateDecay = 64; // Gate decay (0-127)

  // EQ gain values (-12.8 to +12.6 dB)
  double _eq1Gain = 0.0;
  double _eq2Gain = 0.0;
  double _eq3Gain = 0.0;
  double _eq4Gain = 0.0;

  // EQ frequencies (0-127)
  int _eq1Freq = 30;
  int _eq2Freq = 50;
  int _eq3Freq = 70;
  int _eq4Freq = 90;

  // Sync progress
  bool _patchesSynced = false;
  int _syncedCount = 0;

  // Modified indicator
  bool _isModified = false;

  // Amp chain link - when true, changing amp loads defaults; when false, preserves settings
  bool _ampChainLinked = false;

  // Amp picker view mode preference
  bool _ampPickerTilesView = false;

  // Amp picker scroll positions
  double _ampPickerListScrollPosition = 0.0;
  double _ampPickerTilesScrollPosition = 0.0;

  // App settings
  AppSettings _settings = AppSettings();

  @override
  void initState() {
    super.initState();
    // Force landscape orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Load settings
    _loadSettings();

    // Initialize MIDI services
    _midiService = BleMidiService();
    _podController = PodController(_midiService);

    // Listen for connection state changes
    _subscriptions.add(
      _podController.onConnectionStateChanged.listen((state) {
        setState(() {
          _isConnected = state == PodConnectionState.connected;
          _isConnecting = state == PodConnectionState.connecting;
        });
      }),
    );

    // Listen for edit buffer changes (updates from device)
    _subscriptions.add(
      _podController.onEditBufferChanged.listen((buffer) {
        _updateFromEditBuffer(buffer);
        // Check if buffer differs from stored patch
        setState(() {
          _isModified = _podController.editBufferModified;
        });
      }),
    );

    // Listen for parameter changes from device
    _subscriptions.add(
      _podController.onParameterChanged.listen((change) {
        _handleParameterChange(change);
      }),
    );

    // Listen for program changes
    _subscriptions.add(
      _podController.onProgramChanged.listen((program) {
        setState(() {
          _currentProgram = program;
          _currentPatchName = _formatProgramName(program);
        });
      }),
    );

    // Listen for sync progress
    _subscriptions.add(
      _podController.onSyncProgress.listen((progress) {
        setState(() {
          _patchesSynced = progress.isComplete;
          _syncedCount = progress.current;
        });
      }),
    );

    // Open connection screen on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showConnectionScreen();
    });
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _podController.dispose();
    _midiService.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  String _formatProgramName(int program) {
    final bank = (program ~/ 4) + 1;
    final letter = String.fromCharCode('A'.codeUnitAt(0) + (program % 4));
    return '${bank.toString().padLeft(2, '0')}$letter';
  }

  Future<void> _loadSettings() async {
    final settings = await AppSettings.load();
    setState(() {
      _settings = settings;
    });
  }

  void _showSettings() {
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

  void _updateFromEditBuffer(EditBuffer buffer) {
    setState(() {
      // Patch name
      _currentPatchName = buffer.patch.name.isNotEmpty
          ? buffer.patch.name
          : 'Untitled';
      _currentProgram = buffer.sourceProgram ?? _currentProgram;

      // Amp/Cab/Mic
      final amp = _podController.ampModel;
      final cab = _podController.cabModel;
      final micPosition = _podController.getParameter(PodXtCC.micSelect);
      final isBXCab = cab?.pack == 'BX';

      // Map mic position to correct model based on cabinet type
      final micId = isBXCab ? micPosition + 4 : micPosition;
      final mic = MicModels.byId(micId);

      _currentAmp = amp?.name ?? '--';
      _currentCab = cab?.name ?? '--';
      _currentMic = mic?.name ?? '--';

      // Knobs
      _drive = _podController.drive;
      _bass = _podController.bass;
      _mid = _podController.mid;
      _treble = _podController.treble;
      _presence = _podController.presence;
      _volume = _podController.channelVolume;
      _reverbMix = _podController.reverbLevel;
      _roomValue = _podController.room;
      _gateThreshold = _podController.gateThreshold;
      _gateDecay = _podController.getParameter(PodXtCC.gateDecay);

      // Effect enables
      _gateEnabled = _podController.noiseGateEnabled;
      _ampEnabled = _podController.getSwitch(PodXtCC.ampEnable);
      _wahEnabled = _podController.wahEnabled;
      _compEnabled = _podController.compressorEnabled;
      _stompEnabled = _podController.stompEnabled;
      _modEnabled = _podController.modEnabled;
      _delayEnabled = _podController.delayEnabled;
      _reverbEnabled = _podController.reverbEnabled;
      _eqEnabled = _podController.eqEnabled;
      _loopEnabled = _podController.loopEnabled;

      // Effect models
      _wahModel = _podController.wahModel?.name ?? '';
      _stompModel = _podController.stompModel?.name ?? '';
      _modModel = _podController.modModel?.name ?? '';
      _delayModel = _podController.delayModel?.name ?? '';
      _reverbModel = _podController.reverbModel?.name ?? '';

      // EQ frequencies
      _eq1Freq = _podController.getParameter(PodXtCC.eq1Freq);
      _eq2Freq = _podController.getParameter(PodXtCC.eq2Freq);
      _eq3Freq = _podController.getParameter(PodXtCC.eq3Freq);
      _eq4Freq = _podController.getParameter(PodXtCC.eq4Freq);

      // EQ gains (convert 0-127 to -12.8 to +12.6 dB)
      final eq1Midi = _podController.getParameter(PodXtCC.eq1Gain);
      final eq2Midi = _podController.getParameter(PodXtCC.eq2Gain);
      final eq3Midi = _podController.getParameter(PodXtCC.eq3Gain);
      final eq4Midi = _podController.getParameter(PodXtCC.eq4Gain);

      _eq1Gain = _midiToDb(eq1Midi);
      _eq2Gain = _midiToDb(eq2Midi);
      _eq3Gain = _midiToDb(eq3Midi);
      _eq4Gain = _midiToDb(eq4Midi);
      // Debug print removed: EQ gain updates are applied to state.
    });
  }

  void _handleParameterChange(ParameterChange change) {
    // Individual parameter updates are handled by _updateFromEditBuffer
    // This is for any additional real-time handling if needed
  }

  // Convert MIDI value (0-127) to dB (-12.8 to +12.6)
  // Formula from pod-ui: dB = (25.4 / 127.0) * midi - 12.8
  double _midiToDb(int midi) {
    return (25.4 / 127.0) * midi - 12.8;
  }

  // Convert dB (-12.8 to +12.6) to MIDI value (0-127)
  // Formula: midi = (dB + 12.8) * 127.0 / 25.4
  int _dbToMidi(double db) {
    return ((db + 12.8) * 127.0 / 25.4).round().clamp(0, 127);
  }

  void _showEffectModal(String effectName) {
    showPodModal(
      context: context,
      title: '$effectName Parameters',
      child: Center(
        child: Text(
          '$effectName parameters coming soon...',
          style: const TextStyle(color: PodColors.textSecondary),
        ),
      ),
    );
  }

  void _showGateModal() {
    showPodModal(
      context: context,
      title: 'Noise Gate',
      child: _GateModal(
        podController: _podController,
        isConnected: _isConnected,
      ),
    );
  }

  void _showAmpPicker() {
    showDialog(
      context: context,
      builder: (context) => _AmpPickerModal(
        podController: _podController,
        settings: _settings,
        ampChainLinked: _ampChainLinked,
        initialTilesView: _ampPickerTilesView,
        initialListScrollPosition: _ampPickerListScrollPosition,
        initialTilesScrollPosition: _ampPickerTilesScrollPosition,
        onViewModeChanged: (isTiles) {
          setState(() {
            _ampPickerTilesView = isTiles;
          });
        },
        onScrollPositionChanged: (listPos, tilesPos) {
          setState(() {
            _ampPickerListScrollPosition = listPos;
            _ampPickerTilesScrollPosition = tilesPos;
          });
        },
      ),
    );
  }

  void _previousAmp() async {
    if (!_isConnected) return;
    final currentId = _podController.getParameter(PodXtCC.ampSelect);
    // Find previous amp (wrap around from 0 to last)
    int prevId = currentId - 1;
    if (prevId < 0) prevId = AmpModels.all.last.id;
    // Use chain link setting to determine which method to use
    if (_ampChainLinked) {
      await _podController.setAmpModel(prevId); // Load amp defaults
    } else {
      await _podController.setAmpModelNoDefaults(prevId); // Preserve settings
    }
    // Request updated parameters from POD
    await _podController.refreshEditBuffer();
  }

  void _nextAmp() async {
    if (!_isConnected) return;
    final currentId = _podController.getParameter(PodXtCC.ampSelect);
    // Find next amp (wrap around from last to 0)
    int nextId = currentId + 1;
    if (nextId > AmpModels.all.last.id) nextId = 0;
    // Use chain link setting to determine which method to use
    if (_ampChainLinked) {
      await _podController.setAmpModel(nextId); // Load amp defaults
    } else {
      await _podController.setAmpModelNoDefaults(nextId); // Preserve settings
    }
    // Request updated parameters from POD
    await _podController.refreshEditBuffer();
  }

  void _showCabPicker() {
    final currentCabId = _podController.getParameter(PodXtCC.cabSelect);

    showPodModal(
      context: context,
      title: 'Select Cabinet',
      maxWidth: MediaQuery.of(context).size.width * 0.95, // 95% of screen width
      child: _CabPickerModal(
        currentCabId: currentCabId,
        podController: _podController,
        isConnected: _isConnected,
      ),
    );
  }

  void _showMicPicker() {
    final currentMicId = _podController.getParameter(PodXtCC.micSelect);
    final currentCab = _podController.cabModel;
    final isBXCab = currentCab?.pack == 'BX';

    // Filter mics based on current cabinet
    final availableMics = MicModels.all.where((mic) {
      // BX mics only available with BX cabs
      if (mic.pack == 'BX') return isBXCab;
      // Stock mics always available with non-BX cabs
      return !isBXCab;
    }).toList();

    showPodModal(
      context: context,
      title: 'Select Microphone',
      child: _MicPickerModal(
        availableMics: availableMics,
        currentMicId: currentMicId,
        currentRoomValue: _roomValue,
        podController: _podController,
        isConnected: _isConnected,
      ),
    );
  }

  void _showPatchList() {
    showPodModal(
      context: context,
      title: 'Select Patch',
      child: _PatchListModal(
        podController: _podController,
        currentProgram: _currentProgram,
        patchesSynced: _patchesSynced,
        syncedCount: _syncedCount,
        onSelectPatch: (program) {
          _podController.selectProgram(program);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showConnectionScreen() {
    showPodModal(
      context: context,
      title: _isConnected ? 'Connected' : 'Connect to Device',
      child: _ConnectionPanel(
        podController: _podController,
        isConnected: _isConnected,
        isConnecting: _isConnecting,
        onDisconnect: () {
          _podController.disconnect();
          Navigator.of(context).pop();
        },
      ),
    );
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
              // Row 1: GATE/AMP | LCD | CAB/MIC (22.22%)
              Expanded(flex: 2, child: _buildRow1()),
              const SizedBox(height: 12),

              // Row 2: 7 Knobs (22.22%)
              Expanded(flex: 2, child: _buildRow2()),
              const SizedBox(height: 12),

              // Row 3: Effects | EQ | Effects (44.44%)
              Expanded(flex: 4, child: _buildRow3()),
              const SizedBox(height: 12),

              // Row 4: Settings | WAH | FX | Presets | TAP | MIDI (11.11%)
              Expanded(flex: 1, child: _buildRow4()),
            ],
          ),
        ),
      ),
    );
  }

  // Helper for CAB/MIC dropdown buttons (no fixed height)
  Widget _buildDropdownButton({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: PodColors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: PodColors.surfaceLight, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: PodColors.textSecondary,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: PodColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            // Dropdown arrow removed per UI update; whole button is tappable
          ],
        ),
      ),
    );
  }

  // Row 1: 3/10/3 layout - GATE/AMP stacked | LCD | CAB/MIC stacked
  Widget _buildRow1() {
    return Row(
      children: [
        // Left: GATE and AMP stacked (flex 3)
        Expanded(
          flex: 3,
          child: Column(
            children: [
              Expanded(
                child: EffectButton(
                  label: 'GATE',
                  isOn: _gateEnabled,
                  onTap: () {
                    final newState = !_gateEnabled;
                    setState(() => _gateEnabled = newState);
                    if (_isConnected)
                      _podController.setNoiseGateEnabled(newState);
                  },
                  onLongPress: _showGateModal,
                  color: PodColors.buttonOnGreen,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: EffectButton(
                  label: 'AMP',
                  isOn: _ampEnabled,
                  onTap: () {
                    final newState = !_ampEnabled;
                    setState(() => _ampEnabled = newState);
                    if (_isConnected)
                      _podController.setSwitch(PodXtCC.ampEnable, newState);
                  },
                  onLongPress: () {},
                  color: PodColors.buttonOnAmber,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),

        // Center: Large LCD selector (flex 10)
        Expanded(flex: 10, child: _buildAmpSelector()),
        const SizedBox(width: 12),

        // Right: CAB and MIC stacked (flex 3)
        Expanded(
          flex: 3,
          child: Column(
            children: [
              Expanded(
                child: _buildDropdownButton(
                  label: 'CAB',
                  value: _currentCab,
                  onTap: _showCabPicker,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _buildDropdownButton(
                  label: 'MIC',
                  value: _currentMic,
                  onTap: _showMicPicker,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Row 2: 1/14/1 layout - 7 Knobs with spacers
  Widget _buildRow2() {
    return Row(
      children: [
        // scaled flex: 0.2 / 15.6 / 0.2 -> multiply by 10 => 2 / 156 / 2
        const Expanded(flex: 2, child: SizedBox()),
        Expanded(
          flex: 156,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              RotaryKnob(
                label: 'GAIN',
                value: _drive,
                onValueChanged: (v) {
                  setState(() => _drive = v);
                  if (_isConnected) _podController.setDrive(v);
                },
                size: 72,
                valueFormatter: _formatKnobValue,
              ),
              RotaryKnob(
                label: 'BASS',
                value: _bass,
                onValueChanged: (v) {
                  setState(() => _bass = v);
                  if (_isConnected) _podController.setBass(v);
                },
                size: 72,
                valueFormatter: _formatKnobValue,
              ),
              RotaryKnob(
                label: 'MID',
                value: _mid,
                onValueChanged: (v) {
                  setState(() => _mid = v);
                  if (_isConnected) _podController.setMid(v);
                },
                size: 72,
                valueFormatter: _formatKnobValue,
              ),
              RotaryKnob(
                label: 'TREBLE',
                value: _treble,
                onValueChanged: (v) {
                  setState(() => _treble = v);
                  if (_isConnected) _podController.setTreble(v);
                },
                size: 72,
                valueFormatter: _formatKnobValue,
              ),
              RotaryKnob(
                label: 'PRES',
                value: _presence,
                onValueChanged: (v) {
                  setState(() => _presence = v);
                  if (_isConnected) _podController.setPresence(v);
                },
                size: 72,
                valueFormatter: _formatKnobValue,
              ),
              RotaryKnob(
                label: 'VOL',
                value: _volume,
                onValueChanged: (v) {
                  setState(() => _volume = v);
                  if (_isConnected) _podController.setChannelVolume(v);
                },
                size: 72,
                valueFormatter: _formatKnobValue,
              ),
              RotaryKnob(
                label: 'REVERB',
                value: _reverbMix,
                onValueChanged: (v) {
                  setState(() => _reverbMix = v);
                  if (_isConnected) _podController.setReverbLevel(v);
                },
                size: 72,
                valueFormatter: _formatKnobValue,
              ),
            ],
          ),
        ),
        const Expanded(flex: 2, child: SizedBox()),
      ],
    );
  }

  // Row 3: 4/8/4 layout - Effects | EQ | Effects
  Widget _buildRow3() {
    return Row(
      children: [
        // Left effects column (flex 4)
        Expanded(
          flex: 4,
          child: Column(
            children: [
              Expanded(
                child: EffectButton(
                  label: 'STOMP',
                  modelName: _stompModel,
                  isOn: _stompEnabled,
                  onTap: () {
                    final newState = !_stompEnabled;
                    setState(() => _stompEnabled = newState);
                    if (_isConnected) _podController.setStompEnabled(newState);
                  },
                  onLongPress: () => _showEffectModal('Stomp'),
                  color: PodColors.buttonOnGreen,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: EffectButton(
                  label: 'EQ',
                  isOn: _eqEnabled,
                  onTap: () {
                    final newState = !_eqEnabled;
                    setState(() => _eqEnabled = newState);
                    if (_isConnected) _podController.setEqEnabled(newState);
                  },
                  onLongPress: () {},
                  color: PodColors.buttonOnAmber,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: EffectButton(
                  label: 'COMP',
                  isOn: _compEnabled,
                  onTap: () {
                    final newState = !_compEnabled;
                    setState(() => _compEnabled = newState);
                    if (_isConnected)
                      _podController.setCompressorEnabled(newState);
                  },
                  onLongPress: () => _showEffectModal('Comp'),
                  color: PodColors.buttonOnGreen,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),

        // Center EQ section (flex 8)
        Expanded(flex: 8, child: _buildEqSection()),
        const SizedBox(width: 12),

        // Right effects column (flex 4)
        Expanded(
          flex: 4,
          child: Column(
            children: [
              Expanded(
                child: EffectButton(
                  label: 'MOD',
                  modelName: _modModel,
                  isOn: _modEnabled,
                  onTap: () {
                    final newState = !_modEnabled;
                    setState(() => _modEnabled = newState);
                    if (_isConnected) _podController.setModEnabled(newState);
                  },
                  onLongPress: () => _showEffectModal('Mod'),
                  color: PodColors.buttonOnGreen,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: EffectButton(
                  label: 'DELAY',
                  modelName: _delayModel,
                  isOn: _delayEnabled,
                  onTap: () {
                    final newState = !_delayEnabled;
                    setState(() => _delayEnabled = newState);
                    if (_isConnected) _podController.setDelayEnabled(newState);
                  },
                  onLongPress: () => _showEffectModal('Delay'),
                  color: PodColors.buttonOnGreen,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: EffectButton(
                  label: 'REVERB',
                  modelName: _reverbModel,
                  isOn: _reverbEnabled,
                  onTap: () {
                    final newState = !_reverbEnabled;
                    setState(() => _reverbEnabled = newState);
                    if (_isConnected) _podController.setReverbEnabled(newState);
                  },
                  onLongPress: () => _showEffectModal('Reverb'),
                  color: PodColors.buttonOnGreen,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEqSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PodColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: PodColors.surfaceLight, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildEqBand(
              label: 'LOW',
              gain: _eq1Gain,
              onGainChanged: (v) {
                setState(() => _eq1Gain = v);
                if (_isConnected)
                  _podController.setParameter(PodXtCC.eq1Gain, _dbToMidi(v));
              },
              freq: _eq1Freq,
              onFreqChanged: (v) {
                setState(() => _eq1Freq = v);
                if (_isConnected)
                  _podController.setParameter(PodXtCC.eq1Freq, v);
              },
              freqRange: _eq1FreqRange,
              band: 1,
            ),
          ),
          Expanded(
            child: _buildEqBand(
              label: 'LO MID',
              gain: _eq2Gain,
              onGainChanged: (v) {
                setState(() => _eq2Gain = v);
                if (_isConnected)
                  _podController.setParameter(PodXtCC.eq2Gain, _dbToMidi(v));
              },
              freq: _eq2Freq,
              onFreqChanged: (v) {
                setState(() => _eq2Freq = v);
                if (_isConnected)
                  _podController.setParameter(PodXtCC.eq2Freq, v);
              },
              freqRange: _eq2FreqRange,
              band: 2,
            ),
          ),
          Expanded(
            child: _buildEqBand(
              label: 'HI MID',
              gain: _eq3Gain,
              onGainChanged: (v) {
                setState(() => _eq3Gain = v);
                if (_isConnected)
                  _podController.setParameter(PodXtCC.eq3Gain, _dbToMidi(v));
              },
              freq: _eq3Freq,
              onFreqChanged: (v) {
                setState(() => _eq3Freq = v);
                if (_isConnected)
                  _podController.setParameter(PodXtCC.eq3Freq, v);
              },
              freqRange: _eq3FreqRange,
              band: 3,
            ),
          ),
          Expanded(
            child: _buildEqBand(
              label: 'HIGH',
              gain: _eq4Gain,
              onGainChanged: (v) {
                setState(() => _eq4Gain = v);
                if (_isConnected)
                  _podController.setParameter(PodXtCC.eq4Gain, _dbToMidi(v));
              },
              freq: _eq4Freq,
              onFreqChanged: (v) {
                setState(() => _eq4Freq = v);
                if (_isConnected)
                  _podController.setParameter(PodXtCC.eq4Freq, v);
              },
              freqRange: _eq4FreqRange,
              band: 4,
            ),
          ),
        ],
      ),
    );
  }

  // Row 4: 1/1/1/10/2/1 layout - Settings | WAH | FX LOOP | Presets | TAP | MIDI
  Widget _buildRow4() {
    return Row(
      children: [
        // Settings (flex 2)
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: _showSettings,
            child: SizedBox.expand(
              child: Container(
                decoration: BoxDecoration(
                  color: PodColors.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: PodColors.surfaceLight, width: 1),
                ),
                child: const Center(
                  child: Icon(
                    Icons.settings,
                    color: PodColors.textSecondary,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // WAH (flex 3) — restored EffectButton with smaller font, preserves on/off
        Expanded(
          flex: 3,
          child: SizedBox.expand(
            child: EffectButton(
              label: 'WAH',
              isOn: _wahEnabled,
              onTap: () {
                final newState = !_wahEnabled;
                setState(() => _wahEnabled = newState);
                if (_isConnected) _podController.setWahEnabled(newState);
              },
              onLongPress: () => _showEffectModal('Wah'),
              labelFontSize: 11.5,
              modelFontSize: null,
            ),
          ),
        ),
        const SizedBox(width: 12),

        // FX LOOP (flex 3)
        Expanded(
          flex: 3,
          child: SizedBox.expand(
            child: EffectButton(
              label: 'FX LOOP',
              isOn: _loopEnabled,
              onTap: () {
                final newState = !_loopEnabled;
                setState(() => _loopEnabled = newState);
                if (_isConnected) _podController.setLoopEnabled(newState);
              },
              onLongPress: () {},
              labelFontSize: 11,
              color: PodColors.buttonOnAmber,
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Preset bar (flex 19)
        Expanded(
          flex: 19,
          child: SizedBox.expand(
            child: PatchBrowser(
              bank: _formatProgramName(_currentProgram),
              patchName: _currentPatchName,
              isModified: _isModified,
              onPrevious: () {
                if (_isConnected && _currentProgram > 0) {
                  _podController.selectProgram(_currentProgram - 1);
                }
              },
              onNext: () {
                if (_isConnected && _currentProgram < 127) {
                  _podController.selectProgram(_currentProgram + 1);
                }
              },
              onTap: _showPatchList,
            ),
          ),
        ),
        const SizedBox(width: 12),

        // TAP (flex 3)
        Expanded(
          flex: 3,
          child: SizedBox.expand(
            child: Container(
              decoration: BoxDecoration(
                color: PodColors.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: PodColors.surfaceLight, width: 1),
              ),
              child: const Center(
                child: Text(
                  'TAP',
                  style: TextStyle(
                    color: PodColors.textSecondary,
                    fontSize: 14,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // MIDI status (flex 2)
        Expanded(
          flex: 2,
          child: SizedBox.expand(
            child: ConnectionIndicator(
              isConnected: _isConnected,
              onTap: _showConnectionScreen,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAmpSelector() {
    return Container(
      decoration: BoxDecoration(
        color: PodColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: PodColors.surfaceLight, width: 1),
      ),
      child: Row(
        children: [
          // Left arrow — previous amp
          GestureDetector(
            onTap: _previousAmp,
            child: Container(
              width: 40,
              height: double.infinity,
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(color: PodColors.surfaceLight, width: 1),
                ),
              ),
              child: const Icon(
                Icons.chevron_left,
                color: PodColors.textSecondary,
                size: 20,
              ),
            ),
          ),

          // Center: Dot-matrix LCD showing amp and cabinet with chain link icon
          Expanded(
            child: Stack(
              children: [
                GestureDetector(
                  onTap: _showAmpPicker,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: Builder(
                      builder: (context) {
                        final amp = _podController.ampModel;
                        String line1;
                        String? line2;

                        if (amp == null) {
                          line1 = _currentAmp;
                          line2 = null;
                        } else {
                          switch (_settings.ampNameDisplayMode) {
                            case AmpNameDisplayMode.factory:
                              line1 = amp.getDisplayName(
                                AmpNameDisplayMode.factory,
                              );
                              line2 = null;
                              break;
                            case AmpNameDisplayMode.realAmp:
                              line1 = amp.getDisplayName(
                                AmpNameDisplayMode.realAmp,
                              );
                              line2 = null;
                              break;
                            case AmpNameDisplayMode.both:
                              if (amp.realName != null &&
                                  amp.realName!.isNotEmpty) {
                                // Show factory name as the large primary line and real amp as the smaller secondary line
                                line1 = amp.getDisplayName(
                                  AmpNameDisplayMode.factory,
                                );
                                line2 = amp.realName!;
                              } else {
                                line1 = amp.getDisplayName(
                                  AmpNameDisplayMode.factory,
                                );
                                line2 = null;
                              }
                              break;
                          }
                        }

                        return DotMatrixLCD(
                          line1: line1,
                          line2: line2,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          line1Size: 34,
                          line2Size: 14,
                        );
                      },
                    ),
                  ),
                ),
                // Chain link toggle icon in top-right corner
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _ampChainLinked = !_ampChainLinked;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: PodColors.background.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        _ampChainLinked ? Icons.link : Icons.link_off,
                        size: 16,
                        color: _ampChainLinked
                            ? PodColors.accent
                            : PodColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Right arrow — next amp
          GestureDetector(
            onTap: _nextAmp,
            child: Container(
              width: 40,
              height: double.infinity,
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: PodColors.surfaceLight, width: 1),
                ),
              ),
              child: const Icon(
                Icons.chevron_right,
                color: PodColors.textSecondary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEqBand({
    required String label,
    required double gain,
    required ValueChanged<double> onGainChanged,
    required int freq,
    required ValueChanged<int> onFreqChanged,
    required ({double min, double max}) freqRange,
    required int band,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Fader (compact)
        Expanded(
          child: VerticalFader(
            value: gain,
            min: -12.8,
            max: 12.6,
            onChanged: onGainChanged,
            width: 20,
            showValue: true,
            snapThreshold: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        // Frequency knob (compact)
        RotaryKnob(
          label: label,
          value: freq,
          onValueChanged: onFreqChanged,
          size: 28,
          showTickMarks: false,
          valueFormatter: (v) => _formatEqFreq(v, band, freqRange),
        ),
      ],
    );
  }

  Widget _buildAmpDisplay() {
    final amp = _podController.ampModel;
    if (amp == null) return Text(_currentAmp);

    switch (_settings.ampNameDisplayMode) {
      case AmpNameDisplayMode.factory:
        return Text(
          amp.getDisplayName(AmpNameDisplayMode.factory),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: PodColors.textPrimary,
          ),
          overflow: TextOverflow.ellipsis,
        );

      case AmpNameDisplayMode.realAmp:
        return Text(
          amp.getDisplayName(AmpNameDisplayMode.realAmp),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: PodColors.textPrimary,
          ),
          overflow: TextOverflow.ellipsis,
        );

      case AmpNameDisplayMode.both:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (amp.realName != null)
              Text(
                amp.realName!,
                style: const TextStyle(
                  fontSize: 10,
                  color: PodColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            Text(
              amp.getDisplayName(AmpNameDisplayMode.factory),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: PodColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
    }
  }
}

/// Connection panel widget for device discovery and connection
class _ConnectionPanel extends StatefulWidget {
  final PodController podController;
  final bool isConnected;
  final bool isConnecting;
  final VoidCallback onDisconnect;

  const _ConnectionPanel({
    required this.podController,
    required this.isConnected,
    required this.isConnecting,
    required this.onDisconnect,
  });

  @override
  State<_ConnectionPanel> createState() => _ConnectionPanelState();
}

class _ConnectionPanelState extends State<_ConnectionPanel> {
  List<MidiDeviceInfo> _devices = [];
  bool _scanning = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (!widget.isConnected) {
      _scanDevices();
    }
  }

  Future<void> _scanDevices() async {
    setState(() {
      _scanning = true;
      _error = null;
    });

    try {
      final devices = await widget.podController.scanDevices();
      setState(() {
        _devices = devices;
        _scanning = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _scanning = false;
      });
    }
  }

  Future<void> _connectToDevice(MidiDeviceInfo device) async {
    try {
      await widget.podController.connect(device);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to connect: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isConnected) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Connected to POD XT Pro',
            style: TextStyle(color: PodColors.textPrimary, fontSize: 16),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  widget.podController.refreshEditBuffer();
                },
                child: const Text('Sync from POD'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: widget.onDisconnect,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                ),
                child: const Text('Disconnect'),
              ),
            ],
          ),
        ],
      );
    }

    if (widget.isConnecting) {
      return const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Connecting...', style: TextStyle(color: PodColors.textPrimary)),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              _error!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        if (_scanning)
          const Center(
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text(
                  'Scanning for devices...',
                  style: TextStyle(color: PodColors.textSecondary),
                ),
              ],
            ),
          )
        else if (_devices.isEmpty)
          Column(
            children: [
              const Text(
                'No MIDI devices found',
                style: TextStyle(color: PodColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _scanDevices,
                child: const Text('Scan Again'),
              ),
            ],
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Available Devices:',
                style: TextStyle(color: PodColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 12),
              ..._devices.map(
                (device) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ElevatedButton(
                    onPressed: () => _connectToDevice(device),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PodColors.surfaceLight,
                      foregroundColor: PodColors.textPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          device.isBleMidi ? Icons.bluetooth : Icons.usb,
                          size: 18,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            device.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: _scanDevices, child: const Text('Refresh')),
            ],
          ),
      ],
    );
  }
}

/// Patch list modal widget for selecting patches
class _PatchListModal extends StatelessWidget {
  final PodController podController;
  final int currentProgram;
  final bool patchesSynced;
  final int syncedCount;
  final ValueChanged<int> onSelectPatch;

  const _PatchListModal({
    required this.podController,
    required this.currentProgram,
    required this.patchesSynced,
    required this.syncedCount,
    required this.onSelectPatch,
  });

  @override
  Widget build(BuildContext context) {
    // Show sync progress if not complete
    if (!patchesSynced && syncedCount < 128) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),
          CircularProgressIndicator(
            value: syncedCount / 128,
            backgroundColor: PodColors.surfaceLight,
            color: PodColors.accent,
          ),
          const SizedBox(height: 16),
          Text(
            'Syncing patches... $syncedCount/128',
            style: const TextStyle(
              color: PodColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
        ],
      );
    }

    // Group patches by bank (32 banks, 4 patches each)
    return SizedBox(
      height: 400,
      child: ListView.builder(
        itemCount: 32, // 32 banks
        itemBuilder: (context, bankIndex) {
          final bankNum = bankIndex + 1;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bank header
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 12, bottom: 4),
                child: Text(
                  'Bank ${bankNum.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    color: PodColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // 4 patches per bank (A, B, C, D)
              Row(
                children: List.generate(4, (slotIndex) {
                  final program = bankIndex * 4 + slotIndex;
                  final patch = podController.patchLibrary[program];
                  final isSelected = program == currentProgram;
                  final letter = String.fromCharCode(
                    'A'.codeUnitAt(0) + slotIndex,
                  );

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onSelectPatch(program),
                      child: Container(
                        margin: const EdgeInsets.all(2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? PodColors.accent.withValues(alpha: 0.2)
                              : PodColors.surfaceLight,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isSelected
                                ? PodColors.accent
                                : PodColors.surfaceLight,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Program number
                            Text(
                              letter,
                              style: TextStyle(
                                color: isSelected
                                    ? PodColors.accent
                                    : PodColors.textSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            // Patch name
                            Text(
                              patch.name.isEmpty ? '(empty)' : patch.name,
                              style: TextStyle(
                                color: isSelected
                                    ? PodColors.textPrimary
                                    : patch.name.isEmpty
                                    ? PodColors.textSecondary
                                    : PodColors.textPrimary,
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Noise gate parameters modal with real-time updates
class _GateModal extends StatefulWidget {
  final PodController podController;
  final bool isConnected;

  const _GateModal({
    required this.podController,
    required this.isConnected,
  });

  @override
  State<_GateModal> createState() => _GateModalState();
}

class _GateModalState extends State<_GateModal> {
  late int _threshold;
  late int _decay;
  StreamSubscription<EditBuffer>? _editBufferSubscription;

  @override
  void initState() {
    super.initState();
    _threshold = widget.podController.gateThreshold;
    _decay = widget.podController.getParameter(PodXtCC.gateDecay);

    // Listen to edit buffer changes for real-time updates
    _editBufferSubscription = widget.podController.onEditBufferChanged.listen((buffer) {
      if (mounted) {
        setState(() {
          _threshold = widget.podController.gateThreshold;
          _decay = widget.podController.getParameter(PodXtCC.gateDecay);
        });
      }
    });
  }

  @override
  void dispose() {
    _editBufferSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Threshold knob (-96 to 0, physically reversed)
          RotaryKnob(
            label: 'THRESHOLD',
            value: 96 - _threshold, // Invert for display (makes knob work backwards)
            maxValue: 96,
            onValueChanged: (v) {
              final invertedValue = 96 - v; // Invert: clockwise decreases, counterclockwise increases
              setState(() => _threshold = invertedValue);
              if (widget.isConnected) {
                widget.podController.setGateThreshold(invertedValue);
              }
            },
            size: 60,
            valueFormatter: (v) => (v - 96).toString(), // Display as -96 to 0
          ),
          // Decay knob (0-100%)
          RotaryKnob(
            label: 'DECAY',
            value: _decay,
            onValueChanged: (v) {
              setState(() => _decay = v);
              if (widget.isConnected) {
                widget.podController.setParameter(PodXtCC.gateDecay, v);
              }
            },
            size: 60,
            valueFormatter: (v) => '${(v * 100 / 127).round()}%', // Display as percentage
          ),
        ],
      ),
    );
  }
}

/// Cabinet picker modal with full-screen grid layout
class _CabPickerModal extends StatelessWidget {
  final int currentCabId;
  final PodController podController;
  final bool isConnected;

  const _CabPickerModal({
    required this.currentCabId,
    required this.podController,
    required this.isConnected,
  });

  @override
  Widget build(BuildContext context) {
    // Separate standard and BX cabs
    final standardCabs = CabModels.all
        .where((cab) => cab.pack != 'BX')
        .toList();
    final bxCabs = CabModels.all.where((cab) => cab.pack == 'BX').toList();

    final screenWidth = MediaQuery.of(context).size.width;
    final modalWidth = screenWidth * 0.95; // 95% of screen width

    return SizedBox(
      width: modalWidth,
      height: MediaQuery.of(context).size.height * 0.8, // 80% of screen height
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Standard Cabinets Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'GUITAR CABINETS',
                style: PodTextStyles.labelMedium.copyWith(
                  color: PodColors.accent,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  childAspectRatio: 2.35,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: standardCabs.length,
                itemBuilder: (context, index) {
                  final cab = standardCabs[index];
                  final isSelected = cab.id == currentCabId;
                  return _buildCabButton(context, cab, isSelected);
                },
              ),
            ),

            // Divider
            const SizedBox(height: 16),
            const Divider(height: 1, thickness: 2),
            const SizedBox(height: 16),

            // BX Cabinets Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'BASS CABINETS',
                    style: PodTextStyles.labelMedium.copyWith(
                      color: PodColors.accent,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: PodColors.accent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Text(
                      'BX',
                      style: TextStyle(fontSize: 10, color: PodColors.accent),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  childAspectRatio: 2.35,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: bxCabs.length,
                itemBuilder: (context, index) {
                  final cab = bxCabs[index];
                  final isSelected = cab.id == currentCabId;
                  return _buildCabButton(context, cab, isSelected);
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCabButton(BuildContext context, CabModel cab, bool isSelected) {
    return GestureDetector(
      onTap: () {
        if (isConnected) {
          podController.setCabModel(cab.id);
        }
        Navigator.of(context).pop();
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? PodColors.accent.withValues(alpha: 0.3)
              : PodColors.surfaceLight,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? PodColors.accent : PodColors.knobBase,
            width: isSelected ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.all(6),
        child: Center(
          child: Text(
            cab.name,
            style: TextStyle(
              fontSize: 9,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? PodColors.accent : PodColors.textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

/// Microphone picker modal with room percentage control
class _MicPickerModal extends StatefulWidget {
  final List<MicModel> availableMics;
  final int currentMicId;
  final int currentRoomValue;
  final PodController podController;
  final bool isConnected;

  const _MicPickerModal({
    required this.availableMics,
    required this.currentMicId,
    required this.currentRoomValue,
    required this.podController,
    required this.isConnected,
  });

  @override
  State<_MicPickerModal> createState() => _MicPickerModalState();
}

class _MicPickerModalState extends State<_MicPickerModal> {
  late int _roomValue;

  @override
  void initState() {
    super.initState();
    _roomValue = widget.currentRoomValue;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 400,
      child: Column(
        children: [
          // Room percentage control
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('ROOM', style: PodTextStyles.labelMedium),
                    Text(
                      '${(_roomValue * 100 / 127).round()}%',
                      style: PodTextStyles.valueMedium.copyWith(
                        color: PodColors.accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Slider(
                  value: _roomValue.toDouble(),
                  min: 0,
                  max: 127,
                  divisions: 127,
                  onChanged: (value) {
                    setState(() => _roomValue = value.toInt());
                    if (widget.isConnected) {
                      widget.podController.setRoom(value.toInt());
                    }
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 8),
          // Microphone list
          Expanded(
            child: ListView.builder(
              itemCount: widget.availableMics.length,
              itemBuilder: (context, index) {
                final mic = widget.availableMics[index];
                final isSelected = mic.id == widget.currentMicId;

                return Padding(
                  padding: const EdgeInsets.only(
                    bottom: 8,
                    left: 16,
                    right: 16,
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      if (widget.isConnected) {
                        // BX mics (IDs 4-7) map to positions 0-3
                        final micPosition = mic.pack == 'BX'
                            ? mic.id - 4
                            : mic.id;
                        widget.podController.setMicModel(micPosition);
                      }
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected
                          ? PodColors.accent.withValues(alpha: 0.2)
                          : PodColors.surfaceLight,
                      foregroundColor: isSelected
                          ? PodColors.accent
                          : PodColors.textPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            mic.name,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (mic.pack != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: PodColors.accent.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              mic.pack!,
                              style: const TextStyle(
                                fontSize: 10,
                                color: PodColors.accent,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Amp picker modal with list and tiles view modes
class _AmpPickerModal extends StatefulWidget {
  final PodController podController;
  final AppSettings settings;
  final bool ampChainLinked;
  final bool initialTilesView;
  final double initialListScrollPosition;
  final double initialTilesScrollPosition;
  final ValueChanged<bool> onViewModeChanged;
  final void Function(double listPos, double tilesPos) onScrollPositionChanged;

  const _AmpPickerModal({
    required this.podController,
    required this.settings,
    required this.ampChainLinked,
    required this.initialTilesView,
    required this.initialListScrollPosition,
    required this.initialTilesScrollPosition,
    required this.onViewModeChanged,
    required this.onScrollPositionChanged,
  });

  @override
  State<_AmpPickerModal> createState() => _AmpPickerModalState();
}

class _AmpPickerModalState extends State<_AmpPickerModal> {
  late bool _isTilesView;
  late ScrollController _listScrollController;
  late ScrollController _gridScrollController;

  @override
  void initState() {
    super.initState();
    _isTilesView = widget.initialTilesView;

    // Initialize controllers with saved positions
    _listScrollController = ScrollController(
      initialScrollOffset: widget.initialListScrollPosition,
    );
    _gridScrollController = ScrollController(
      initialScrollOffset: widget.initialTilesScrollPosition,
    );
  }

  @override
  void dispose() {
    // Save current scroll positions before disposing
    final listPos = _listScrollController.hasClients
        ? _listScrollController.offset
        : widget.initialListScrollPosition;
    final tilesPos = _gridScrollController.hasClients
        ? _gridScrollController.offset
        : widget.initialTilesScrollPosition;

    // Schedule callback after dispose to avoid setState during dispose
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onScrollPositionChanged(listPos, tilesPos);
    });

    _listScrollController.dispose();
    _gridScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentAmpId = widget.podController.getParameter(PodXtCC.ampSelect);

    return Dialog(
      backgroundColor: PodColors.background,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header with title and view toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Amp Model',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: PodColors.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.view_list,
                        color: !_isTilesView
                            ? PodColors.accent
                            : PodColors.textSecondary,
                      ),
                      onPressed: () {
                        setState(() => _isTilesView = false);
                        widget.onViewModeChanged(false);
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.grid_view,
                        color: _isTilesView
                            ? PodColors.accent
                            : PodColors.textSecondary,
                      ),
                      onPressed: () {
                        setState(() => _isTilesView = true);
                        widget.onViewModeChanged(true);
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: PodColors.textSecondary,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Amp list/grid
            Expanded(
              child: _isTilesView
                  ? _buildTilesView(currentAmpId)
                  : _buildListView(currentAmpId),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView(int currentAmpId) {
    return ListView.builder(
      controller: _listScrollController,
      itemCount: AmpModels.all.length,
      itemBuilder: (context, index) {
        final amp = AmpModels.all[index];
        final isSelected = amp.id == currentAmpId;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ElevatedButton(
            onPressed: () async {
              // Use chain link setting to determine which method to use
              if (widget.ampChainLinked) {
                await widget.podController.setAmpModel(amp.id);
              } else {
                await widget.podController.setAmpModelNoDefaults(amp.id);
              }
              // Request updated parameters from POD
              await widget.podController.refreshEditBuffer();
              if (context.mounted) Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isSelected
                  ? PodColors.accent.withValues(alpha: 0.2)
                  : PodColors.surfaceLight,
              foregroundColor: isSelected
                  ? PodColors.accent
                  : PodColors.textPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style,
                      children: [
                        TextSpan(
                          text: '${amp.id.toString().padLeft(2, '0')} - ',
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? PodColors.accent : PodColors.textPrimary,
                          ),
                        ),
                        TextSpan(
                          text: amp.name,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? PodColors.accent : PodColors.textPrimary,
                          ),
                        ),
                        if (amp.realName != null) ...[
                          TextSpan(
                            text: ' - ${amp.realName}',
                            style: TextStyle(
                              fontWeight: FontWeight.w400,
                              color: PodColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (amp.pack != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getPackColor(amp.pack!).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      amp.pack!,
                      style: TextStyle(
                        fontSize: 10,
                        color: _getPackColor(amp.pack!),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTilesView(int currentAmpId) {
    // Separate amps by pack
    final stockAmps = AmpModels.all.where((amp) => amp.pack == null).toList();
    final msAmps = AmpModels.all.where((amp) => amp.pack == 'MS').toList();
    final ccAmps = AmpModels.all.where((amp) => amp.pack == 'CC').toList();
    final bxAmps = AmpModels.all.where((amp) => amp.pack == 'BX').toList();

    return SingleChildScrollView(
      controller: _gridScrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stock Amps Section
          _buildPackSection(
            'STOCK MODELS',
            stockAmps,
            currentAmpId,
            PodColors.accent,
            null,
          ),

          // Metal Shop Section
          if (msAmps.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1, thickness: 2),
            const SizedBox(height: 16),
            _buildPackSection(
              'METAL SHOP',
              msAmps,
              currentAmpId,
              Colors.red,
              'MS',
            ),
          ],

          // Collector's Classic Section
          if (ccAmps.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1, thickness: 2),
            const SizedBox(height: 16),
            _buildPackSection(
              'COLLECTOR\'S CLASSIC',
              ccAmps,
              currentAmpId,
              Colors.blue,
              'CC',
            ),
          ],

          // Bass Expansion Section
          if (bxAmps.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1, thickness: 2),
            const SizedBox(height: 16),
            _buildPackSection(
              'BASS EXPANSION',
              bxAmps,
              currentAmpId,
              Colors.green,
              'BX',
            ),
          ],

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPackSection(
    String title,
    List<AmpModel> amps,
    int currentAmpId,
    Color packColor,
    String? packBadge,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Text(
                title,
                style: PodTextStyles.labelMedium.copyWith(color: packColor),
              ),
              if (packBadge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: packColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    packBadge,
                    style: TextStyle(fontSize: 10, color: packColor),
                  ),
                ),
              ],
            ],
          ),
        ),
        // Grid of amps
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2.35,
          ),
          itemCount: amps.length,
          itemBuilder: (context, index) {
            final amp = amps[index];
            final isSelected = amp.id == currentAmpId;

            return GestureDetector(
              onTap: () async {
                // Use chain link setting to determine which method to use
                if (widget.ampChainLinked) {
                  await widget.podController.setAmpModel(amp.id);
                } else {
                  await widget.podController.setAmpModelNoDefaults(amp.id);
                }
                // Request updated parameters from POD
                await widget.podController.refreshEditBuffer();
                if (context.mounted) Navigator.of(context).pop();
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? packColor.withValues(alpha: 0.3)
                      : PodColors.surfaceLight,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected ? packColor : PodColors.knobBase,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                padding: const EdgeInsets.all(6),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        amp.name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected ? packColor : PodColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (amp.realName != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          amp.realName!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 7,
                            fontWeight: FontWeight.w300,
                            color: PodColors.textSecondary.withValues(alpha: 0.7),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Color _getPackColor(String pack) {
    switch (pack) {
      case 'MS':
        return Colors.red;
      case 'CC':
        return Colors.blue;
      case 'BX':
        return Colors.green;
      case 'FX':
        return Colors.orange;
      default:
        return PodColors.accent;
    }
  }
}
