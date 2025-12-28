import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/pod_theme.dart';

/// A skeuomorphic rotary knob widget with metallic appearance
///
/// Features:
/// - Metallic gradient appearance
/// - Configurable value range (default 0-127)
/// - Rotating indicator dot (~270° arc)
/// - Label and value display
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

  const RotaryKnob({
    super.key,
    required this.label,
    required this.value,
    required this.onValueChanged,
    this.minValue = 0,
    this.maxValue = 127,
    this.size = 80.0,
    this.showTickMarks = true,
  });

  @override
  State<RotaryKnob> createState() => _RotaryKnobState();
}

class _RotaryKnobState extends State<RotaryKnob> {
  late int _currentValue;
  Offset? _lastDragPosition;
  double _accumulatedDelta = 0.0;

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
  /// 270° arc of rotation, starting from bottom-left (-135°)
  double _valueToAngle(int value) {
    final normalizedValue =
        (value - widget.minValue) / (widget.maxValue - widget.minValue);
    // Start at -135° (bottom-left), end at +135° (bottom-right)
    // Total rotation: 270°
    const startAngle = -135.0 * math.pi / 180.0; // -2.356 rad
    const arcAngle = 270.0 * math.pi / 180.0; // 4.712 rad
    return startAngle + (normalizedValue * arcAngle);
  }

  /// Convert angle (in radians) to value
  int _angleToValue(double angle) {
    // Normalize angle to 0-2π range
    double normalizedAngle = angle % (2 * math.pi);
    if (normalizedAngle < 0) normalizedAngle += 2 * math.pi;

    // Convert to -π to π range for easier calculation
    if (normalizedAngle > math.pi) normalizedAngle -= 2 * math.pi;

    // Map angle range [-2.356, 2.356] to [0, 1]
    const startAngle = -135.0 * math.pi / 180.0;
    const endAngle = 135.0 * math.pi / 180.0;

    // Clamp angle to valid range
    double clampedAngle = normalizedAngle.clamp(startAngle, endAngle);

    // Convert to 0-1 range
    double normalizedValue = (clampedAngle - startAngle) / (endAngle - startAngle);

    // Convert to value range
    int value = (widget.minValue +
            normalizedValue * (widget.maxValue - widget.minValue))
        .round();

    return value.clamp(widget.minValue, widget.maxValue);
  }

  void _handleVerticalDrag(DragUpdateDetails details) {
    // Vertical drag: up = increase, down = decrease
    // Accumulate small movements to prevent jitter
    _accumulatedDelta += -details.delta.dy;

    // Sensitivity: pixels per value step
    const sensitivity = 2.0;

    if (_accumulatedDelta.abs() >= sensitivity) {
      final steps = (_accumulatedDelta / sensitivity).floor();
      _accumulatedDelta -= steps * sensitivity;

      final newValue = (_currentValue + steps).clamp(widget.minValue, widget.maxValue);

      if (newValue != _currentValue) {
        setState(() {
          _currentValue = newValue;
        });
        widget.onValueChanged(newValue);
      }
    }
  }

