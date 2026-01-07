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
  final VoidCallback onMidiTap;

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
    required this.onMidiTap,
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
    return Row(
      children: [
        // Left arrow — independent button
        GestureDetector(
          onTap: onPreviousAmp,
          child: Container(
            width: 36,
            height: double.infinity,
            alignment: Alignment.center,
            child: const Icon(
              Icons.chevron_left,
              color: PodColors.textSecondary,
              size: 28,
            ),
          ),
        ),

        // Center: LCD display
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Stack(
              children: [
                // LCD
                GestureDetector(
                  onTap: onAmpTap,
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
                          horizontal: 16,
                          vertical: 8,
                        ),
                        line1Size: 40,
                        line2Size: 20,
                      );
                    },
                  ),
                ),
                // Connection status icon in top-left corner
                Positioned(
                  top: 2,
                  left: 2,
                  child: GestureDetector(
                    onTap: onMidiTap,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Container(
                        width: 13,
                        height: 13,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isConnected
                              ? PodColors.buttonOnGreen
                              : const Color(0xFFCC0000),
                          boxShadow: isConnected
                              ? [
                                  BoxShadow(
                                    color: PodColors.buttonOnGreen
                                        .withValues(alpha: 0.6),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
                // Chain link toggle icon in top-right corner
                Positioned(
                  top: 2,
                  right: 2,
                  child: GestureDetector(
                    onTap: onChainLinkToggle,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        ampChainLinked ? Icons.link : Icons.link_off,
                        size: 17,
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
        ),

        // Right arrow — independent button
        GestureDetector(
          onTap: onNextAmp,
          child: Container(
            width: 36,
            height: double.infinity,
            alignment: Alignment.center,
            child: const Icon(
              Icons.chevron_right,
              color: PodColors.textSecondary,
              size: 28,
            ),
          ),
        ),
      ],
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
          borderRadius: BorderRadius.circular(12),
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
