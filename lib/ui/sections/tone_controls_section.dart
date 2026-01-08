import 'package:flutter/material.dart';
import '../widgets/rotary_knob.dart';
import '../utils/value_formatters.dart';

/// Tone Controls Section - Row 2 of the POD XT Pro interface.
///
/// Contains 7 rotary knobs for amp and effect tone control:
/// - GAIN: Drive/distortion amount
/// - BASS: Bass EQ
/// - MID: Mid EQ
/// - TREBLE: Treble EQ
/// - PRES: Presence
/// - VOL: Channel volume
/// - REVERB: Reverb mix level
class ToneControlsSection extends StatelessWidget {
  final int drive;
  final int bass;
  final int mid;
  final int treble;
  final int presence;
  final int volume;
  final int reverbMix;

  final ValueChanged<int> onDriveChanged;
  final ValueChanged<int> onBassChanged;
  final ValueChanged<int> onMidChanged;
  final ValueChanged<int> onTrebleChanged;
  final ValueChanged<int> onPresenceChanged;
  final ValueChanged<int> onVolumeChanged;
  final ValueChanged<int> onReverbMixChanged;

  const ToneControlsSection({
    super.key,
    required this.drive,
    required this.bass,
    required this.mid,
    required this.treble,
    required this.presence,
    required this.volume,
    required this.reverbMix,
    required this.onDriveChanged,
    required this.onBassChanged,
    required this.onMidChanged,
    required this.onTrebleChanged,
    required this.onPresenceChanged,
    required this.onVolumeChanged,
    required this.onReverbMixChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate adaptive sizes based on available space
        final availableHeight = constraints.maxHeight;

        // Start with a proportion of height for the knob
        double knobSize = (availableHeight * 0.50).clamp(40.0, 72.0);

        // Calculate font sizes and spacing proportionally
        double labelFontSize = (knobSize * 0.18).clamp(10.0, 13.0);
        double textSpacing = (knobSize * 0.11).clamp(4.0, 8.0);

        // Calculate total component height:
        // label + spacing + knob + spacing + value (16px fixed)
        final labelHeight = labelFontSize + 4;
        final valueHeight = 16.0;
        double totalHeight = labelHeight + textSpacing + knobSize + textSpacing + valueHeight;

        // If total height exceeds available, scale everything down
        if (totalHeight > availableHeight) {
          final scaleFactor = availableHeight / totalHeight;
          knobSize = (knobSize * scaleFactor).clamp(40.0, 72.0);
          labelFontSize = (labelFontSize * scaleFactor).clamp(10.0, 13.0);
          textSpacing = (textSpacing * scaleFactor).clamp(4.0, 8.0);
        }

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
                    value: drive,
                    onValueChanged: onDriveChanged,
                    size: knobSize,
                    valueFormatter: formatKnobValue,
                    labelFontSize: labelFontSize,
                    textSpacing: textSpacing,
                  ),
                  RotaryKnob(
                    label: 'BASS',
                    value: bass,
                    onValueChanged: onBassChanged,
                    size: knobSize,
                    valueFormatter: formatKnobValue,
                    labelFontSize: labelFontSize,
                    textSpacing: textSpacing,
                  ),
                  RotaryKnob(
                    label: 'MID',
                    value: mid,
                    onValueChanged: onMidChanged,
                    size: knobSize,
                    valueFormatter: formatKnobValue,
                    labelFontSize: labelFontSize,
                    textSpacing: textSpacing,
                  ),
                  RotaryKnob(
                    label: 'TREBLE',
                    value: treble,
                    onValueChanged: onTrebleChanged,
                    size: knobSize,
                    valueFormatter: formatKnobValue,
                    labelFontSize: labelFontSize,
                    textSpacing: textSpacing,
                  ),
                  RotaryKnob(
                    label: 'PRES',
                    value: presence,
                    onValueChanged: onPresenceChanged,
                    size: knobSize,
                    valueFormatter: formatKnobValue,
                    labelFontSize: labelFontSize,
                    textSpacing: textSpacing,
                  ),
                  RotaryKnob(
                    label: 'VOL',
                    value: volume,
                    onValueChanged: onVolumeChanged,
                    size: knobSize,
                    valueFormatter: formatKnobValue,
                    labelFontSize: labelFontSize,
                    textSpacing: textSpacing,
                  ),
                  RotaryKnob(
                    label: 'REVERB',
                    value: reverbMix,
                    onValueChanged: onReverbMixChanged,
                    size: knobSize,
                    valueFormatter: formatKnobValue,
                    labelFontSize: labelFontSize,
                    textSpacing: textSpacing,
                  ),
                ],
              ),
            ),
            const Expanded(flex: 2, child: SizedBox()),
          ],
        );
      },
    );
  }
}
