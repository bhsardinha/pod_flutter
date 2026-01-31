import 'package:flutter/material.dart';
import '../../services/pod_controller.dart';
import '../../models/app_settings.dart';
import '../../models/amp_models.dart';
import '../../protocol/cc_map.dart';
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
  final VoidCallback onCabLongPress;
  final VoidCallback onMicLongPress;
  final VoidCallback onMidiTap;
  final VoidCallback onTunerTap;

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
    required this.onCabLongPress,
    required this.onMicLongPress,
    required this.onMidiTap,
    required this.onTunerTap,
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
                  labelFontSize: 16,
                  useDynamicLabelSize: true,
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
                  labelFontSize: 16,
                  useDynamicLabelSize: true,
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
                child: EffectButton(
                  label: 'CAB',
                  modelName: currentCab,
                  isOn: podController.getParameter(PodXtCC.cabSelect) != 0,
                  onTap: onCabTap,
                  onLongPress: onCabLongPress,
                  labelFontSize: 16,
                  useDynamicLabelSize: true,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: EffectButton(
                  label: 'MIC',
                  modelName: currentMic,
                  isOn: podController.getParameter(PodXtCC.cabSelect) != 0, // Gray when No Cab selected
                  onTap: null, // No tap action for MIC
                  onLongPress: podController.getParameter(PodXtCC.cabSelect) != 0
                      ? onMicLongPress
                      : null, // Disable long-press when No Cab
                  labelFontSize: 16,
                  useDynamicLabelSize: true,
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
            width: 52,
            height: double.infinity,
            alignment: Alignment.center,
            child: const Icon(
              Icons.chevron_left,
              color: Color(
                0xFF3D0112,
              ), // Much darker to match darker brushed metal
              size: 50,
              shadows: [
                // Dark shadow on top-left (engraved depression)
                Shadow(
                  color: Color(0xE6000000),
                  offset: Offset(-1.5, -1.5),
                  blurRadius: 2.0,
                ),
                // Light highlight on bottom-right (edge catch light)
                Shadow(
                  color: Color(0x33FFFFFF),
                  offset: Offset(1.5, 1.5),
                  blurRadius: 2.0,
                ),
              ],
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
                                    color: PodColors.buttonOnGreen.withValues(
                                      alpha: 0.6,
                                    ),
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
                // Tuner button in top-center (letter A)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: onTunerTap,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'A',
                          style: TextStyle(
                            color: PodColors.accent,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0,
                          ),
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
            width: 50,
            height: double.infinity,
            alignment: Alignment.center,
            child: const Icon(
              Icons.chevron_right,
              color: Color(
                0xFF3D0112,
              ), // Much darker to match darker brushed metal
              size: 50,
              shadows: [
                // Dark shadow on top-left (engraved depression)
                Shadow(
                  color: Color(0xE6000000),
                  offset: Offset(-1.5, -1.5),
                  blurRadius: 2.0,
                ),
                // Light highlight on bottom-right (edge catch light)
                Shadow(
                  color: Color(0x33FFFFFF),
                  offset: Offset(1.5, 1.5),
                  blurRadius: 2.0,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

}
