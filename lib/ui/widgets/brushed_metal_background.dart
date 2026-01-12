import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Brushed metal background effect for POD controller
/// Creates a realistic brushed aluminum/steel appearance
class BrushedMetalBackground extends StatelessWidget {
  final Widget child;

  const BrushedMetalBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base brushed metal layer
        Positioned.fill(child: CustomPaint(painter: BrushedMetalPainter())),
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
    // Base color - much darker (stronger black)
    final baseColor = const ui.Color.fromARGB(255, 148, 1, 30);

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
      // Much darker effect - stronger black strokes
      final opacity = 0.015 + random.nextDouble() * 0.05;
      final brightness = random.nextDouble();

      // 80% chance of black (darkening), 20% chance of white (highlights)
      brushPaint.color = brightness > 0.8
          ? Colors.white.withValues(alpha: opacity * 0.2)
          : Colors.black.withValues(alpha: opacity * 1.5);

      canvas.drawLine(Offset(0, y), Offset(size.width, y), brushPaint);
    }

    // Add subtle vertical variation for realism (darker)
    for (double x = 0; x < size.width; x += 10) {
      final opacity = random.nextDouble() * 0.008;
      brushPaint.color = Colors.black.withValues(alpha: opacity);
      brushPaint.strokeWidth = 0.6;

      canvas.drawLine(Offset(x, 0), Offset(x, size.height), brushPaint);
    }

    // Add stronger gradient overlay for depth
    final gradient = ui.Gradient.linear(
      Offset(0, 0),
      Offset(size.width, 0),
      [
        Colors.black.withValues(alpha: 0.04),
        Colors.transparent,
        Colors.black.withValues(alpha: 0.05),
      ],
      [0.0, 0.5, 1.0],
    );

    final gradientPaint = Paint()
      ..shader = gradient
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      gradientPaint,
    );

    // Add very subtle vignette effect (almost imperceptible)
    final vignette = ui.Gradient.radial(
      Offset(size.width / 2, size.height / 2),
      math.max(size.width, size.height) * 0.7,
      [
        Colors.transparent,
        Colors.black.withValues(alpha: 0.0001),
        Colors.black.withValues(alpha: 0.0002),
      ],
      [0.0, 0.95, 1.0],
    );

    final vignettePaint = Paint()
      ..shader = vignette
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      vignettePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
