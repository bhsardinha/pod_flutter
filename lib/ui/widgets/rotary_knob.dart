import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../theme/pod_theme.dart';

/// A minimalist rotary knob widget
///
/// Features:
/// - Clean geometric design
/// - Configurable value range (default 0-127)
/// - Rotating indicator line (~270° arc)
/// - Label and value display
/// - Optional value formatter for real values
/// - Vertical drag or circular gesture control
class RotaryKnob extends StatefulWidget {
  /// Label displayed below the knob
  final String label;

  /// Current value of the knob
  final int value;

  /// Minimum value (inclusive)
  final int minValue;

  /// Maximum value (inclusive)
  final int maxValue;

  /// Callback when the value changes
  final ValueChanged<int> onValueChanged;

  /// Size of the knob (diameter)
  final double size;

  /// Whether to show tick marks around the edge
  final bool showTickMarks;

  /// Optional formatter for displaying the value
  /// If null, displays the raw integer value
  final String Function(int value)? valueFormatter;

  const RotaryKnob({
    super.key,
    required this.label,
    required this.value,
    required this.onValueChanged,
    this.minValue = 0,
    this.maxValue = 127,
    this.size = 80.0,
    this.showTickMarks = true,
    this.valueFormatter,
  });

  @override
  State<RotaryKnob> createState() => _RotaryKnobState();
}

class _RotaryKnobState extends State<RotaryKnob> {
  late int _currentValue;
  Offset? _lastDragPosition;
  double _accumulatedDelta = 0.0;

