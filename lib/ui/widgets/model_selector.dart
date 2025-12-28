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

        // LCD Display
        GestureDetector(
          onTap: onTap,
          onHorizontalDragEnd: _handleSwipe,
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.grey.shade800,
                width: 2,
              ),
              boxShadow: [
                // Outer shadow for depth
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Container(
              margin: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                // Inner shadow effect using gradient
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    PodColors.lcdBackground,
                    PodColors.lcdBackground,
                    Colors.black.withValues(alpha: 0.6),
                  ],
                  stops: const [0.0, 0.15, 0.85, 1.0],
                ),
                boxShadow: [
                  // Inner shadow effect (top)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Subtle scanline effect overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.1),
                          ],
                          stops: const [0.5, 0.5],
                          tileMode: TileMode.repeated,
                        ),
                      ),
                    ),
                  ),

                  // LCD Text with glow
                  Center(
                    child: Text(
                      '« $value »',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        fontFamily: 'monospace',
                        color: PodColors.lcdText,
                        shadows: [
                          // Glow effect
                          Shadow(
                            color: PodColors.lcdGlow,
                            blurRadius: 8,
                          ),
                          Shadow(
                            color: PodColors.lcdGlow,
                            blurRadius: 16,
                          ),
                          Shadow(
                            color: PodColors.lcdGlow.withValues(alpha: 0.5),
                            blurRadius: 24,
                          ),
                        ],
                      ),
                    ),
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
