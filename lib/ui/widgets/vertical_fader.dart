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
      final double baseSensitivity = (widget.max - widget.min) / height;
      final double adjustedSensitivity = baseSensitivity * widget.sensitivity;

      _currentValue -= details.delta.dy * adjustedSensitivity;
      _currentValue = _currentValue.clamp(widget.min, widget.max);

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
      final double normalizedPosition = 1.0 - (dy / height);
      _currentValue =
          widget.min + (normalizedPosition * (widget.max - widget.min));
      _currentValue = _currentValue.clamp(widget.min, widget.max);

      if (_currentValue.abs() <= widget.snapThreshold) {
        _currentValue = 0.0;
      }

      widget.onChanged(_currentValue);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, parentConstraints) {
        final totalHeight = parentConstraints.maxHeight;

        final valueHeight = widget.showValue
            ? (totalHeight * 0.12).clamp(14.0, 20.0)
            : 0.0;

        final valueFontSize = widget.showValue
            ? (valueHeight * 0.6).clamp(9.0, 12.0)
            : 0.0;

        final labelHeight = widget.label != null ? 20.0 : 0.0;

        final trackHeight = totalHeight - valueHeight - labelHeight;

        return Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            // Value display
            if (widget.showValue)
              SizedBox(
                height: valueHeight,
                child: Center(
                  child: Text(
                    _formatValue(_currentValue),
                    style: TextStyle(
                      color: PodColors.textPrimary,
                      fontSize: valueFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            // Fader track
            SizedBox(
              height: trackHeight,
              child: GestureDetector(
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
              ),
            ),

            // Label
            if (widget.label != null)
              SizedBox(
                height: labelHeight,
                child: Text(
                  widget.label!,
                  style: const TextStyle(
                    color: PodColors.textLabel,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        );
      },
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
    final double trackWidth = size.width * 0.5;
    final double trackLeft = (size.width - trackWidth) / 2;
    final double trackRight = trackLeft + trackWidth;

    final double handleWidth = size.width * 0.85;
    final double handleHeight = math.max(12.0, size.width * 0.35);

    final double centerY = size.height / 2;

    final double normalizedValue = (value - min) / (max - min);
    final double handleY = size.height - (normalizedValue * size.height);

    // Draw track outer shadow/inset
    final trackShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final trackShadowRect = RRect.fromLTRBR(
      trackLeft - 1,
      -1,
      trackRight + 1,
      size.height + 1,
      const Radius.circular(4),
    );
    canvas.drawRRect(trackShadowRect, trackShadowPaint);

    // Draw track background with gradient
    final trackGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        PodColors.surfaceLight.withValues(alpha: 0.6),
        PodColors.surfaceLight,
        PodColors.surfaceLight.withValues(alpha: 0.6),
      ],
    );

    final trackPaint = Paint()
      ..shader = trackGradient.createShader(
        Rect.fromLTRB(trackLeft, 0, trackRight, size.height),
      );

    final trackRect = RRect.fromLTRBR(
      trackLeft,
      0,
      trackRight,
      size.height,
      const Radius.circular(3),
    );
    canvas.drawRRect(trackRect, trackPaint);

    // Draw tick marks
    _drawTickMarks(canvas, size, trackLeft, trackRight);

    // Draw fill from center to handle with gradient
    final double fillTop = math.min(centerY, handleY);
    final double fillBottom = math.max(centerY, handleY);

    if ((handleY - centerY).abs() > 0.5) {
      final bool isBoost = handleY < centerY;

      final fillGradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isBoost
            ? [
                fillColor.withValues(alpha: 0.9),
                fillColor.withValues(alpha: 0.6),
              ]
            : [
                fillColor.withValues(alpha: 0.6),
                fillColor.withValues(alpha: 0.9),
              ],
      );

      final fillPaint = Paint()
        ..shader = fillGradient.createShader(
          Rect.fromLTRB(trackLeft, fillTop, trackRight, fillBottom),
        );

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
      ..color = PodColors.textPrimary.withValues(alpha: 0.4)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(trackLeft - 6, centerY),
      Offset(trackRight + 6, centerY),
      centerLinePaint,
    );

    // Draw small notch at center
    final notchPaint = Paint()
      ..color = PodColors.textLabel.withValues(alpha: 0.6)
      ..strokeWidth = 1.5;

    canvas.drawLine(
      Offset(trackRight + 6, centerY),
      Offset(trackRight + 10, centerY),
      notchPaint,
    );
    canvas.drawLine(
      Offset(trackLeft - 6, centerY),
      Offset(trackLeft - 10, centerY),
      notchPaint,
    );

    // Draw handle shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final shadowRect = RRect.fromLTRBR(
      (size.width - handleWidth) / 2,
      handleY - handleHeight / 2 + 2,
      (size.width + handleWidth) / 2,
      handleY + handleHeight / 2 + 2,
      Radius.circular(handleHeight * 0.25),
    );
    canvas.drawRRect(shadowRect, shadowPaint);

    // Draw handle with gradient
    final handleGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        PodColors.textPrimary,
        PodColors.textPrimary.withValues(alpha: 0.85),
        PodColors.textPrimary.withValues(alpha: 0.7),
      ],
    );

    final handlePaint = Paint()
      ..shader = handleGradient.createShader(
        Rect.fromLTRB(
          (size.width - handleWidth) / 2,
          handleY - handleHeight / 2,
          (size.width + handleWidth) / 2,
          handleY + handleHeight / 2,
        ),
      );

    final handleRect = RRect.fromLTRBR(
      (size.width - handleWidth) / 2,
      handleY - handleHeight / 2,
      (size.width + handleWidth) / 2,
      handleY + handleHeight / 2,
      Radius.circular(handleHeight * 0.25),
    );
    canvas.drawRRect(handleRect, handlePaint);

    // Draw handle highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final highlightRect = RRect.fromLTRBR(
      (size.width - handleWidth) / 2 + 2,
      handleY - handleHeight / 2 + 2,
      (size.width + handleWidth) / 2 - 2,
      handleY - handleHeight / 2 + (handleHeight * 0.3),
      Radius.circular(handleHeight * 0.2),
    );
    canvas.drawRRect(highlightRect, highlightPaint);

    // Draw handle grip lines
    final gripPaint = Paint()
      ..color = PodColors.background.withValues(alpha: 0.4)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    final gripSpacing = handleWidth * 0.25;
    final gripLeft = size.width / 2 - gripSpacing;
    final gripRight = size.width / 2 + gripSpacing;

    for (int i = 0; i < 3; i++) {
      final y = handleY - 3 + (i * 3.0);
      canvas.drawLine(
        Offset(gripLeft, y),
        Offset(gripRight, y),
        gripPaint,
      );
    }
  }

  void _drawTickMarks(Canvas canvas, Size size, double trackLeft, double trackRight) {
    final tickPaint = Paint()
      ..color = PodColors.textSecondary.withValues(alpha: 0.3)
      ..strokeWidth = 1.0;

    // Draw tick marks at 25%, 50%, 75% positions
    final positions = [0.25, 0.5, 0.75];

    for (final pos in positions) {
      final y = size.height * pos;
      canvas.drawLine(
        Offset(trackLeft - 3, y),
        Offset(trackLeft, y),
        tickPaint,
      );
      canvas.drawLine(
        Offset(trackRight, y),
        Offset(trackRight + 3, y),
        tickPaint,
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
