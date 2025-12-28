import 'package:flutter/material.dart';
import '../theme/pod_theme.dart';
import 'dart:math' as math;

/// A bipolar vertical fader widget for EQ controls.
///
/// This is a CENTER-ZERO fader where:
/// - Zero (0dB) is in the CENTER of the fader
/// - Dragging UP = boost (+dB)
/// - Dragging DOWN = cut (-dB)
/// - The fill extends FROM CENTER TO the handle position
class VerticalFader extends StatefulWidget {
  /// Current value (e.g., -6.0 to +6.0 dB)
  final double value;

  /// Minimum value (e.g., -12 dB)
  final double min;

  /// Maximum value (e.g., +12 dB)
  final double max;

  /// Callback when value changes
  final ValueChanged<double> onChanged;

  /// Optional label displayed at the bottom
  final String? label;

  /// Width of the fader track
  final double width;

  /// Height of the fader track
  final double height;

  /// Whether to show the value display
  final bool showValue;

  /// Custom fill color (defaults to accent orange)
  final Color? fillColor;

  const VerticalFader({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = -12.0,
    this.max = 12.0,
    this.label,
    this.width = 40.0,
    this.height = 200.0,
    this.showValue = true,
    this.fillColor,
  });

  @override
  State<VerticalFader> createState() => _VerticalFaderState();
}

class _VerticalFaderState extends State<VerticalFader> {
  double _currentValue = 0.0;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value.clamp(widget.min, widget.max);
  }

  @override
  void didUpdateWidget(VerticalFader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _currentValue = widget.value.clamp(widget.min, widget.max);
    }
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      // Convert vertical drag to value change
      // Negative dy means dragging up (increase value)
      final double sensitivity = (widget.max - widget.min) / widget.height;
      _currentValue -= details.delta.dy * sensitivity;
      _currentValue = _currentValue.clamp(widget.min, widget.max);
      widget.onChanged(_currentValue);
    });
  }

  void _handleTapDown(TapDownDetails details) {
    _updateValueFromPosition(details.localPosition.dy);
  }

  void _updateValueFromPosition(double dy) {
    setState(() {
      // Convert tap position to value
      final double normalizedPosition = 1.0 - (dy / widget.height);
      _currentValue = widget.min + (normalizedPosition * (widget.max - widget.min));
      _currentValue = _currentValue.clamp(widget.min, widget.max);
      widget.onChanged(_currentValue);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Value display
        if (widget.showValue)
          SizedBox(
            height: 24,
            child: Text(
              _formatValue(_currentValue),
              style: TextStyle(
                color: PodColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

        // Fader track
        GestureDetector(
          onVerticalDragUpdate: _handleDragUpdate,
          onTapDown: _handleTapDown,
          child: CustomPaint(
            size: Size(widget.width, widget.height),
            painter: _FaderPainter(
              value: _currentValue,
              min: widget.min,
              max: widget.max,
              fillColor: widget.fillColor ?? PodColors.accent,
            ),
          ),
        ),

        // Label
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              widget.label!,
              style: TextStyle(
                color: PodColors.textLabel,
                fontSize: 11,
              ),
            ),
          ),
      ],
    );
  }

  String _formatValue(double value) {
    if (value == 0.0) {
      return '0dB';
    } else if (value > 0) {
      return '+${value.toStringAsFixed(1)}dB';
    } else {
      return '${value.toStringAsFixed(1)}dB';
    }
  }
}

class _FaderPainter extends CustomPainter {
  final double value;
  final double min;
  final double max;
  final Color fillColor;

  _FaderPainter({
    required this.value,
    required this.min,
    required this.max,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double trackWidth = size.width * 0.3;
    final double trackLeft = (size.width - trackWidth) / 2;
    final double trackRight = trackLeft + trackWidth;

    final double handleWidth = size.width * 0.8;
    final double handleHeight = 12.0;

    // Calculate center position (where value = 0)
    final double centerY = size.height / 2;

    // Calculate handle position based on value
    final double normalizedValue = (value - min) / (max - min);
    final double handleY = size.height - (normalizedValue * size.height);

    // Draw track background
    final trackPaint = Paint()
      ..color = PodColors.surfaceLight
      ..style = PaintingStyle.fill;

    final trackRect = RRect.fromLTRBR(
      trackLeft,
      0,
      trackRight,
      size.height,
      const Radius.circular(3),
    );
    canvas.drawRRect(trackRect, trackPaint);

    // Draw fill from center to handle
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final double fillTop = math.min(centerY, handleY);
    final double fillBottom = math.max(centerY, handleY);

    if ((handleY - centerY).abs() > 0.5) {
      final fillRect = RRect.fromLTRBR(
        trackLeft,
        fillTop,
        trackRight,
        fillBottom,
        const Radius.circular(3),
      );
      canvas.drawRRect(fillRect, fillPaint);
    }

    // Draw center line (0dB indicator)
    final centerLinePaint = Paint()
      ..color = PodColors.textSecondary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(0, centerY),
      Offset(size.width, centerY),
      centerLinePaint,
    );

    // Draw small tick marks at center
    final tickPaint = Paint()
      ..color = PodColors.textSecondary
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(0, centerY),
      Offset(trackLeft - 2, centerY),
      tickPaint,
    );
    canvas.drawLine(
      Offset(trackRight + 2, centerY),
      Offset(size.width, centerY),
      tickPaint,
    );

    // Draw handle
    final handlePaint = Paint()
      ..color = PodColors.knobHighlight
      ..style = PaintingStyle.fill;

    final handleRect = RRect.fromLTRBR(
      (size.width - handleWidth) / 2,
      handleY - handleHeight / 2,
      (size.width + handleWidth) / 2,
      handleY + handleHeight / 2,
      const Radius.circular(2),
    );
    canvas.drawRRect(handleRect, handlePaint);

    // Draw handle border for better visibility
    final handleBorderPaint = Paint()
      ..color = PodColors.textPrimary.withValues(alpha: 0.3)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(handleRect, handleBorderPaint);

    // Draw handle grip lines
    final gripPaint = Paint()
      ..color = PodColors.textSecondary
      ..strokeWidth = 1;

    final double gripSpacing = 3;
    final double gripLength = handleWidth * 0.5;
    final double gripLeft = (size.width - gripLength) / 2;
    final double gripRight = gripLeft + gripLength;

    for (int i = -1; i <= 1; i++) {
      canvas.drawLine(
        Offset(gripLeft, handleY + i * gripSpacing),
        Offset(gripRight, handleY + i * gripSpacing),
        gripPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_FaderPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.min != min ||
        oldDelegate.max != max ||
        oldDelegate.fillColor != fillColor;
  }
}
