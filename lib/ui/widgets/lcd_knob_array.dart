import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:math' as math;
import 'dot_matrix_lcd.dart';

/// LCD-style parameter knob resembling POD XT/XT Pro LCD display.
///
/// Features:
/// - 3-line display: label, pixelated circular knob, value text
/// - Orange LCD aesthetic (#FF7A00 active, #CC5E00 dimmer)
/// - Active knob has orange background and inverted label colors
/// - Vertical drag to change values
/// - Scroll wheel control (up = increase, down = decrease)
/// - Supports 14-bit values (0-16383) for MSB/LSB parameters
/// - Distance-based movement (not velocity-based)
class LcdKnob extends StatefulWidget {
  final String label;
  final int value;
  final int minValue;
  final int maxValue;
  final ValueChanged<int> onValueChanged;
  final String Function(int) valueFormatter;
  final bool isActive; // Whether this knob is currently selected/active
  final VoidCallback? onTap; // Callback when knob is tapped
  final double width;
  final double height;

  const LcdKnob({
    super.key,
    required this.label,
    required this.value,
    required this.onValueChanged,
    this.minValue = 0,
    this.maxValue = 127,
    required this.valueFormatter,
    this.isActive = false,
    this.onTap,
    this.width = 100,
    this.height = 80,
  });

  @override
  State<LcdKnob> createState() => _LcdKnobState();
}

class _LcdKnobState extends State<LcdKnob> {
  double _accumulatedScrollDistance = 0.0;
  double _accumulatedDragDistance = 0.0;
  bool _needsReleaseToCrossBoundary = false;

  /// Reset accumulated distances when crossing between note division mode and ms/Hz mode
  void _resetAccumulationOnModeChange(int oldValue, int newValue) {
    // Detect mode change: crossing the boundary between negative (note division) and positive (ms/Hz)
    final oldIsNoteMode = oldValue < 0;
    final newIsNoteMode = newValue < 0;

    if (oldIsNoteMode != newIsNoteMode) {
      _accumulatedScrollDistance = 0.0;
      _accumulatedDragDistance = 0.0;
    }
  }

  /// Handle pointer release to allow crossing boundary after release
  void _onPointerUp(PointerUpEvent event) {
    _needsReleaseToCrossBoundary = false;
  }

  void _handleScroll(PointerScrollEvent event) {
    // Activate this knob when scrolling
    if (!widget.isActive && widget.onTap != null) {
      widget.onTap!();
    }

    // Negate delta so scroll UP (negative) increases value, scroll DOWN (positive) decreases
    final delta = -event.scrollDelta.dy;
    final range = widget.maxValue - widget.minValue;

    // SIMPLE 2-POSITION SWITCH: just check direction
    if (range <= 1) {
      final newValue = delta > 0 ? widget.maxValue : widget.minValue; // scroll up = max (FAST), down = min (SLOW)
      if (newValue != widget.value) {
        widget.onValueChanged(newValue);
      }
      return;
    }

    // DISTANCE-BASED movement: accumulate scroll distance, only step when threshold reached
    _accumulatedScrollDistance += delta;

    double threshold;

    if (widget.value < 0) {
      // Note divisions (-13 to -1), a small range of negative values
      // Higher threshold = more pixels needed per step = very deliberate changes
      threshold = 400.0;
    } else if (range <= 15) {
      // Small-range knobs (e.g., Heads, Bits)
      // Higher threshold = more distance needed per step
      threshold = 120.0;
    } else if (range > 10000) {
      // Large-range knobs (delay time MS/Hz mode: 0-16383)
      // Lower threshold = less pixels needed = smoother, faster scrolling
      threshold = 15.0;
    } else {
      // Default for standard (0-127) params
      threshold = 50.0;
    }

    // Calculate how many steps we've accumulated
    final steps = (_accumulatedScrollDistance / threshold).truncate();

    if (steps != 0) {
      final newValue = (widget.value + steps).clamp(widget.minValue, widget.maxValue);

      // Check if trying to cross boundary between note mode and ms/Hz mode
      // Boundary is between -1 (WHOLE note) and 0 (20ms)
      final crossingToMs = (widget.value == -1 && newValue >= 0);
      final crossingToNote = (widget.value == 0 && newValue < 0);

      if ((crossingToMs || crossingToNote) && _needsReleaseToCrossBoundary) {
        // Block crossing - user must release and start new gesture
        _accumulatedScrollDistance = 0.0;
        return;
      }

      if (newValue != widget.value) {
        // Reset accumulation if crossing between note division and ms/Hz mode
        _resetAccumulationOnModeChange(widget.value, newValue);

        widget.onValueChanged(newValue);

        // If we just reached the boundary, require release before crossing
        if (newValue == -1 || newValue == 0) {
          _needsReleaseToCrossBoundary = true;
        }

        // Subtract the distance we "consumed" for these steps
        _accumulatedScrollDistance -= steps * threshold;
      }
    }
  }

