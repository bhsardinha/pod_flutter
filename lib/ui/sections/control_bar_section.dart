import 'package:flutter/material.dart';
import '../widgets/effect_button.dart';
import '../widgets/patch_browser.dart';
import '../widgets/tap_button.dart';
import '../utils/value_formatters.dart';

/// Control bar section (Row 4) containing settings, WAH, FX LOOP,
/// patch browser, and TAP.
///
/// This is the bottom row of the main screen with all control functions.
class ControlBarSection extends StatelessWidget {
  final bool wahEnabled;
  final bool loopEnabled;
  final bool isModified;
  final int currentProgram;
  final String currentPatchName;
  final int currentBpm;
  final bool isDelayTempoSynced;
  final bool enableTempoScrolling;
  final VoidCallback onSettings;
  final VoidCallback onWahToggle;
  final VoidCallback onWahLongPress;
  final VoidCallback onLoopToggle;
  final VoidCallback onPreviousPatch;
  final VoidCallback onNextPatch;
  final VoidCallback onPatchTap;
  final VoidCallback onTap;
  final Function(int newBpm) onTempoChanged;

  const ControlBarSection({
    super.key,
    required this.wahEnabled,
    required this.loopEnabled,
    required this.isModified,
    required this.currentProgram,
    required this.currentPatchName,
    required this.currentBpm,
    required this.isDelayTempoSynced,
    required this.enableTempoScrolling,
    required this.onSettings,
    required this.onWahToggle,
    required this.onWahLongPress,
    required this.onLoopToggle,
    required this.onPreviousPatch,
    required this.onNextPatch,
    required this.onPatchTap,
    required this.onTap,
    required this.onTempoChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // WAH (flex 1.5) — EffectButton with smaller font, no model name
        Expanded(
          flex: 15,
          child: SizedBox.expand(
            child: EffectButton(
              label: 'WAH',
              isOn: wahEnabled,
              onTap: onWahToggle,
              onLongPress: onWahLongPress,
              labelFontSize: 10,
            ),
          ),
        ),
        const SizedBox(width: 12),

        // FX LOOP (flex 1.5) — EffectButton with smaller font, no modal
        Expanded(
          flex: 15,
          child: SizedBox.expand(
            child: EffectButton(
              label: 'FX LOOP',
              isOn: loopEnabled,
              onTap: onLoopToggle,
              labelFontSize: 10,
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Preset bar (flex 10)
        Expanded(
          flex: 100,
          child: SizedBox.expand(
            child: PatchBrowser(
              bank: formatProgramName(currentProgram),
              patchName: currentPatchName,
              isModified: isModified,
              onPrevious: onPreviousPatch,
              onNext: onNextPatch,
              onTap: onPatchTap,
            ),
          ),
        ),
        const SizedBox(width: 12),

        // TAP (flex 1.5) — Blinks at current BPM (only when delay is tempo-synced)
        Expanded(
          flex: 15,
          child: SizedBox.expand(
            child: TapButton(
              bpm: currentBpm,
              isTempoSynced: isDelayTempoSynced,
              enableScrolling: enableTempoScrolling,
              onTap: onTap,
              onTempoChanged: onTempoChanged,
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Settings (flex 1.5) — EffectButton with icon
        Expanded(
          flex: 15,
          child: SizedBox.expand(
            child: EffectButton(
              label: 'SET',
              isOn: false,
              onTap: onSettings,
              icon: Icons.settings,
            ),
          ),
        ),
      ],
    );
  }
}