  // Rotation angles: 7:30 (135°) to 4:30 (45°), 270° arc through the top
  // Start at 135° (7:30 position), sweep 270° clockwise to 45° (4:30 position)
  static const double _startAngle = 135.0 * math.pi / 180.0; // 2.356 rad (7:30)
  static const double _totalArc = 270.0 * math.pi / 180.0; // 4.712 rad

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value.clamp(widget.minValue, widget.maxValue);
  }

  @override
  void didUpdateWidget(RotaryKnob oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _currentValue = widget.value.clamp(widget.minValue, widget.maxValue);
    }
  }

  /// Convert value to angle (in radians)
  /// Min value at -135° (7:30), max value at 135° (4:30)
  double _valueToAngle(int value) {
    final normalizedValue =
        (value - widget.minValue) / (widget.maxValue - widget.minValue);
    return _startAngle + (normalizedValue * _totalArc);
  }

  /// Convert angle (in radians) to value
  int _angleToValue(double angle) {
    // Normalize angle to 0-2π range, then shift to match our start angle
    double normalizedAngle = angle;

    // Handle the wrap-around: our range goes from 135° through 360°/0° to 45°
    // First normalize to 0-2π
    while (normalizedAngle < 0) {
      normalizedAngle += 2 * math.pi;
    }
    while (normalizedAngle > 2 * math.pi) {
      normalizedAngle -= 2 * math.pi;
    }

    // Calculate how far we are from start angle
    double deltaFromStart = normalizedAngle - _startAngle;
    if (deltaFromStart < 0) deltaFromStart += 2 * math.pi;

    // Clamp to valid arc range
    if (deltaFromStart > _totalArc) {
      // We're in the dead zone (bottom of knob)
      // Snap to nearest end
      if (deltaFromStart > _totalArc + (2 * math.pi - _totalArc) / 2) {
        deltaFromStart = 0; // Snap to min
      } else {
        deltaFromStart = _totalArc; // Snap to max
      }
    }

    // Convert to 0-1 range
    double normalizedValue = deltaFromStart / _totalArc;

    // Convert to value range
    int value =
        (widget.minValue +
                normalizedValue * (widget.maxValue - widget.minValue))
            .round();

    return value.clamp(widget.minValue, widget.maxValue);
  }

  void _handleVerticalDrag(DragUpdateDetails details) {
    // Vertical drag: up = increase, down = decrease
    // Inverted sign so gestures map as expected for natural scroll settings
    _accumulatedDelta += details.delta.dy;

    // Sensitivity: pixels per value step
    const sensitivity = 2.0;

    if (_accumulatedDelta.abs() >= sensitivity) {
      final steps = (_accumulatedDelta / sensitivity).floor();
      _accumulatedDelta -= steps * sensitivity;

      final newValue = (_currentValue + steps).clamp(
        widget.minValue,
        widget.maxValue,
      );

      if (newValue != _currentValue) {
        setState(() {
          _currentValue = newValue;
        });
        widget.onValueChanged(newValue);
      }
    }
  }

  void _handleCircularDrag(DragUpdateDetails details, Offset center) {
    final position = details.localPosition;
    final delta = position - center;
    final angle = math.atan2(delta.dy, delta.dx);

    final newValue = _angleToValue(angle);

    if (newValue != _currentValue) {
      setState(() {
        _currentValue = newValue;
      });
      widget.onValueChanged(newValue);
    }
  }

  void _handleDragUpdate(DragUpdateDetails details, Offset center) {
    if (_lastDragPosition == null) {
      _lastDragPosition = details.localPosition;
      return;
    }

    final distanceFromCenter = (details.localPosition - center).distance;
    final knobRadius = widget.size / 2;

    if (distanceFromCenter < knobRadius * 1.2) {
      _handleCircularDrag(details, center);
    } else {
      _handleVerticalDrag(details);
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    _lastDragPosition = null;
    _accumulatedDelta = 0.0;
  }

  void _handleScroll(PointerScrollEvent event) {
    // Scroll handling: map scroll delta directly (adjusted for natural scroll)
    final delta = event.scrollDelta.dy;
    const sensitivity = 20.0; // pixels per value step

    final steps = (delta / sensitivity).round();
    if (steps != 0) {
      final newValue = (_currentValue + steps).clamp(
        widget.minValue,
        widget.maxValue,
      );
      if (newValue != _currentValue) {
        setState(() {
          _currentValue = newValue;
        });
        widget.onValueChanged(newValue);
      }
    }
  }

  String _getDisplayValue() {
    if (widget.valueFormatter != null) {
      return widget.valueFormatter!(_currentValue);
    }
    return _currentValue.toString();
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
        onPanUpdate: (details) {
          final RenderBox box = context.findRenderObject() as RenderBox;
          final center = Offset(box.size.width / 2, widget.size / 2);
          _handleDragUpdate(details, center);
        },
        onPanEnd: _handleDragEnd,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Value display above knob
            SizedBox(
              height: 16,
              child: Text(
                _getDisplayValue(),
                style: const TextStyle(
                  color: PodColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Knob
            SizedBox(
              width: widget.size,
              height: widget.size,
              child: CustomPaint(
                painter: _RotaryKnobPainter(
                  value: _currentValue,
                  minValue: widget.minValue,
                  maxValue: widget.maxValue,
                  angle: _valueToAngle(_currentValue),
                  showTickMarks: widget.showTickMarks,
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Label
            Text(
              widget.label,
              style: const TextStyle(
                color: PodColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for the minimalist rotary knob
class _RotaryKnobPainter extends CustomPainter {
  final int value;
  final int minValue;
  final int maxValue;
  final double angle;
  final bool showTickMarks;

  static const double _startAngle = 135.0 * math.pi / 180.0; // 7:30 position
  static const double _totalArc = 270.0 * math.pi / 180.0;

  _RotaryKnobPainter({
    required this.value,
    required this.minValue,
    required this.maxValue,
    required this.angle,
    required this.showTickMarks,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw tick marks (optional)
    if (showTickMarks) {
      _drawTickMarks(canvas, center, radius);
    }

    // Draw main knob body (solid circle)
    _drawKnobBody(canvas, center, radius);

    // Draw indicator line
    _drawIndicator(canvas, center, radius);
  }

  void _drawKnobBody(Canvas canvas, Offset center, double radius) {
    // Neumorphic-style knob body: soft shadow, subtle highlight, radial
    // gradient for a 3D appearance.

    // Soft shadow (bottom-right)
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center.translate(3, 3), radius * 0.85, shadowPaint);

    // Soft highlight (top-left)
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(center.translate(-2, -2), radius * 0.85, highlightPaint);

    // Main knob body with radial gradient
    final Rect knobRect = Rect.fromCircle(
      center: center,
      radius: radius * 0.85,
    );
    final Gradient grad = RadialGradient(
      center: const Alignment(-0.3, -0.3),
      radius: 0.9,
      colors: [
        PodColors.surfaceLight.withValues(alpha: 0.98),
        PodColors.surface.withValues(alpha: 1.0),
      ],
      stops: const [0.0, 1.0],
    );
    final bodyPaint = Paint()..shader = grad.createShader(knobRect);
    canvas.drawCircle(center, radius * 0.85, bodyPaint);

    // Thin rim to define edge
    final rimPaint = Paint()
      ..color = PodColors.textSecondary.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, radius * 0.85, rimPaint);

    // Bevel effect: subtle top-left highlight and bottom-right shadow
    final bevelOffset = radius * 0.04;
    final rimHighlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);
    canvas.drawCircle(
      center.translate(-bevelOffset, -bevelOffset),
      radius * 0.87,
      rimHighlightPaint,
    );

    final rimShadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.6);
    canvas.drawCircle(
      center.translate(bevelOffset, bevelOffset),
      radius * 0.87,
      rimShadowPaint,
    );

    // Inner ring to emphasize protrusion (slightly darker inner border)
    final innerRingRect = Rect.fromCircle(
      center: center,
      radius: radius * 0.65,
    );
    final innerRingPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.2, -0.2),
        radius: 0.9,
        colors: [
          Colors.white.withOpacity(0.03),
          Colors.black.withOpacity(0.06),
        ],
        stops: const [0.0, 1.0],
      ).createShader(innerRingRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.06;
    canvas.drawCircle(center, radius * 0.62, innerRingPaint);
  }

  void _drawTickMarks(Canvas canvas, Offset center, double radius) {
    const tickCount = 11;

    final tickPaint = Paint()
      ..color = PodColors.textSecondary.withValues(alpha: 0.4)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < tickCount; i++) {
      final tickAngle = _startAngle + (i / (tickCount - 1)) * _totalArc;
      final tickStart =
          center +
          Offset(
            math.cos(tickAngle) * (radius * 0.92),
            math.sin(tickAngle) * (radius * 0.92),
          );
      final tickEnd =
          center +
          Offset(math.cos(tickAngle) * radius, math.sin(tickAngle) * radius);

      canvas.drawLine(tickStart, tickEnd, tickPaint);
    }
  }

  void _drawIndicator(Canvas canvas, Offset center, double radius) {
    // Simple line indicator from center outward
    // Draw a subtle shadow for the indicator for depth
    final indicatorShadow = Paint()
      ..color = Colors.black.withOpacity(0.28)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final shadowStart =
        center +
        Offset(
          math.cos(angle) * (radius * 0.3 + 0.8),
          math.sin(angle) * (radius * 0.3 + 0.8),
        );
    final shadowEnd =
        center +
        Offset(
          math.cos(angle) * (radius * 0.7 + 0.8),
          math.sin(angle) * (radius * 0.7 + 0.8),
        );
    canvas.drawLine(shadowStart, shadowEnd, indicatorShadow);

    final indicatorPaint = Paint()
      ..color = PodColors.textPrimary
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final startPoint =
        center +
        Offset(
          math.cos(angle) * (radius * 0.3),
          math.sin(angle) * (radius * 0.3),
        );
    final endPoint =
        center +
        Offset(
          math.cos(angle) * (radius * 0.7),
          math.sin(angle) * (radius * 0.7),
        );

    canvas.drawLine(startPoint, endPoint, indicatorPaint);
  }

  @override
  bool shouldRepaint(_RotaryKnobPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.angle != angle ||
        oldDelegate.showTickMarks != showTickMarks;
  }
}
