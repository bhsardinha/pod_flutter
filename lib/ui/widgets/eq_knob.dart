import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:math' as math;
import '../theme/pod_theme.dart';

/// Modern EQ frequency knob with red display
class EqKnob extends StatefulWidget {
  final String label;
  final int value; // 0-127 MIDI value
  final ValueChanged<int> onValueChanged;
  final String Function(int) valueFormatter;
  final double size;

  const EqKnob({
    super.key,
    required this.label,
    required this.value,
    required this.onValueChanged,
    required this.valueFormatter,
    this.size = 32.0,
  });

  @override
  State<EqKnob> createState() => _EqKnobState();
}

class _EqKnobState extends State<EqKnob> {
  late int _currentValue;
  double _accumulatedDragDistance = 0.0;
  double _accumulatedScrollDistance = 0.0;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value;
  }

  @override
  void didUpdateWidget(EqKnob oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _currentValue = widget.value;
    }
  }

  double _valueToAngle(int value) {
    const minAngle = -math.pi * 0.75 - math.pi / 2; // Rotated 90° counterclockwise
    const maxAngle = math.pi * 0.75 - math.pi / 2;
    final normalized = value / 127.0;
    return minAngle + (normalized * (maxAngle - minAngle));
  }

  void _handleDrag(DragUpdateDetails details) {
    // DISTANCE-BASED drag: only vertical movement, accumulate distance
    // Negate delta.dy so upward drag (negative dy) increases value
    _accumulatedDragDistance -= details.delta.dy;

    // Distance threshold: pixels needed per step (higher = more distance needed)
    const double threshold = 2.5;

    // Calculate how many steps we've accumulated
    final steps = (_accumulatedDragDistance / threshold).truncate();

    if (steps != 0) {
      final newValue = (_currentValue + steps).clamp(0, 127);

      if (newValue != _currentValue) {
        setState(() {
          _currentValue = newValue;
        });
        widget.onValueChanged(newValue);

        // Subtract the distance we "consumed" for these steps
        _accumulatedDragDistance -= steps * threshold;
      }
    }
  }

  void _handleScroll(PointerScrollEvent event) {
    // DISTANCE-BASED scroll: accumulate scroll distance, only step when threshold reached
    final delta = event.scrollDelta.dy;
    _accumulatedScrollDistance += delta;

    // Distance threshold: pixels needed per step (higher = more distance needed)
    const double threshold = 50.0;

    // Calculate how many steps we've accumulated
    final steps = (_accumulatedScrollDistance / threshold).truncate();

    if (steps != 0) {
      final newValue = (_currentValue + steps).clamp(0, 127);

      if (newValue != _currentValue) {
        setState(() {
          _currentValue = newValue;
        });
        widget.onValueChanged(newValue);

        // Subtract the distance we "consumed" for these steps
        _accumulatedScrollDistance -= steps * threshold;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) {
          _handleScroll(event);
        }
      },
      child: GestureDetector(
        onPanUpdate: _handleDrag,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Label
            Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'OPTICopperplate',
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: PodColors.textLabel.withValues(alpha: 0.7),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 4),
            // Knob
            SizedBox(
              width: widget.size,
              height: widget.size,
              child: CustomPaint(
                painter: _EqKnobPainter(
                  value: _currentValue,
                  angle: _valueToAngle(_currentValue),
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Value display with fixed height
            SizedBox(
              height: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(
                    color: const Color(0xFFFF3333).withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  widget.valueFormatter(_currentValue),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF3333), // Red digital display
                    letterSpacing: 0.5,
                    height: 1.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EqKnobPainter extends CustomPainter {
  final int value;
  final double angle;

  _EqKnobPainter({
    required this.value,
    required this.angle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw outer shadow
    final outerShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(center, radius - 1, outerShadowPaint);

    // Draw knob body with metallic gradient
    final bodyGradient = RadialGradient(
      colors: [
        const Color(0xFF2a2a2a),
        const Color(0xFF1a1a1a),
        const Color(0xFF0a0a0a),
      ],
      stops: const [0.0, 0.6, 1.0],
    );

    final bodyPaint = Paint()
      ..shader = bodyGradient.createShader(
        Rect.fromCircle(center: center, radius: radius - 2),
      );

    canvas.drawCircle(center, radius - 2, bodyPaint);

    // Draw rim highlight
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.3),
          Colors.white.withValues(alpha: 0.05),
          Colors.black.withValues(alpha: 0.4),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius - 2));

    canvas.drawCircle(center, radius - 2.5, rimPaint);

    // Draw value arc (red glow)
    final normalizedValue = value / 127.0;
    const startAngle = -math.pi * 0.75 - math.pi / 2; // -135 degrees, rotated 90° counterclockwise
    const sweepAngle = math.pi * 1.5; // 270 degrees range

    // Arc track background
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..color = Colors.black.withValues(alpha: 0.5);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 6),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    // Arc value (red)
    if (normalizedValue > 0) {
      final valuePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(
          colors: [
            const Color(0xFFFF3333).withValues(alpha: 0.5),
            const Color(0xFFFF3333),
          ],
        ).createShader(
          Rect.fromCircle(center: center, radius: radius - 6),
        );

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 6),
        startAngle,
        sweepAngle * normalizedValue,
        false,
        valuePaint,
      );
    }

    // Draw pointer indicator
    final pointerLength = radius - 8;
    final pointerEnd = Offset(
      center.dx + pointerLength * math.cos(angle),
      center.dy + pointerLength * math.sin(angle),
    );

    // Pointer shadow
    final pointerShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.6)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    canvas.drawLine(center, pointerEnd, pointerShadowPaint);

    // Pointer
    final pointerPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFFF3333),
          const Color(0xFFCC0000),
        ],
      ).createShader(Rect.fromPoints(center, pointerEnd))
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, pointerEnd, pointerPaint);

    // Draw center cap
    final capGradient = RadialGradient(
      colors: [
        const Color(0xFF3a3a3a),
        const Color(0xFF1a1a1a),
      ],
    );

    final capPaint = Paint()
      ..shader = capGradient.createShader(
        Rect.fromCircle(center: center, radius: 4),
      );

    canvas.drawCircle(center, 4, capPaint);

    // Center cap highlight
    final capHighlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2);

    canvas.drawCircle(
      Offset(center.dx - 1, center.dy - 1),
      2,
      capHighlightPaint,
    );
  }

  @override
  bool shouldRepaint(_EqKnobPainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.angle != angle;
  }
}
