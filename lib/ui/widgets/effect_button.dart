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
          borderRadius: BorderRadius.circular(6),
          // Black hole recessed effect - inverted shadows for sunken look
          boxShadow: [
            // Inner shadow top-left (dark, creates depth going IN)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.9),
              offset: const Offset(-2, -3),
              blurRadius: 6,
              spreadRadius: -2,
            ),
            // Inner shadow bottom-right (subtle light from below)
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.03),
              offset: const Offset(2, 3),
              blurRadius: 4,
              spreadRadius: -1,
            ),
            // Deep recess shadow (black hole effect)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.95),
              offset: const Offset(0, 0),
              blurRadius: 12,
              spreadRadius: -4,
            ),
          ],
          // Dark vignette border to enhance black hole edge
          border: Border.all(
            color: const Color(0xFF000000),
            width: 2,
          ),
        ),
        // Second container for the recessed surface
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            // Inverted gradient - darker at edges, slight light in center (like light at bottom of hole)
            gradient: const RadialGradient(
              center: Alignment.center,
              radius: 1.2,
              colors: [
                Color(0xFF0A0A0A), // Slightly lighter in center
                Color(0xFF020202), // Very dark at edges
                Color(0xFF000000), // Pure black at outer edge
              ],
              stops: [0.0, 0.7, 1.0],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Effect name with minimal dark orange glow when ON
              Text(
                label,
                style: TextStyle(
                  color: isOn ? const Color(0xFFCC6200) : const Color(0xFF4A4A4A), // Dark orange or dark gray
                  fontSize: labelFontSize ?? 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  // Minimal glow when ON
                  shadows: isOn
                      ? [
                          Shadow(
                            color: const Color(0xFFB85500).withValues(alpha: 0.4),
                            blurRadius: 4,
                          ),
                        ]
                      : null,
                ),
              ),
              // Model/preset name with barely visible glow when ON
              if (modelName != null && modelName!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  modelName!,
                  style: TextStyle(
                    color: isOn
                        ? const Color(0xFFCC6200).withValues(alpha: 0.7)
                        : const Color(0xFF3A3A3A),
                    fontSize: modelFontSize ?? 11,
                    shadows: isOn
                        ? [
                            Shadow(
                              color: const Color(0xFFB85500).withValues(alpha: 0.3),
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
    );
  }
}
