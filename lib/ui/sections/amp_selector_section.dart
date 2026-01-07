import 'package:flutter/material.dart';
import '../../services/pod_controller.dart';
import '../../models/app_settings.dart';
import '../../models/amp_models.dart';
import '../theme/pod_theme.dart';
import '../widgets/effect_button.dart';
import '../widgets/dot_matrix_lcd.dart';

/// Amp selector section (Row 1) with GATE/AMP buttons, LCD display, and CAB/MIC selectors.
///
/// Layout: 3/10/3 flex ratio
/// - Left: GATE and AMP buttons stacked vertically
/// - Center: Large LCD selector with amp/cab navigation
/// - Right: CAB and MIC dropdown buttons stacked vertically
class AmpSelectorSection extends StatelessWidget {
  final PodController podController;
  final bool isConnected;
  final bool gateEnabled;
  final bool ampEnabled;
  final String currentAmp;
  final String currentCab;
  final String currentMic;
  final bool ampChainLinked;
  final AppSettings settings;
  final VoidCallback onGateToggle;
  final VoidCallback onAmpToggle;
  final VoidCallback onGateLongPress;
  final VoidCallback onPreviousAmp;
  final VoidCallback onNextAmp;
  final VoidCallback onAmpTap;
  final VoidCallback onChainLinkToggle;
  final VoidCallback onCabTap;
  final VoidCallback onMicTap;

  const AmpSelectorSection({
    super.key,
    required this.podController,
    required this.isConnected,
    required this.gateEnabled,
    required this.ampEnabled,
    required this.currentAmp,
    required this.currentCab,
    required this.currentMic,
    required this.ampChainLinked,
    required this.settings,
    required this.onGateToggle,
    required this.onAmpToggle,
    required this.onGateLongPress,
    required this.onPreviousAmp,
    required this.onNextAmp,
    required this.onAmpTap,
    required this.onChainLinkToggle,
    required this.onCabTap,
    required this.onMicTap,
  });

  @override
  Widget build(BuildContext context) {
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
                  isOn: gateEnabled,
                  onTap: onGateToggle,
                  onLongPress: onGateLongPress,
                  color: PodColors.buttonOnGreen,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: EffectButton(
                  label: 'AMP',
                  isOn: ampEnabled,
                  onTap: onAmpToggle,
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
                  value: currentCab,
                  onTap: onCabTap,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _buildDropdownButton(
                  label: 'MIC',
                  value: currentMic,
                  onTap: onMicTap,
                ),
              ),
            ],
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
            onTap: onPreviousAmp,
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
                  onTap: onAmpTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: Builder(
                      builder: (context) {
                        final amp = podController.ampModel;
                        String line1;
                        String? line2;

                        if (amp == null) {
                          line1 = currentAmp;
                          line2 = null;
                        } else {
                          switch (settings.ampNameDisplayMode) {
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
                    onTap: onChainLinkToggle,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: PodColors.background.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        ampChainLinked ? Icons.link : Icons.link_off,
                        size: 16,
                        color: ampChainLinked
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
            onTap: onNextAmp,
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
            const SizedBox(height: 4),
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w400,
                color: PodColors.textPrimary,
                height: 1.2,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
            // Dropdown arrow removed per UI update; whole button is tappable
          ],
        ),
      ),
    );
  }
}
