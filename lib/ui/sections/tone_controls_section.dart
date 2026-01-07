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
                size: 72,
                valueFormatter: formatKnobValue,
              ),
              RotaryKnob(
                label: 'BASS',
                value: bass,
                onValueChanged: onBassChanged,
                size: 72,
                valueFormatter: formatKnobValue,
              ),
              RotaryKnob(
                label: 'MID',
                value: mid,
                onValueChanged: onMidChanged,
                size: 72,
                valueFormatter: formatKnobValue,
              ),
              RotaryKnob(
                label: 'TREBLE',
                value: treble,
                onValueChanged: onTrebleChanged,
                size: 72,
                valueFormatter: formatKnobValue,
              ),
              RotaryKnob(
                label: 'PRES',
                value: presence,
                onValueChanged: onPresenceChanged,
                size: 72,
                valueFormatter: formatKnobValue,
              ),
              RotaryKnob(
                label: 'VOL',
                value: volume,
                onValueChanged: onVolumeChanged,
                size: 72,
                valueFormatter: formatKnobValue,
              ),
              RotaryKnob(
                label: 'REVERB',
                value: reverbMix,
                onValueChanged: onReverbMixChanged,
                size: 72,
                valueFormatter: formatKnobValue,
              ),
            ],
          ),
        ),
        const Expanded(flex: 2, child: SizedBox()),
      ],
    );
  }
}
