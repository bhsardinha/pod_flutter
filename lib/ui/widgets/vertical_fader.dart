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
  final double? height;

  /// Whether to show the value display
  final bool showValue;

  /// Custom fill color (defaults to accent color)
  final Color? fillColor;

  /// Snap threshold in dB - values within this range snap to zero
  final double snapThreshold;

  /// Drag sensitivity multiplier (lower = more precise, default 0.3)
  final double sensitivity;

  const VerticalFader({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = -12.0,
    this.max = 12.0,
    this.label,
    // Slightly larger defaults for better touch targets
    this.width = 40.0,
    this.height,
    this.showValue = true,
    this.fillColor,
    this.snapThreshold = 0.8,
    this.sensitivity = 0.3,
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

  void _handleDragUpdate(DragUpdateDetails details, double height) {
    setState(() {
      // Convert vertical drag to value change
      // Negative dy means dragging up (increase value)
      // Apply sensitivity multiplier for more precise control
      final double baseSensitivity = (widget.max - widget.min) / height;
      final double adjustedSensitivity = baseSensitivity * widget.sensitivity;

      // Invert mapping so upward drag increases the fader value
      _currentValue += details.delta.dy * adjustedSensitivity;
      _currentValue = _currentValue.clamp(widget.min, widget.max);

      // Snap to zero if within threshold
      if (_currentValue.abs() <= widget.snapThreshold) {
        _currentValue = 0.0;
      }

      widget.onChanged(_currentValue);
    });
  }

  void _handleTapDown(TapDownDetails details, double height) {
    _updateValueFromPosition(details.localPosition.dy, height);
  }

  void _updateValueFromPosition(double dy, double height) {
    setState(() {
      // Convert tap position to value
      final double normalizedPosition = 1.0 - (dy / height);
      _currentValue =
          widget.min + (normalizedPosition * (widget.max - widget.min));
      _currentValue = _currentValue.clamp(widget.min, widget.max);

      // Snap to zero if within threshold
      if (_currentValue.abs() <= widget.snapThreshold) {
        _currentValue = 0.0;
      }

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

        // Fader track - adapt to available height when `height` is null
        LayoutBuilder(
          builder: (ctx, constraints) {
            final availableHeight = widget.height ?? constraints.maxHeight;
            final trackHeight = availableHeight.isFinite && availableHeight > 0
                ? availableHeight
                : 160.0;
            return GestureDetector(
              onVerticalDragUpdate: (d) => _handleDragUpdate(d, trackHeight),
              onTapDown: (td) => _handleTapDown(td, trackHeight),
              child: CustomPaint(
                size: Size(widget.width, trackHeight),
                painter: _FaderPainter(
                  value: _currentValue,
                  min: widget.min,
                  max: widget.max,
                  fillColor: widget.fillColor ?? PodColors.accent,
                ),
              ),
            );
          },
        ),

        // Label
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              widget.label!,
              style: TextStyle(color: PodColors.textLabel, fontSize: 11),
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
    // Make track much wider (thicker) for improved visuals and touch targets
    final double trackWidth = size.width * 0.72;
    final double trackLeft = (size.width - trackWidth) / 2;
    final double trackRight = trackLeft + trackWidth;

    // Larger handle to match the thicker track
    final double handleWidth = size.width * 0.98;
    final double handleHeight = math.max(14.0, size.width * 0.40);

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
      const Radius.circular(2),
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
        const Radius.circular(2),
      );
      canvas.drawRRect(fillRect, fillPaint);
    }

    // Draw center line (0dB indicator) - subtle
    final centerLinePaint = Paint()
      ..color = PodColors.textSecondary.withValues(alpha: 0.5)
      ..strokeWidth = 1.5;

    canvas.drawLine(
      Offset(trackLeft - 4, centerY),
      Offset(trackRight + 4, centerY),
      centerLinePaint,
    );

    // Draw handle - simple rectangle
    final handlePaint = Paint()
      ..color = PodColors.textPrimary
      ..style = PaintingStyle.fill;

    final handleRect = RRect.fromLTRBR(
      (size.width - handleWidth) / 2,
      handleY - handleHeight / 2,
      (size.width + handleWidth) / 2,
      handleY + handleHeight / 2,
      Radius.circular(handleHeight * 0.25),
    );
    canvas.drawRRect(handleRect, handlePaint);
  }

  @override
  bool shouldRepaint(_FaderPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.min != min ||
        oldDelegate.max != max ||
        oldDelegate.fillColor != fillColor;
  }
}