  void _handleCircularDrag(DragUpdateDetails details, Offset center) {
    // Circular drag: calculate angle from center
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
    // Determine if this is vertical or circular drag
    // If drag starts near center, use circular; otherwise use vertical
    if (_lastDragPosition == null) {
      _lastDragPosition = details.localPosition;
      return;
    }

    final distanceFromCenter = (details.localPosition - center).distance;
    final knobRadius = widget.size / 2;

    // If within knob radius, prefer circular drag
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final center = Offset(box.size.width / 2, widget.size / 2);
        _handleDragUpdate(details, center);
      },
      onPanEnd: _handleDragEnd,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
          const SizedBox(height: 8),
          // Label
          Text(
            widget.label,
            style: const TextStyle(
              color: PodColors.textLabel,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          // Value display
          Text(
            _currentValue.toString(),
            style: const TextStyle(
              color: PodColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the rotary knob
class _RotaryKnobPainter extends CustomPainter {
  final int value;
  final int minValue;
  final int maxValue;
  final double angle;
  final bool showTickMarks;

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

    // Draw shadow
    _drawShadow(canvas, center, radius);

    // Draw main knob body with metallic gradient
    _drawKnobBody(canvas, center, radius);

    // Draw tick marks (optional)
    if (showTickMarks) {
      _drawTickMarks(canvas, center, radius);
    }

    // Draw center cap
    _drawCenterCap(canvas, center, radius);

    // Draw indicator dot
    _drawIndicator(canvas, center, radius);
  }

  void _drawShadow(Canvas canvas, Offset center, double radius) {
    final shadowPaint = Paint()
      ..color = PodColors.knobShadow.withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawCircle(
      center + const Offset(2, 2),
      radius,
      shadowPaint,
    );
  }

  void _drawKnobBody(Canvas canvas, Offset center, double radius) {
    // Outer metallic gradient (radial gradient for 3D effect)
    final gradientPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          PodColors.knobHighlight,
          PodColors.knobBase,
          PodColors.knobShadow,
        ],
        stops: const [0.0, 0.6, 1.0],
        center: const Alignment(-0.3, -0.3), // Light from top-left
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, gradientPaint);

    // Add subtle edge highlight for more depth
    final edgeHighlight = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..shader = SweepGradient(
        colors: [
          PodColors.knobHighlight.withValues(alpha: 0.3),
          Colors.transparent,
          Colors.transparent,
          PodColors.knobHighlight.withValues(alpha: 0.3),
        ],
        stops: const [0.0, 0.25, 0.75, 1.0],
        startAngle: -math.pi / 4,
        endAngle: (7 * math.pi) / 4,
      ).createShader(Rect.fromCircle(center: center, radius: radius - 1));

    canvas.drawCircle(center, radius - 1, edgeHighlight);

    // Inner shadow for depth
    final innerShadow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = PodColors.knobShadow.withValues(alpha: 0.5);

    canvas.drawCircle(center, radius - 2, innerShadow);
  }

  void _drawTickMarks(Canvas canvas, Offset center, double radius) {
    const startAngle = -135.0 * math.pi / 180.0;
    const endAngle = 135.0 * math.pi / 180.0;
    const tickCount = 11; // 11 ticks for 0, 12.7, 25.4, ..., 127

    final tickPaint = Paint()
      ..color = PodColors.knobShadow
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < tickCount; i++) {
      final tickAngle = startAngle + (i / (tickCount - 1)) * (endAngle - startAngle);
      final tickStart = center +
          Offset(
            math.cos(tickAngle) * (radius - 8),
            math.sin(tickAngle) * (radius - 8),
          );
      final tickEnd = center +
          Offset(
            math.cos(tickAngle) * (radius - 3),
            math.sin(tickAngle) * (radius - 3),
          );

      canvas.drawLine(tickStart, tickEnd, tickPaint);
    }
  }

  void _drawCenterCap(Canvas canvas, Offset center, double radius) {
    final capRadius = radius * 0.25;

    // Center cap with gradient
    final capGradient = Paint()
      ..shader = RadialGradient(
        colors: [
          PodColors.knobHighlight,
          PodColors.knobBase,
        ],
        stops: const [0.0, 1.0],
        center: const Alignment(-0.4, -0.4),
      ).createShader(Rect.fromCircle(center: center, radius: capRadius));

    canvas.drawCircle(center, capRadius, capGradient);

    // Cap outline
    final capOutline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = PodColors.knobShadow;

    canvas.drawCircle(center, capRadius, capOutline);
  }

  void _drawIndicator(Canvas canvas, Offset center, double radius) {
    // Indicator position (on the edge of the knob)
    final indicatorRadius = radius * 0.75;
    final indicatorPosition = center +
        Offset(
          math.cos(angle) * indicatorRadius,
          math.sin(angle) * indicatorRadius,
        );

    // Indicator dot with glow effect
    final glowPaint = Paint()
      ..color = PodColors.knobIndicator.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawCircle(indicatorPosition, 6, glowPaint);

    // Indicator dot
    final indicatorPaint = Paint()..color = PodColors.knobIndicator;

    canvas.drawCircle(indicatorPosition, 4, indicatorPaint);

    // Indicator dot highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8);

    canvas.drawCircle(
      indicatorPosition + const Offset(-1, -1),
      1.5,
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(_RotaryKnobPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.angle != angle ||
        oldDelegate.showTickMarks != showTickMarks;
  }
}