  void _handleDrag(DragUpdateDetails details) {
    // Activate this knob when dragging
    if (!widget.isActive && widget.onTap != null) {
      widget.onTap!();
    }

    final range = widget.maxValue - widget.minValue;

    // SIMPLE 2-POSITION SWITCH: just check direction
    if (range <= 1) {
      final newValue = details.delta.dy < 0 ? widget.maxValue : widget.minValue; // drag up = max (FAST), down = min (SLOW)
      if (newValue != widget.value) {
        widget.onValueChanged(newValue);
      }
      return;
    }

    // DISTANCE-BASED movement: accumulate drag distance, only step when threshold reached
    _accumulatedDragDistance -= details.delta.dy;  // Negative because drag up = increase

    double threshold;

    if (widget.value < 0) {
      // Note divisions (-13 to -1), a small range of negative values
      // Higher threshold = more pixels needed per step = very deliberate changes
      threshold = 15.0;
    } else if (range <= 15) {
      // Small-range knobs (e.g., Heads, Bits)
      // Higher threshold = more distance needed per step
      threshold = 25.0;
    } else if (range > 10000) {
      // Large-range knobs (delay time MS/Hz mode: 0-16383)
      // Lower threshold = less pixels needed = smoother, faster dragging
      threshold = 0.5;
    } else {
      // Default for standard (0-127) params
      threshold = 2.5;
    }

    // Calculate how many steps we've accumulated
    final steps = (_accumulatedDragDistance / threshold).truncate();

    if (steps != 0) {
      final newValue = (widget.value + steps).clamp(widget.minValue, widget.maxValue);

      // Check if trying to cross boundary between note mode and ms/Hz mode
      // Boundary is between -1 (WHOLE note) and 0 (20ms)
      final crossingToMs = (widget.value == -1 && newValue >= 0);
      final crossingToNote = (widget.value == 0 && newValue < 0);

      if ((crossingToMs || crossingToNote) && _needsReleaseToCrossBoundary) {
        // Block crossing - user must release and start new gesture
        _accumulatedDragDistance = 0.0;
        return;
      }

      if (newValue != widget.value) {
        // Reset accumulation if crossing between note division and ms/Hz mode
        _resetAccumulationOnModeChange(widget.value, newValue);

        widget.onValueChanged(newValue);

        // If we just reached the boundary, require release before crossing
        if (newValue == -1 || newValue == 0) {
          _needsReleaseToCrossBoundary = true;
        }

        // Subtract the distance we "consumed" for these steps
        _accumulatedDragDistance -= steps * threshold;
      }
    }
  }

  void _onDragEnd(DragEndDetails details) {
    _needsReleaseToCrossBoundary = false;
  }

