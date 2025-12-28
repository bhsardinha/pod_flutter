import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/pod_theme.dart';
import '../widgets/effect_button.dart';
import '../widgets/model_selector.dart';
import '../widgets/rotary_knob.dart';
import '../widgets/vertical_fader.dart';
import '../widgets/connection_indicator.dart';
import '../widgets/patch_browser.dart';
import '../widgets/pod_modal.dart';

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
  // Connection state
  bool _isConnected = false;

  // Patch state
  String _currentBank = '01A';
  String _currentPatchName = 'Clean Rhythm';

  // Amp/Cab state
  String _currentAmp = 'BRIT J-800';
  String _currentCab = '4x12 V30\'s';
  String _currentMic = '57 On Axis';

  // Effect states
  bool _gateEnabled = true;
  bool _wahEnabled = false;
  bool _stompEnabled = false;
  bool _modEnabled = true;
  bool _delayEnabled = true;
  bool _reverbEnabled = true;
  bool _eqEnabled = true;

  // Effect model names
  String _wahModel = 'Fassel';
  String _stompModel = 'Screamer';
  String _modModel = 'Chorus';
  String _delayModel = 'Analog';
  String _reverbModel = 'Hall';

  // Knob values (0-127)
  int _drive = 75;
  int _bass = 50;
  int _mid = 62;
  int _treble = 58;
  int _presence = 45;
  int _volume = 80;

  // EQ values (-12 to +12 dB)
  double _eq1Gain = 3.0;
  double _eq2Gain = -2.0;
  double _eq3Gain = 1.5;
  double _eq4Gain = 4.0;

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
  }

  @override
  void dispose() {
    // Allow all orientations when leaving
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
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
      title: 'Connection',
      child: const Center(
        child: Text(
          'Connection settings coming soon...',
          style: TextStyle(color: PodColors.textSecondary),
        ),
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
      children: [
        // GATE button (1/5)
        Expanded(
          flex: 1,
          child: EffectButton(
            label: 'GATE',
            isOn: _gateEnabled,
            onTap: () => setState(() => _gateEnabled = !_gateEnabled),
            onLongPress: () => _showEffectModal('Gate'),
            color: PodColors.buttonOnGreen,
          ),
        ),
        const SizedBox(width: 12),

        // AMP Selector (3/5)
        Expanded(
          flex: 3,
          child: ModelSelector(
            value: _currentAmp,
            label: 'AMP MODEL',
            onTap: _showAmpPicker,
            onPrevious: () {
              // TODO: implement previous amp
            },
            onNext: () {
              // TODO: implement next amp
            },
          ),
        ),
        const SizedBox(width: 12),

        // CAB/MIC (1/5)
        Expanded(
          flex: 1,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // CAB button
              GestureDetector(
                onTap: _showCabPicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: PodColors.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8),
                    ),
                    border: Border.all(
                      color: PodColors.surfaceLight,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'CAB',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _currentCab,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: PodColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              // MIC button
              GestureDetector(
                onTap: _showMicPicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: PodColors.surface,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(8),
                    ),
                    border: Border.all(
                      color: PodColors.surfaceLight,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'MIC',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _currentMic,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: PodColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKnobsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        RotaryKnob(
          label: 'DRIVE',
          value: _drive,
          onValueChanged: (v) => setState(() => _drive = v),
          size: 60,
        ),
        RotaryKnob(
          label: 'BASS',
          value: _bass,
          onValueChanged: (v) => setState(() => _bass = v),
          size: 60,
        ),
        RotaryKnob(
          label: 'MID',
          value: _mid,
          onValueChanged: (v) => setState(() => _mid = v),
          size: 60,
        ),
        RotaryKnob(
          label: 'TREBLE',
          value: _treble,
          onValueChanged: (v) => setState(() => _treble = v),
          size: 60,
        ),
        RotaryKnob(
          label: 'PRESENCE',
          value: _presence,
          onValueChanged: (v) => setState(() => _presence = v),
          size: 60,
        ),
        RotaryKnob(
          label: 'VOLUME',
          value: _volume,
          onValueChanged: (v) => setState(() => _volume = v),
          size: 60,
        ),
      ],
    );
  }

  Widget _buildEqRow() {
    return Row(
      children: [
        // Band 1
        Expanded(
          child: _buildEqBand(
            label: 'LOW',
            gain: _eq1Gain,
            onGainChanged: (v) => setState(() => _eq1Gain = v),
            freq: _eq1Freq,
            onFreqChanged: (v) => setState(() => _eq1Freq = v),
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
          ),
        ),
        const SizedBox(width: 16),
        // EQ Enable button
        SizedBox(
          width: 70,
          child: EffectButton(
            label: 'EQ',
            isOn: _eqEnabled,
            onTap: () => setState(() => _eqEnabled = !_eqEnabled),
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
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Fader
        Expanded(
          child: VerticalFader(
            value: gain,
            min: -12.0,
            max: 12.0,
            onChanged: onGainChanged,
            width: 36,
            showValue: true,
          ),
        ),
        const SizedBox(height: 8),
        // Frequency knob
        RotaryKnob(
          label: label,
          value: freq,
          onValueChanged: onFreqChanged,
          size: 40,
          showTickMarks: false,
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
            onTap: () => setState(() => _wahEnabled = !_wahEnabled),
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
            onTap: () => setState(() => _stompEnabled = !_stompEnabled),
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
            onTap: () => setState(() => _modEnabled = !_modEnabled),
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
            onTap: () => setState(() => _delayEnabled = !_delayEnabled),
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
            onTap: () => setState(() => _reverbEnabled = !_reverbEnabled),
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
            bank: _currentBank,
            patchName: _currentPatchName,
            onPrevious: () {
              // TODO: implement previous patch
            },
            onNext: () {
              // TODO: implement next patch
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
