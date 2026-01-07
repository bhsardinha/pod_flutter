import 'package:flutter/material.dart';
import '../theme/pod_theme.dart';
import '../widgets/effect_button.dart';
import '../widgets/patch_browser.dart';
import '../widgets/connection_indicator.dart';
import '../utils/value_formatters.dart';

/// Control bar section (Row 4) containing settings, WAH, FX LOOP,
/// patch browser, TAP, and MIDI connection indicator.
///
/// This is the bottom row of the main screen with all control functions.
class ControlBarSection extends StatelessWidget {
  final bool isConnected;
  final bool wahEnabled;
  final bool loopEnabled;
  final bool isModified;
  final int currentProgram;
  final String currentPatchName;
  final VoidCallback onSettings;
  final VoidCallback onWahToggle;
  final VoidCallback onWahLongPress;
  final VoidCallback onLoopToggle;
  final VoidCallback onPreviousPatch;
  final VoidCallback onNextPatch;
  final VoidCallback onPatchTap;
  final VoidCallback onTap;
  final VoidCallback onMidiTap;

  const ControlBarSection({
    super.key,
    required this.isConnected,
    required this.wahEnabled,
    required this.loopEnabled,
    required this.isModified,
    required this.currentProgram,
    required this.currentPatchName,
    required this.onSettings,
    required this.onWahToggle,
    required this.onWahLongPress,
    required this.onLoopToggle,
    required this.onPreviousPatch,
    required this.onNextPatch,
    required this.onPatchTap,
    required this.onTap,
    required this.onMidiTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Settings (flex 2)
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: onSettings,
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

        // WAH (flex 3) — EffectButton with smaller font, no model name
        Expanded(
          flex: 3,
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

        // FX LOOP (flex 3) — Two-line label
        Expanded(
          flex: 3,
          child: SizedBox.expand(
            child: GestureDetector(
              onTap: onLoopToggle,
              child: Container(
                decoration: BoxDecoration(
                  color: loopEnabled
                      ? PodColors.buttonOnAmber.withValues(alpha: 0.3)
                      : PodColors.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: loopEnabled ? PodColors.buttonOnAmber : PodColors.surfaceLight,
                    width: loopEnabled ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'FX',
                        style: TextStyle(
                          color: loopEnabled ? PodColors.buttonOnAmber : PodColors.textSecondary,
                          fontSize: 9,
                          fontWeight: loopEnabled ? FontWeight.w700 : FontWeight.w500,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        'LOOP',
                        style: TextStyle(
                          color: loopEnabled ? PodColors.buttonOnAmber : PodColors.textSecondary,
                          fontSize: 9,
                          fontWeight: loopEnabled ? FontWeight.w700 : FontWeight.w500,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Preset bar (flex 19)
        Expanded(
          flex: 19,
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

        // TAP (flex 3)
        Expanded(
          flex: 3,
          child: GestureDetector(
            onTap: onTap,
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
                      fontSize: 10,
                      letterSpacing: 1.2,
                    ),
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
              isConnected: isConnected,
              onTap: onMidiTap,
            ),
          ),
        ),
      ],
    );
  }
}
