import 'package:flutter/material.dart';
import '../widgets/vertical_fader.dart';
import '../widgets/rotary_knob.dart';
import '../utils/eq_frequency_mapper.dart';
import '../theme/pod_theme.dart';

/// EQ Section - 4-band parametric EQ with bipolar faders.
///
/// Contains four EQ bands, each with:
/// - Vertical fader for gain control (-12.8 dB to +12.6 dB)
/// - Rotary knob for frequency selection (band-specific ranges)
///
/// Bands:
/// - LOW: 50-690 Hz
/// - LO MID: 50-6050 Hz
/// - HI MID: 100-11300 Hz
/// - HIGH: 500-9300 Hz
class EqSection extends StatelessWidget {
  // EQ gain values (in dB)
  final double eq1Gain;
  final double eq2Gain;
  final double eq3Gain;
  final double eq4Gain;

  // EQ frequency values (MIDI 0-127)
  final int eq1Freq;
  final int eq2Freq;
  final int eq3Freq;
  final int eq4Freq;

  // Gain change callbacks
  final ValueChanged<double> onEq1GainChanged;
  final ValueChanged<double> onEq2GainChanged;
  final ValueChanged<double> onEq3GainChanged;
  final ValueChanged<double> onEq4GainChanged;

  // Frequency change callbacks
  final ValueChanged<int> onEq1FreqChanged;
  final ValueChanged<int> onEq2FreqChanged;
  final ValueChanged<int> onEq3FreqChanged;
  final ValueChanged<int> onEq4FreqChanged;

  const EqSection({
    super.key,
    required this.eq1Gain,
    required this.eq2Gain,
    required this.eq3Gain,
    required this.eq4Gain,
    required this.eq1Freq,
    required this.eq2Freq,
    required this.eq3Freq,
    required this.eq4Freq,
    required this.onEq1GainChanged,
    required this.onEq2GainChanged,
    required this.onEq3GainChanged,
    required this.onEq4GainChanged,
    required this.onEq1FreqChanged,
    required this.onEq2FreqChanged,
    required this.onEq3FreqChanged,
    required this.onEq4FreqChanged,
  });

  @override
  Widget build(BuildContext context) {
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
              gain: eq1Gain,
              onGainChanged: onEq1GainChanged,
              freq: eq1Freq,
              onFreqChanged: onEq1FreqChanged,
              freqRange: EqFrequencyRanges.eq1,
              band: 1,
            ),
          ),
          Expanded(
            child: _buildEqBand(
              label: 'LO MID',
              gain: eq2Gain,
              onGainChanged: onEq2GainChanged,
              freq: eq2Freq,
              onFreqChanged: onEq2FreqChanged,
              freqRange: EqFrequencyRanges.eq2,
              band: 2,
            ),
          ),
          Expanded(
            child: _buildEqBand(
              label: 'HI MID',
              gain: eq3Gain,
              onGainChanged: onEq3GainChanged,
              freq: eq3Freq,
              onFreqChanged: onEq3FreqChanged,
              freqRange: EqFrequencyRanges.eq3,
              band: 3,
            ),
          ),
          Expanded(
            child: _buildEqBand(
              label: 'HIGH',
              gain: eq4Gain,
              onGainChanged: onEq4GainChanged,
              freq: eq4Freq,
              onFreqChanged: onEq4FreqChanged,
              freqRange: EqFrequencyRanges.eq4,
              band: 4,
            ),
          ),
        ],
      ),
    );
  }

  /// Build a single EQ band with vertical fader and frequency knob.
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
          valueFormatter: (v) => formatEqFreq(v, band, freqRange),
        ),
      ],
    );
  }
}
