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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: PodColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PodColors.surfaceLight, width: 1),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate adaptive sizes based on available height
          final availableHeight = constraints.maxHeight - 12; // minus padding (6 top + 6 bottom)

          // Start with minimum knob size and scale up if space allows
          final knobSize = (availableHeight * 0.3).clamp(24.0, 36.0);

          // Calculate font sizes and spacing
          final labelFontSize = (knobSize * 0.28).clamp(7.0, 10.0);
          final textSpacing = (knobSize * 0.12).clamp(2.0, 4.0);

          // Calculate total knob component height:
          // labelHeight + textSpacing + knobSize + textSpacing + valueHeight
          final labelHeight = labelFontSize + 4; // approximate text height
          final valueHeight = 16.0; // fixed height from knob widget
          final totalKnobHeight = labelHeight + textSpacing + knobSize + textSpacing + valueHeight;

          // Spacing between fader and knob
          final verticalSpacing = textSpacing * 2;

          // Account for fader padding (4px top + 4px bottom) and value display (18px + 4px spacing)
          final faderPadding = 8.0;
          final valueDisplayHeight = 22.0; // 18px text + 4px spacing

          // Calculate fader height: available - knob - spacing - fader padding - value display
          final faderHeight = (availableHeight - totalKnobHeight - verticalSpacing - faderPadding - valueDisplayHeight).clamp(60.0, 200.0);

          // Adaptive fader width based on available horizontal space
          final faderWidth = (constraints.maxWidth / 4 * 0.35).clamp(14.0, 20.0);

          return Row(
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
                  knobSize: knobSize,
                  faderHeight: faderHeight,
                  faderWidth: faderWidth,
                  labelFontSize: labelFontSize,
                  textSpacing: textSpacing,
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
                  knobSize: knobSize,
                  faderHeight: faderHeight,
                  faderWidth: faderWidth,
                  labelFontSize: labelFontSize,
                  textSpacing: textSpacing,
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
                  knobSize: knobSize,
                  faderHeight: faderHeight,
                  faderWidth: faderWidth,
                  labelFontSize: labelFontSize,
                  textSpacing: textSpacing,
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
                  knobSize: knobSize,
                  faderHeight: faderHeight,
                  faderWidth: faderWidth,
                  labelFontSize: labelFontSize,
                  textSpacing: textSpacing,
                ),
              ),
            ],
          );
        },
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
    required double knobSize,
    required double faderHeight,
    required double faderWidth,
    required double labelFontSize,
    required double textSpacing,
  }) {
    // Format the gain value for display
    String formatGainValue(double value) {
      if (value == 0.0) {
        return '0dB';
      } else if (value > 0) {
        return '+${value.toStringAsFixed(1)}dB';
      } else {
        return '${value.toStringAsFixed(1)}dB';
      }
    }

    return SizedBox(
      height: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Value display outside the fader
          SizedBox(
            height: 18,
            child: Center(
              child: Text(
                formatGainValue(gain),
                style: TextStyle(
                  color: PodColors.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Fader with fixed calculated height
          SizedBox(
            height: faderHeight,
            child: VerticalFader(
              value: gain,
              min: -12.8,
              max: 12.6,
              onChanged: onGainChanged,
              width: faderWidth,
              showValue: false,
              snapThreshold: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(height: textSpacing * 2),
          // Frequency knob with adaptive size
          SizedBox(
            height: labelFontSize + 4 + textSpacing + knobSize + textSpacing + 16,
            child: RotaryKnob(
              label: label,
              value: freq,
              onValueChanged: onFreqChanged,
              size: knobSize,
              showTickMarks: false,
              valueFormatter: (v) => formatEqFreq(v, band, freqRange),
              labelFontSize: labelFontSize,
              textSpacing: textSpacing,
            ),
          ),
        ],
      ),
    );
  }
}
