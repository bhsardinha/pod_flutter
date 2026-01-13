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
/// - Scroll wheel control (up = increase, down = decrease)
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

  /// Font size for the label
  final double labelFontSize;

  /// Spacing between knob and text above/below
  final double textSpacing;

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
    this.labelFontSize = 10.0,
    this.textSpacing = 4.0,
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
    // Negate delta.dy so upward drag (negative dy) increases value
    _accumulatedDelta -= details.delta.dy;

    // Sensitivity: pixels per value step (higher = less sensitive)
    const sensitivity = 5.0;

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
    const sensitivity = 50.0; // pixels per value step (higher = less sensitive)

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
          // Label above knob
          Text(
            widget.label,
            style: TextStyle(
              color: Colors.white,
              fontSize: widget.labelFontSize,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.8,
            ),
          ),
          SizedBox(height: widget.textSpacing),
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
          SizedBox(height: widget.textSpacing),
          // Value display below knob
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

    // Outer ring with cast lighting (45°) - one side lighter, opposite darker
    final outerR = radius * 0.99;
    final outerRect = Rect.fromCircle(center: center, radius: outerR);
    final outerPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.fromARGB(255, 40, 1, 13), // lit side
          Color.fromARGB(255, 54, 2, 12), // mid tone
          Color.fromARGB(255, 39, 1, 8), // shadowed side
        ],
        stops: [0.0, 0.5, 1.0],
      ).createShader(outerRect);
    canvas.drawCircle(center, outerR, outerPaint);

    // Draw eleven white dots along the knob's 270° arc on an outer transparent ring
    const int dotCount = 11;
    final double dotRadius = math.max(1.5, outerR * 0.015);
    final double dotDistance = outerR * 1.12; // place outside the outer ring
    final dotPaint = Paint()..color = Colors.white.withValues(alpha: 0.95);
    for (int i = 0; i < dotCount; i++) {
      final double a = _startAngle + (i / (dotCount - 1)) * _totalArc;
      final Offset p =
          center + Offset(math.cos(a) * dotDistance, math.sin(a) * dotDistance);
      canvas.drawCircle(p, dotRadius, dotPaint);
    }

    // Inner circle (SVG innerGradient: #6b3638 -> #4a2426)
    final innerR = outerR * 0.92; // maintain similar proportions to SVG
    final innerRect = Rect.fromCircle(center: center, radius: innerR);
    final innerPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment.center,
        radius: 0.55,
        colors: [
          Color.fromARGB(255, 48, 3, 16),
          Color.fromARGB(255, 65, 21, 27),
        ],
      ).createShader(innerRect);
    canvas.drawCircle(center, innerR, innerPaint);

    // Black center circle
    // Black center circle
    // Scale group (center circle, pointer rectangle, and dash) together
    const double groupScale = 1.32; // scale by 15%
    final centerR =
        outerR * 0.61 * groupScale; // matches SVG proportions (55/85)
    final centerPaint = Paint()..color = Colors.black;
    canvas.drawCircle(center, centerR, centerPaint);

    // Soft shadow to ground the knob slightly
    final shadowPaint = Paint()
      ..color = PodColors.knobShadow.withValues(alpha: 0.92)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center.translate(3, 3), centerR * 0.96, shadowPaint);

    // Rounded rectangular pointer (concentric to the black center circle)
    // Make pointer width exactly 40% of the black circle diameter (only width changed)
    final ptrWidth = centerR * 2.0 * 0.45; // 40% of black circle diameter
    final ptrHeight =
        size.height *
        0.6325 *
        1.015 *
        groupScale; // keep previous height scaling
    // Slightly increase corner rounding for a softer look
    final ptrRadius = ptrWidth * 0.22;

    // Center the pointer on the knob center so it's concentric with the black circle
    canvas.save();
    canvas.translate(center.dx, center.dy);
    // Rotate so the pointer's 'up' direction aligns with the indicator angle
    canvas.rotate(angle + math.pi / 2);
    final ptrRect = Rect.fromCenter(
      center: Offset.zero,
      width: ptrWidth,
      height: ptrHeight,
    );
    final ptrRRect = RRect.fromRectAndRadius(
      ptrRect,
      Radius.circular(ptrRadius),
    );

    // Pointer paint: three-stage vertical gradient (black -> almost-black -> black)
    final ptrPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.fromARGB(255, 22, 22, 22), // slight lighter center
          Color.fromARGB(255, 0, 0, 0), // top black
          Color.fromARGB(255, 20, 20, 20), // slight lighter center
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(ptrRect);
    canvas.drawRRect(ptrRRect, ptrPaint);

    // White dash aligned with the top of the rectangle (drawn in local rotated space)
    final dashPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = math.max(2.0, ptrWidth * 0.12)
      ..strokeCap = StrokeCap.round;
    // Place the white dash completely inside the rectangle with small padding
    final dashPadding = ptrHeight * 0.05;
    final dashLength = ptrHeight * 0.18;
    final dashStart = Offset(0, -ptrHeight * 0.5 + dashPadding);
    final dashEnd = Offset(0, -ptrHeight * 0.5 + dashPadding + dashLength);
    canvas.drawLine(dashStart, dashEnd, dashPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_RotaryKnobPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.angle != angle ||
        oldDelegate.showTickMarks != showTickMarks;
  }
}
