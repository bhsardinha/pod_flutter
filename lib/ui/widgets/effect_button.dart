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

  /// Callback when button is long-pressed (open modal)
  final VoidCallback onLongPress;

  /// The color to use for text glow when lit (green or amber)
  final Color color;

  /// Optional font size for the main label
  final double? labelFontSize;

  /// Optional font size for the model/sub-label
  final double? modelFontSize;

  const EffectButton({
    super.key,
    required this.label,
    this.modelName,
    required this.isOn,
    required this.onTap,
    required this.onLongPress,
    this.color = PodColors.buttonOnAmber,
    this.labelFontSize,
    this.modelFontSize,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      onSecondaryTap: onLongPress,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          // Piano black glossy gradient
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1A1A), // Subtle highlight at top
              Color(0xFF0A0A0A), // Deep black in middle
              Color(0xFF000000), // Pure black at bottom
            ],
            stops: [0.0, 0.5, 1.0],
          ),
          borderRadius: BorderRadius.circular(12),
          // Outer bevel - raised button effect
          boxShadow: [
            // Top-left highlight (light source from top-left)
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.08),
              offset: const Offset(-1, -1),
              blurRadius: 2,
              spreadRadius: 0,
            ),
            // Bottom-right shadow (depth)
            const BoxShadow(
              color: Colors.black,
              offset: Offset(2, 2),
              blurRadius: 4,
              spreadRadius: 0,
            ),
            // Ambient shadow
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              offset: const Offset(0, 1),
              blurRadius: 3,
              spreadRadius: 0,
            ),
          ],
          // Subtle border for definition
          border: Border.all(color: const Color(0xFF2A2A2A), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Effect name with orange glow when ON
            Text(
              label,
              style: TextStyle(
                color: isOn
                    ? const Color(0xFFFF7A00)
                    : const Color(0xFF4A4A4A), // Orange or dark gray
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
                          color: const Color(0xFFFF7A00).withValues(alpha: 0.3),
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
                style: TextStyle(
                  color: isOn
                      ? const Color(0xFFFF7A00).withValues(alpha: 0.8)
                      : const Color(0xFF3A3A3A),
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
    );
  }
}
