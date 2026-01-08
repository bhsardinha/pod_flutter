import 'package:flutter/material.dart';
import '../theme/pod_theme.dart';

/// A realistic piano-black effect button with outer bevel and glowing text when on.
///
/// Features:
/// - Piano black glossy surface with outer bevel (raised button look)
/// - Realistic lighting and shadows for 3D depth
/// - When ON: Text glows with discrete color (green/amber)
/// - When OFF: Dark gray text, no glow
/// - Tap to toggle, long-press for settings
class EffectButton extends StatelessWidget {
  /// The effect name (e.g., "WAH", "STOMP", "DELAY")
  final String label;

  /// Optional current model/preset name (e.g., "Fassel")
  final String? modelName;

  /// Whether the effect is currently ON
  final bool isOn;

  /// Callback when button is tapped (toggle)
  final VoidCallback onTap;

  /// Callback when button is long-pressed (open modal) - optional
  final VoidCallback? onLongPress;

  /// The color to use for text glow when lit (green or amber)
  final Color color;

  /// Optional font size for the main label
  final double? labelFontSize;

  /// Optional font size for the model/sub-label
  final double? modelFontSize;

  /// Optional icon to display instead of text
  final IconData? icon;

  const EffectButton({
    super.key,
    required this.label,
    this.modelName,
    required this.isOn,
    required this.onTap,
    this.onLongPress,
    this.color = PodColors.buttonOnAmber,
    this.labelFontSize,
    this.modelFontSize,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      onSecondaryTap: onLongPress,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          // Pitch black hole background
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF000000), // Pure black
              Color(0xFF000000), // Pure black
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          // Inner shadows to create hole/cavity effect
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.9),
              offset: const Offset(4, 4),
              blurRadius: 2,
              spreadRadius: -3,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              offset: const Offset(-4, -4),
              blurRadius: 2,
              spreadRadius: -6,
            ),
          ],
        ),
        child: Container(
          margin: const EdgeInsets.all(0.5),
          decoration: BoxDecoration(
            // Deep glossy black gradient - slightly lighter
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF0F0F0F), // Very dark gray
                Color(0xFF0A0A0A), // Slightly darker
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              // Radical glossy bevel - left edge very short gradient
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      const Color(0xFF000000), // Pitch black
                      Colors.black.withValues(alpha: 0.1),
                      const Color(
                        0xFF666666,
                      ).withValues(alpha: 0.08), // Darker gray
                      Colors.transparent,
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.04, 0.08, 0.99, 1.0],
                  ),
                ),
              ),
              // Right edge - very short gradient
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [
                      const Color(0xFF000000), // Pitch black
                      Colors.black.withValues(alpha: 0.1),
                      const Color(
                        0xFF666666,
                      ).withValues(alpha: 0.10), // Darker gray
                      Colors.transparent,
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.04, 0.08, 0.99, 1.0],
                  ),
                ),
              ),
              // Top to bottom - very short gradient at top edge
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF000000), // Pitch black
                      Colors.black.withValues(alpha: 0.1),
                      const Color(
                        0xFF666666,
                      ).withValues(alpha: 0.1), // Darker gray
                      Colors.transparent,
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.05, 0.18, 0.99, 1.0],
                  ),
                ),
              ),
              // Bottom to top - very short gradient at bottom edge
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      const Color(0xFF000000), // Pitch black
                      Colors.black.withValues(alpha: 0.1),
                      const Color(
                        0xFF666666,
                      ).withValues(alpha: 0.08), // Darker gray
                      Colors.transparent,
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.05, 0.18, 0.99, 1.0],
                  ),
                ),
              ),
              // Content
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: icon != null
                      ? Icon(
                          icon,
                          color: isOn
                              ? const Color(0xFFFF7A00)
                              : const Color(0xFF6A6A6A),
                          size: 20,
                          shadows: isOn
                              ? [
                                  Shadow(
                                    color: const Color(0xFFFF7A00)
                                        .withValues(alpha: 0.15),
                                    blurRadius: 4,
                                  ),
                                  Shadow(
                                    color: const Color(0xFFFF7A00)
                                        .withValues(alpha: 0.3),
                                    blurRadius: 8,
                                  ),
                                  Shadow(
                                    color: const Color(0xFFFF7A00)
                                        .withValues(alpha: 0.15),
                                    blurRadius: 4,
                                  ),
                                ]
                              : null,
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Effect name with orange glow when ON
                            Text(
                              label,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isOn
                                    ? const Color(0xFFFF7A00)
                                    : const Color(
                                        0xFF6A6A6A), // Orange or lighter gray
                                fontSize: labelFontSize ?? 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                                // Discrete orange glow when ON
                                shadows: isOn
                                    ? [
                                        Shadow(
                                          color: const Color(
                                            0xFFFF7A00,
                                          ).withValues(alpha: 0.15),
                                          blurRadius: 4,
                                        ),
                                        Shadow(
                                          color: const Color(
                                            0xFFFF7A00,
                                          ).withValues(alpha: 0.3),
                                          blurRadius: 8,
                                        ),
                                        Shadow(
                                          color: const Color(
                                            0xFFFF7A00,
                                          ).withValues(alpha: 0.15),
                                          blurRadius: 4,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                            // Model/preset name with subtle orange glow when ON
                            if (modelName != null && modelName!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                modelName!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isOn
                                      ? const Color(0xFFFF7A00)
                                          .withValues(alpha: 0.8)
                                      : const Color(0xFF5A5A5A),
                                  fontSize: modelFontSize ?? 11,
                                  shadows: isOn
                                      ? [
                                          Shadow(
                                            color: const Color(
                                              0xFFFF7A00,
                                            ).withValues(alpha: 0.3),
                                            blurRadius: 3,
                                          ),
                                        ]
                                      : null,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
