import 'package:flutter/material.dart';
import '../widgets/vertical_fader.dart';
import '../widgets/eq_knob.dart';
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
      margin: const EdgeInsets.all(4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            // Outer bevel - light top, dark bottom
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: 0.15),
                Colors.black.withValues(alpha: 0.3),
              ],
            ),
          ),
          padding: const EdgeInsets.all(3),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              // Recessed area - darker, gradient from top-left to bottom-right
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1a1a1a),
                  PodColors.background,
                  const Color(0xFF0d0d0d),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
              // Inner shadow effect
              boxShadow: [
                // Top-left inner shadow (dark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.8),
                  offset: const Offset(0, 0),
                  blurRadius: 8,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                // Inner bevel highlights
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: LayoutBuilder(
                      builder: (context, constraints) {
                        final availableHeight = constraints.maxHeight;

                        // Knob size calculation
                        final knobSize = (availableHeight * 0.22).clamp(28.0, 40.0);

                        // EqKnob total height: label(~10px) + spacing(4px) + knob(size) + spacing(4px) + value(14px)
                        final knobTotalHeight = 10 + 4 + knobSize + 4 + 14;

                        // Value display height at top
                        final valueDisplayHeight = 18.0;

                        // Spacing
                        final topSpacing = 4.0;
                        final bottomSpacing = 8.0;

                        // Calculate maximum fader height
                        final faderHeight = (availableHeight - valueDisplayHeight - topSpacing - bottomSpacing - knobTotalHeight).clamp(80.0, 300.0);
                        final faderWidth = (constraints.maxWidth / 4 * 0.35).clamp(16.0, 22.0);

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
                              ),
                            ),
                            _buildDivider(),
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
                              ),
                            ),
                            _buildDivider(),
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
                              ),
                            ),
                            _buildDivider(),
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
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.white.withValues(alpha: 0.1),
            Colors.black.withValues(alpha: 0.3),
            Colors.white.withValues(alpha: 0.05),
            Colors.transparent,
          ],
          stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
        ),
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
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  formatGainValue(gain),
                  style: TextStyle(
                    color: gain == 0
                        ? PodColors.textSecondary
                        : (gain > 0
                            ? PodColors.accent.withValues(alpha: 0.9)
                            : Colors.red.withValues(alpha: 0.8)),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
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
          const SizedBox(height: 8),
          // Frequency knob with adaptive size
          EqKnob(
            label: label,
            value: freq,
            onValueChanged: onFreqChanged,
            size: knobSize,
            valueFormatter: (v) => formatEqFreq(v, band, freqRange),
          ),
        ],
      ),
    );
  }
}
