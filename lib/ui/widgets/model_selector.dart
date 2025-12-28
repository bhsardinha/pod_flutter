import 'package:flutter/material.dart';
import '../theme/pod_theme.dart';

/// An LCD-style model selector widget that displays the current model name
/// (amp, cab, effect, etc.) with a retro green LCD display aesthetic.
///
/// Features:
/// - Dark green-tinted background (like old LCD displays)
/// - Green glowing text with chevrons « »
/// - Subtle inner shadow for recessed look
/// - Tap to open picker (calls onTap callback)
/// - Optional left/right swipe for prev/next models
///
/// Example usage:
/// ```dart
/// ModelSelector(
///   value: 'BRIT J-800',
///   label: 'AMP MODEL',
///   onTap: () => showModelPicker(),
///   onPrevious: () => selectPreviousModel(),
///   onNext: () => selectNextModel(),
/// )
/// ```
class ModelSelector extends StatelessWidget {
  /// The current model name to display
  final String value;

  /// Callback when the widget is tapped (e.g., to open a picker modal)
  final VoidCallback onTap;

  /// Optional callback for swipe left / previous model
  final VoidCallback? onPrevious;

  /// Optional callback for swipe right / next model
  final VoidCallback? onNext;

  /// Optional label to display above the LCD display
  final String? label;

  const ModelSelector({
    super.key,
    required this.value,
    required this.onTap,
    this.onPrevious,
    this.onNext,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Optional label above the LCD
        if (label != null) ...[
          Text(
            label!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
        ],

        // Model display
        GestureDetector(
          onTap: onTap,
          onHorizontalDragEnd: _handleSwipe,
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: PodColors.surface,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: PodColors.surfaceLight,
                width: 1,
              ),
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chevron_left,
                    color: PodColors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    value,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: PodColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.chevron_right,
                    color: PodColors.textSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Handles horizontal swipe gestures
  void _handleSwipe(DragEndDetails details) {
    // Calculate swipe velocity
    final velocity = details.primaryVelocity ?? 0;

    // Threshold for swipe detection (positive = right, negative = left)
    const swipeThreshold = 100;

    if (velocity > swipeThreshold && onNext != null) {
      // Swiped right -> next model
      onNext!();
    } else if (velocity < -swipeThreshold && onPrevious != null) {
      // Swiped left -> previous model
      onPrevious!();
    }
  }
}