  @override
  Widget build(BuildContext context) {
    final normalizedValue = (widget.value - widget.minValue) / (widget.maxValue - widget.minValue);

    return Listener(
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) {
          _handleScroll(event);
        }
      },
      onPointerUp: _onPointerUp,
      child: GestureDetector(
        onPanUpdate: _handleDrag,
        onPanEnd: _onDragEnd,
        onTap: widget.onTap,
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: [
              // Label (inverted when active) - pushed to top
              _DotText(
                widget.label,
                size: 15,
                color: widget.isActive ? Colors.black : const Color(0xFFFF7A00),
                backgroundColor: widget.isActive
                    ? const Color(0xFFFF7A00)
                    : Colors.transparent,
                isBold: true,
              ),
              // LCD knob visualization (pixelated circle with dash) - centered
              _LcdKnobIndicator(
                value: normalizedValue,
                size: 34,
                isActive: widget.isActive,
              ),
              // Value display - pushed to bottom
              _DotText(
                widget.valueFormatter(widget.value),
                size: 14,
                color: const Color(0xFFFF7A00),
                isBold: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Renders pixelated LCD-style knob indicator (circular knob with dash).
///
/// Draws an orange pixelated circle with a dark-orange dash indicator
/// showing the current value position, matching the POD XT LCD display.
class _LcdKnobIndicator extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final double size;
  final bool isActive;

  const _LcdKnobIndicator({
    required this.value,
    required this.size,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _LcdKnobPainter(
        value: value,
        color: isActive
            ? const Color(0xFFFF7A00)
            : const Color(0xFFCC5E00), // Dimmer when inactive
      ),
    );
  }
}

/// Painter for LCD knob - draws filled pixelated circle with black dash.
///
/// Creates an authentic POD XT LCD knob appearance with:
/// - Filled pixelated circle (orange)
/// - Black dash indicator showing value position
/// - 270° rotation range (135° to 405° / -135° to 135°)
class _LcdKnobPainter extends CustomPainter {
  final double value;
  final Color color;

  _LcdKnobPainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final circlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // POD XT LCD knob: 12x12 pixel grid pattern
    // 1 = filled pixel, 0 = empty
    // This creates a filled circle with proper LCD pixelated appearance
    const pattern = [
      [0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0], // Row 0
      [0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0], // Row 1
      [0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0], // Row 2
      [0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0], // Row 3
      [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1], // Row 4
      [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1], // Row 5
      [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1], // Row 6
      [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1], // Row 7
      [0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0], // Row 8
      [0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0], // Row 9
      [0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0], // Row 10
      [0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0], // Row 11
    ];

    const gridSize = 12;
    const blockSize = 2.5; // 3x3px blocks
    const gap = 0.5; // 1px gap between blocks
    const pixelSize = blockSize + gap; // Total cell size = 4px
    final totalSize = gridSize * pixelSize;
    final startX = center.dx - (totalSize / 2);
    final startY = center.dy - (totalSize / 2);

    // Draw the pattern
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        if (pattern[row][col] == 1) {
          final x = startX + (col * pixelSize);
          final y = startY + (row * pixelSize);

          canvas.drawRect(
            Rect.fromLTWH(x, y, blockSize, blockSize),
            circlePaint,
          );
        }
      }
    }

    // Draw black dash indicator showing value position
    // 270° sweep: 135° to 405° (0.0 = bottom-left, 0.5 = noon/top, 1.0 = bottom-right)
    const startAngle = 135.0 * math.pi / 180.0; // Bottom-left (7:30)
    const sweepRange = 270.0 * math.pi / 180.0; // 270° sweep
    final currentAngle = startAngle + (value * sweepRange);

    final dashPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    // Draw dash from center outward using same grid pattern
    final knobRadius = totalSize / 2;
    final dashLength = knobRadius * 0.7;
    final dashStartRadius = knobRadius * 0.15;

    for (double r = dashStartRadius; r <= dashLength; r += blockSize) {
      final x = center.dx + math.cos(currentAngle) * r;
      final y = center.dy + math.sin(currentAngle) * r;

      // Draw pixelated dash blocks (3x3px like the circle blocks)
      canvas.drawRect(
        Rect.fromLTWH(
          x - blockSize / 2,
          y - blockSize / 2,
          blockSize,
          blockSize,
        ),
        dashPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_LcdKnobPainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.color != color;
  }
}

/// Dot-matrix text matching DotMatrixLCD style.
///
/// Uses the Doto font family to render text with the authentic
/// dot-matrix look. Supports optional background color for
/// inverted display (active knob labels).
class _DotText extends StatelessWidget {
  final String text;
  final double size;
  final Color color;
  final Color? backgroundColor;
  final bool isBold;

  const _DotText(
    this.text, {
    required this.size,
    required this.color,
    this.backgroundColor,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: backgroundColor != null
          ? const EdgeInsets.symmetric(horizontal: 6, vertical: 3)
          : EdgeInsets.zero,
      color: backgroundColor,
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Doto',
          fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
          fontSize: size,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Array of LCD knobs arranged horizontally in a DotMatrixLCD container.
///
/// Features:
/// - Active knob tracking (one knob active at a time)
/// - Automatic spacing and layout
/// - Wrapped in POD-style LCD aesthetic
///
/// Example:
/// ```dart
/// LcdKnobArray(
///   knobs: [
///     LcdKnobConfig(
///       label: 'DRIVE',
///       value: 50,
///       maxValue: 127,
///       onValueChanged: (v) => setState(() => drive = v),
///       valueFormatter: (v) => v.toString(),
///     ),
///   ],
/// )
/// ```
class LcdKnobArray extends StatefulWidget {
  final List<LcdKnobConfig> knobs;
  final EdgeInsets padding;

  const LcdKnobArray({
    super.key,
    required this.knobs,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
  });

  @override
  State<LcdKnobArray> createState() => _LcdKnobArrayState();
}

class _LcdKnobArrayState extends State<LcdKnobArray> {
  int _activeIndex = 0;

  @override
  Widget build(BuildContext context) {
    return DotMatrixLCD(
      padding: widget.padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(widget.knobs.length, (index) {
          final config = widget.knobs[index];
          return LcdKnob(
            label: config.label,
            value: config.value,
            minValue: config.minValue,
            maxValue: config.maxValue,
            onValueChanged: config.onValueChanged,
            valueFormatter: config.valueFormatter,
            isActive: index == _activeIndex,
            onTap: () => setState(() => _activeIndex = index),
            width: 100,
            height: 80,
          );
        }),
      ),
    );
  }
}

/// Configuration for a single LCD knob in an LcdKnobArray.
///
/// Encapsulates all the properties needed to render and control
/// a parameter knob. Supports both 7-bit (0-127) and 14-bit
/// (0-16383) values via minValue/maxValue.
///
/// Example:
/// ```dart
/// LcdKnobConfig(
///   label: 'DEPTH',
///   value: 8192,
///   minValue: 0,
///   maxValue: 16383,  // 14-bit for MSB/LSB params
///   onValueChanged: (v) => pod.setModulationDepth(v),
///   valueFormatter: (v) => '${(v / 163.83).round()}%',
/// )
/// ```
class LcdKnobConfig {
  final String label;
  final int value;
  final int minValue;
  final int maxValue;
  final ValueChanged<int> onValueChanged;
  final String Function(int) valueFormatter;

  const LcdKnobConfig({
    required this.label,
    required this.value,
    required this.onValueChanged,
    this.minValue = 0,
    this.maxValue = 127,
    required this.valueFormatter,
  });
}
