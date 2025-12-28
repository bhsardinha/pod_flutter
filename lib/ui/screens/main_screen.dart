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
import '../../services/ble_midi_service.dart';
import '../../services/pod_controller.dart';
import '../../services/midi_service.dart';
import '../../protocol/cc_map.dart';
import '../../models/patch.dart';

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
  // EQ frequency ranges (Hz) for each band
  static const _eq1FreqRange = (min: 60.0, max: 240.0); // LOW
  static const _eq2FreqRange = (min: 140.0, max: 1400.0); // LO MID
  static const _eq3FreqRange = (min: 360.0, max: 3600.0); // HI MID
  static const _eq4FreqRange = (min: 500.0, max: 7200.0); // HIGH

  // MIDI Services
  late final BleMidiService _midiService;
  late final PodController _podController;
  final List<StreamSubscription> _subscriptions = [];

  /// Format a MIDI value (0-127) as a 0.0-10.0 scale
  String _formatKnobValue(int value) {
    final scaled = (value / 127.0 * 10.0);
    return scaled.toStringAsFixed(1);
  }

  /// Format EQ frequency value based on the band's range
  String _formatEqFreq(int midiValue, ({double min, double max}) range) {
    final freq = range.min + (midiValue / 127.0) * (range.max - range.min);
    if (freq >= 1000) {
      return '${(freq / 1000).toStringAsFixed(1)}k';
    }
    return '${freq.round()}';
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
  bool _ampEnabled = true; // Amp bypass (inverted: true = amp ON)
  bool _wahEnabled = false;
  bool _stompEnabled = false;
  bool _modEnabled = false;
  bool _delayEnabled = false;
  bool _reverbEnabled = false;
  bool _eqEnabled = false;

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

  // EQ gain values (-12 to +12 dB)
  double _eq1Gain = 0.0;
  double _eq2Gain = 0.0;
  double _eq3Gain = 0.0;
  double _eq4Gain = 0.0;

  // EQ frequencies (0-127)
  int _eq1Freq = 30;
  int _eq2Freq = 50;
  int _eq3Freq = 70;
  int _eq4Freq = 90;

  @override
  void initState() {
    super.initState();
    // Force landscape orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

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

  void _updateFromEditBuffer(EditBuffer buffer) {
    setState(() {
      // Amp/Cab/Mic
      final amp = _podController.ampModel;
      final cab = _podController.cabModel;
      final mic = _podController.micModel;
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

      // Effect enables
      _gateEnabled = _podController.noiseGateEnabled;
      _ampEnabled = !_podController.getSwitch(PodXtCC.ampEnable); // Inverted
      _wahEnabled = _podController.wahEnabled;
      _stompEnabled = _podController.stompEnabled;
      _modEnabled = _podController.modEnabled;
      _delayEnabled = _podController.delayEnabled;
      _reverbEnabled = _podController.reverbEnabled;
      _eqEnabled = _podController.eqEnabled;

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

      // EQ gains (convert 0-127 to -12 to +12 dB)
      _eq1Gain = _midiToDb(_podController.getParameter(PodXtCC.eq1Gain));
      _eq2Gain = _midiToDb(_podController.getParameter(PodXtCC.eq2Gain));
      _eq3Gain = _midiToDb(_podController.getParameter(PodXtCC.eq3Gain));
      _eq4Gain = _midiToDb(_podController.getParameter(PodXtCC.eq4Gain));
    });
  }

  void _handleParameterChange(ParameterChange change) {
    // Individual parameter updates are handled by _updateFromEditBuffer
    // This is for any additional real-time handling if needed
  }

  // Convert MIDI value (0-127) to dB (-12 to +12)
  double _midiToDb(int midi) {
    return ((midi / 127.0) * 24.0) - 12.0;
  }

  // Convert dB (-12 to +12) to MIDI value (0-127)
  int _dbToMidi(double db) {
    return (((db + 12.0) / 24.0) * 127.0).round().clamp(0, 127);
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

  void _showAmpPicker() {
    showPodModal(
      context: context,
      title: 'Select Amp Model',
      child: const Center(
        child: Text(
          'Amp picker coming soon...',
          style: TextStyle(color: PodColors.textSecondary),
        ),
      ),
    );
  }

  void _showCabPicker() {
    showPodModal(
      context: context,
      title: 'Select Cabinet',
      child: const Center(
        child: Text(
          'Cabinet picker coming soon...',
          style: TextStyle(color: PodColors.textSecondary),
        ),
      ),
    );
  }

  void _showMicPicker() {
    showPodModal(
      context: context,
      title: 'Select Microphone',
      child: const Center(
        child: Text(
          'Microphone picker coming soon...',
          style: TextStyle(color: PodColors.textSecondary),
        ),
      ),
    );
  }

  void _showPatchList() {
    showPodModal(
      context: context,
      title: 'Patch Browser',
      child: const Center(
        child: Text(
          'Patch list coming soon...',
          style: TextStyle(color: PodColors.textSecondary),
        ),
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
              // Top Row: GATE | AMP SELECTOR | CAB/MIC
              _buildTopRow(),
              const SizedBox(height: 12),

              // Knobs Row: Drive, Bass, Mid, Treble, Presence, Vol
              _buildKnobsRow(),
              const SizedBox(height: 12),

              // EQ Row: 4-band faders + EQ button
              Expanded(
                flex: 2,
                child: _buildEqRow(),
              ),
              const SizedBox(height: 12),

              // Effects Row: WAH, STOMP, MOD, DELAY, REVERB
              _buildEffectsRow(),
              const SizedBox(height: 12),

              // Bottom Bar: Patch Browser | Connection
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // GATE button
        SizedBox(
          width: 80,
          height: 48,
          child: EffectButton(
            label: 'GATE',
            isOn: _gateEnabled,
            onTap: () {
              final newState = !_gateEnabled;
              setState(() => _gateEnabled = newState);
              if (_isConnected) _podController.setNoiseGateEnabled(newState);
            },
            onLongPress: () => _showEffectModal('Gate'),
            color: PodColors.buttonOnGreen,
          ),
        ),
        const SizedBox(width: 8),

        // AMP Selector with arrows at extremes
        Expanded(
          child: _buildAmpSelector(),
        ),
        const SizedBox(width: 8),

        // AMP Bypass button
        SizedBox(
          width: 70,
          height: 48,
          child: EffectButton(
            label: 'AMP',
            isOn: _ampEnabled,
            onTap: () {
              final newState = !_ampEnabled;
              setState(() => _ampEnabled = newState);
              // ampEnable CC is inverted: 127 = bypass (off), 0 = amp on
              if (_isConnected) _podController.setSwitch(PodXtCC.ampEnable, !newState);
            },
            onLongPress: () {},
            color: PodColors.buttonOnAmber,
          ),
        ),
        const SizedBox(width: 8),

        // CAB selector
        _buildDropdown(
          label: 'CAB',
          value: _currentCab,
          onTap: _showCabPicker,
        ),
        const SizedBox(width: 8),

        // MIC selector
        _buildDropdown(
          label: 'MIC',
          value: _currentMic,
          onTap: _showMicPicker,
        ),
      ],
    );
  }

  Widget _buildAmpSelector() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: PodColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: PodColors.surfaceLight, width: 1),
      ),
      child: Row(
        children: [
          // Left arrow
          GestureDetector(
            onTap: () {
              // TODO: previous amp
            },
            child: Container(
              width: 32,
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
          // Amp name
          Expanded(
            child: GestureDetector(
              onTap: _showAmpPicker,
              child: Center(
                child: Text(
                  _currentAmp,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: PodColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          // Right arrow
          GestureDetector(
            onTap: () {
              // TODO: next amp
            },
            child: Container(
              width: 32,
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

  Widget _buildDropdown({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: PodColors.surface,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: PodColors.surfaceLight, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: PodColors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: PodColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_drop_down,
              color: PodColors.textSecondary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKnobsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        RotaryKnob(
          label: 'DRIVE',
          value: _drive,
          onValueChanged: (v) {
            setState(() => _drive = v);
            if (_isConnected) _podController.setDrive(v);
          },
          size: 50,
          valueFormatter: _formatKnobValue,
        ),
        RotaryKnob(
          label: 'BASS',
          value: _bass,
          onValueChanged: (v) {
            setState(() => _bass = v);
            if (_isConnected) _podController.setBass(v);
          },
          size: 50,
          valueFormatter: _formatKnobValue,
        ),
        RotaryKnob(
          label: 'MID',
          value: _mid,
          onValueChanged: (v) {
            setState(() => _mid = v);
            if (_isConnected) _podController.setMid(v);
          },
          size: 50,
          valueFormatter: _formatKnobValue,
        ),
        RotaryKnob(
          label: 'TREBLE',
          value: _treble,
          onValueChanged: (v) {
            setState(() => _treble = v);
            if (_isConnected) _podController.setTreble(v);
          },
          size: 50,
          valueFormatter: _formatKnobValue,
        ),
        RotaryKnob(
          label: 'PRES',
          value: _presence,
          onValueChanged: (v) {
            setState(() => _presence = v);
            if (_isConnected) _podController.setPresence(v);
          },
          size: 50,
          valueFormatter: _formatKnobValue,
        ),
        RotaryKnob(
          label: 'VOL',
          value: _volume,
          onValueChanged: (v) {
            setState(() => _volume = v);
            if (_isConnected) _podController.setChannelVolume(v);
          },
          size: 50,
          valueFormatter: _formatKnobValue,
        ),
      ],
    );
  }

  Widget _buildEqRow() {
    return Row(
      children: [
        // EQ Section in a tile
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: PodColors.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: PodColors.surfaceLight,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Band 1
                Expanded(
                  child: _buildEqBand(
                    label: 'LOW',
                    gain: _eq1Gain,
                    onGainChanged: (v) => setState(() => _eq1Gain = v),
                    freq: _eq1Freq,
                    onFreqChanged: (v) => setState(() => _eq1Freq = v),
                    freqRange: _eq1FreqRange,
                  ),
                ),
                // Band 2
                Expanded(
                  child: _buildEqBand(
                    label: 'LO MID',
                    gain: _eq2Gain,
                    onGainChanged: (v) => setState(() => _eq2Gain = v),
                    freq: _eq2Freq,
                    onFreqChanged: (v) => setState(() => _eq2Freq = v),
                    freqRange: _eq2FreqRange,
                  ),
                ),
                // Band 3
                Expanded(
                  child: _buildEqBand(
                    label: 'HI MID',
                    gain: _eq3Gain,
                    onGainChanged: (v) => setState(() => _eq3Gain = v),
                    freq: _eq3Freq,
                    onFreqChanged: (v) => setState(() => _eq3Freq = v),
                    freqRange: _eq3FreqRange,
                  ),
                ),
                // Band 4
                Expanded(
                  child: _buildEqBand(
                    label: 'HIGH',
                    gain: _eq4Gain,
                    onGainChanged: (v) => setState(() => _eq4Gain = v),
                    freq: _eq4Freq,
                    onFreqChanged: (v) => setState(() => _eq4Freq = v),
                    freqRange: _eq4FreqRange,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // EQ Enable button
        SizedBox(
          width: 60,
          child: EffectButton(
            label: 'EQ',
            isOn: _eqEnabled,
            onTap: () {
              final newState = !_eqEnabled;
              setState(() => _eqEnabled = newState);
              if (_isConnected) _podController.setEqEnabled(newState);
            },
            onLongPress: () => _showEffectModal('EQ'),
            color: PodColors.buttonOnAmber,
          ),
        ),
      ],
    );
  }

  Widget _buildEqBand({
    required String label,
    required double gain,
    required ValueChanged<double> onGainChanged,
    required int freq,
    required ValueChanged<int> onFreqChanged,
    required ({double min, double max}) freqRange,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Fader
        Expanded(
          child: VerticalFader(
            value: gain,
            min: -12.0,
            max: 12.0,
            onChanged: onGainChanged,
            width: 24,
            showValue: true,
          ),
        ),
        // Frequency knob (no gap)
        RotaryKnob(
          label: label,
          value: freq,
          onValueChanged: onFreqChanged,
          size: 32,
          showTickMarks: false,
          valueFormatter: (v) => _formatEqFreq(v, freqRange),
        ),
      ],
    );
  }

  Widget _buildEffectsRow() {
    return Row(
      children: [
        Expanded(
          child: EffectButton(
            label: 'WAH',
            modelName: _wahModel,
            isOn: _wahEnabled,
            onTap: () {
              final newState = !_wahEnabled;
              setState(() => _wahEnabled = newState);
              if (_isConnected) _podController.setWahEnabled(newState);
            },
            onLongPress: () => _showEffectModal('Wah'),
            color: PodColors.buttonOnGreen,
          ),
        ),
        const SizedBox(width: 8),
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
        const SizedBox(width: 8),
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
        const SizedBox(width: 8),
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
        const SizedBox(width: 8),
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
    );
  }

  Widget _buildBottomBar() {
    return Row(
      children: [
        // Patch Browser (4/5)
        Expanded(
          flex: 4,
          child: PatchBrowser(
            bank: _formatProgramName(_currentProgram),
            patchName: _currentPatchName,
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
        const SizedBox(width: 12),
        // Connection Indicator (1/5)
        ConnectionIndicator(
          isConnected: _isConnected,
          onTap: _showConnectionScreen,
        ),
      ],
    );
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
          Text(
            'Connecting...',
            style: TextStyle(color: PodColors.textPrimary),
          ),
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
                style: TextStyle(
                  color: PodColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              ..._devices.map((device) => Padding(
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
                            device.isBleMidi
                                ? Icons.bluetooth
                                : Icons.usb,
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
                  )),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _scanDevices,
                child: const Text('Refresh'),
              ),
            ],
          ),
      ],
    );
  }
}
