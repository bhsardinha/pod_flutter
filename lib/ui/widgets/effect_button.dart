import 'package:flutter/material.dart';
import '../theme/pod_theme.dart';

/// A backlit effect button widget that simulates a button with an internal light.
///
/// This widget is designed for effect buttons like WAH, STOMP, MOD, DELAY, REVERB, GATE, EQ.
/// The entire button acts as the indicator - when ON, it glows with color; when OFF, it's dark.
///
/// Features:
/// - Two states: OFF (grayed/dark) and ON (lit/colored with glow)
/// - Tap to toggle ON/OFF
/// - Hold for 600ms to trigger long press (e.g., open modal)
/// - Shows effect name and optional model name
///
/// Example usage:
/// ```dart
/// EffectButton(
///   label: 'WAH',
///   modelName: 'Fassel',
///   isOn: wahEnabled,
///   onTap: () => setState(() => wahEnabled = !wahEnabled),
///   onLongPress: () => showWahSettingsModal(),
///   color: PodColors.buttonOnGreen,
/// )
/// ```
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

  /// The color to use when the button is lit (green or amber)
  final Color color;

  const EffectButton({
    super.key,
    required this.label,
    this.modelName,
    required this.isOn,
    required this.onTap,
    required this.onLongPress,
    this.color = PodColors.buttonOnGreen,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      onLongPressStart: (_) {
        // Trigger haptic feedback on long press if available
        // HapticFeedback.mediumImpact();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isOn ? color.withValues(alpha: 0.3) : PodColors.buttonOff,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isOn ? color.withValues(alpha: 0.5) : PodColors.buttonOff.withValues(alpha: 0.5),
            width: 1,
          ),
          boxShadow: isOn
              ? [
                  // Inner glow effect
                  BoxShadow(
                    color: color.withValues(alpha: 0.6),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                  // Outer glow effect
                  BoxShadow(
                    color: PodColors.buttonGlow.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Effect name (e.g., "WAH")
            Text(
              label,
              style: TextStyle(
                color: isOn ? Colors.white : PodColors.buttonOffText,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            // Model/preset name (e.g., "Fassel") - optional
            if (modelName != null && modelName!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '"$modelName"',
                style: TextStyle(
                  color: isOn
                      ? Colors.white.withValues(alpha: 0.8)
                      : PodColors.buttonOffText.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
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
