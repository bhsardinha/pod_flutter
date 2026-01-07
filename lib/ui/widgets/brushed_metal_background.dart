import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Brushed metal background effect for POD controller
/// Creates a realistic brushed aluminum/steel appearance
class BrushedMetalBackground extends StatelessWidget {
  final Widget child;

  const BrushedMetalBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base brushed metal layer
        Positioned.fill(
          child: CustomPaint(
            painter: BrushedMetalPainter(),
          ),
        ),
        // Child content on top
        child,
      ],
    );
  }
}

/// Custom painter that creates a brushed metal effect
class BrushedMetalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Base color 10% darker (#a80239 darkened)
    final baseColor = const Color(0xFF970233);

    // Draw base layer
    final basePaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), basePaint);

    // Create brushed texture with horizontal lines
    final random = math.Random(42); // Fixed seed for consistent pattern
    final brushPaint = Paint()
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw darker horizontal brush strokes (mostly black for darkening effect)
    for (double y = 0; y < size.height; y += 0.5) {
      // Darker effect - bias towards black strokes
      final opacity = 0.01 + random.nextDouble() * 0.03;
      final brightness = random.nextDouble();

      // 70% chance of black (darkening), 30% chance of white (highlights)
      brushPaint.color = brightness > 0.7
          ? Colors.white.withValues(alpha: opacity * 0.3)
          : Colors.black.withValues(alpha: opacity);

      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        brushPaint,
      );
    }

    // Add subtle vertical variation for realism (darker)
    for (double x = 0; x < size.width; x += 10) {
      final opacity = random.nextDouble() * 0.008;
      brushPaint.color = Colors.black.withValues(alpha: opacity);
      brushPaint.strokeWidth = 0.5;

      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        brushPaint,
      );
    }

    // Add subtle gradient overlay for depth (darker)
    final gradient = ui.Gradient.linear(
      Offset(0, 0),
      Offset(size.width, 0),
      [
        Colors.black.withValues(alpha: 0.015),
        Colors.transparent,
        Colors.black.withValues(alpha: 0.025),
      ],
      [0.0, 0.5, 1.0],
    );

    final gradientPaint = Paint()
      ..shader = gradient
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), gradientPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
