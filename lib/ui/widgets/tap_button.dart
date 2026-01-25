import 'package:flutter/material.dart';
import 'dart:async';

/// A TAP tempo button that blinks at the current BPM
///
/// Features:
/// - Blinks orange at the current tempo (when tempo-synced)
/// - Shows BPM value (when tempo-synced)
/// - Hides BPM and stops blinking when delay is in ms mode
/// - Tap to send tap tempo message
/// - Swipe up/down to adjust tempo
/// - Visual feedback with glow effect
class TapButton extends StatefulWidget {
  /// Current BPM (beats per minute)
  final int bpm;

  /// Whether delay is in tempo sync mode (shows BPM and blinks)
  final bool isTempoSynced;

  /// Whether scrolling to change tempo is enabled
  final bool enableScrolling;

  /// Callback when button is tapped
  final VoidCallback onTap;

  /// Callback when tempo is changed via swipe
  final Function(int newBpm) onTempoChanged;

  /// Optional font size for the TAP label
  final double? labelFontSize;

  /// Optional font size for the BPM number
  final double? bpmFontSize;

  /// Whether to use dynamic font sizing (FittedBox)
  final bool useDynamicSize;

  const TapButton({
    super.key,
    required this.bpm,
    required this.isTempoSynced,
    required this.enableScrolling,
    required this.onTap,
    required this.onTempoChanged,
    this.labelFontSize,
    this.bpmFontSize,
    this.useDynamicSize = false,
  });

  @override
  State<TapButton> createState() => _TapButtonState();
}

class _TapButtonState extends State<TapButton> {
  Timer? _beatTimer;
  Timer? _flashOffTimer;
  bool _isBlinkOn = false;
  double _dragAccumulator = 0.0;
  int? _dragStartBpm;

  @override
  void initState() {
    super.initState();
    _startBlinking();
  }

  @override
  void didUpdateWidget(TapButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bpm != widget.bpm || oldWidget.isTempoSynced != widget.isTempoSynced) {
      _startBlinking();
    }
  }

  @override
  void dispose() {
    _beatTimer?.cancel();
    _flashOffTimer?.cancel();
    super.dispose();
  }

  void _startBlinking() {
    _beatTimer?.cancel();
    _flashOffTimer?.cancel();

    // Stop blinking if not tempo-synced or invalid BPM
    if (!widget.isTempoSynced || widget.bpm <= 0) {
      if (mounted) {
        setState(() => _isBlinkOn = false);
      }
      return;
    }

    // Calculate beat interval from BPM (60000ms per minute / BPM)
    final beatIntervalMs = (60000 / widget.bpm).round();

    // Flash immediately on first beat
    _flashBeat();

    // Set up timer to flash on each beat
    _beatTimer = Timer.periodic(Duration(milliseconds: beatIntervalMs), (timer) {
      if (mounted) {
        _flashBeat();
      }
    });
  }

  void _flashBeat() {
    _flashOffTimer?.cancel();

    if (mounted) {
      setState(() => _isBlinkOn = true);
    }

    // Turn off after flash duration
    _flashOffTimer = Timer(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() => _isBlinkOn = false);
      }
    });
  }

  void _handleVerticalDragStart(DragStartDetails details) {
    _dragStartBpm = widget.bpm;
    _dragAccumulator = 0.0;
  }

  void _handleVerticalDragUpdate(DragUpdateDetails details) {
    if (_dragStartBpm == null) return;

    // Accumulate drag delta (negative = up = increase, positive = down = decrease)
    _dragAccumulator -= details.delta.dy;

    // Convert accumulated pixels to BPM change (10 pixels = 1 BPM)
    final bpmDelta = (_dragAccumulator / 10.0).round();

    if (bpmDelta != 0) {
      final newBpm = (_dragStartBpm! + bpmDelta).clamp(30, 240);
      widget.onTempoChanged(newBpm);
      _dragAccumulator = 0.0; // Reset accumulator after applying change
      _dragStartBpm = newBpm; // Update reference for next delta
    }
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
    _dragStartBpm = null;
    _dragAccumulator = 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onVerticalDragStart: widget.enableScrolling ? _handleVerticalDragStart : null,
      onVerticalDragUpdate: widget.enableScrolling ? _handleVerticalDragUpdate : null,
      onVerticalDragEnd: widget.enableScrolling ? _handleVerticalDragEnd : null,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          // Pitch black hole background
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF000000), // Pure black
              Color(0xFF000000), // Pure black
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          // Inner shadows to create hole/cavity effect
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.9),
              offset: const Offset(4, 4),
              blurRadius: 2,
              spreadRadius: -3,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              offset: const Offset(-4, -4),
              blurRadius: 2,
              spreadRadius: -6,
            ),
          ],
        ),
        child: Container(
          margin: const EdgeInsets.all(0.5),
          decoration: BoxDecoration(
            // Deep glossy black gradient
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF0F0F0F), // Very dark gray
                Color(0xFF0A0A0A), // Slightly darker
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              // Glossy bevels (same as EffectButton)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      const Color(0xFF000000),
                      Colors.black.withValues(alpha: 0.1),
                      const Color(0xFF666666).withValues(alpha: 0.08),
                      Colors.transparent,
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.04, 0.08, 0.99, 1.0],
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [
                      const Color(0xFF000000),
                      Colors.black.withValues(alpha: 0.1),
                      const Color(0xFF666666).withValues(alpha: 0.10),
                      Colors.transparent,
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.04, 0.08, 0.99, 1.0],
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF000000),
                      Colors.black.withValues(alpha: 0.1),
                      const Color(0xFF666666).withValues(alpha: 0.1),
                      Colors.transparent,
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.05, 0.18, 0.99, 1.0],
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      const Color(0xFF000000),
                      Colors.black.withValues(alpha: 0.1),
                      const Color(0xFF666666).withValues(alpha: 0.08),
                      Colors.transparent,
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.05, 0.18, 0.99, 1.0],
                  ),
                ),
              ),
              // Content
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.useDynamicSize)
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'TAP',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _isBlinkOn
                                  ? const Color(0xFFFF7A00)
                                  : const Color(0xFF6A6A6A),
                              fontSize: widget.labelFontSize ?? 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                              shadows: _isBlinkOn
                                  ? [
                                      Shadow(
                                        color: const Color(0xFFFF7A00)
                                            .withValues(alpha: 0.15),
                                        blurRadius: 4,
                                      ),
                                      Shadow(
                                        color: const Color(0xFFFF7A00)
                                            .withValues(alpha: 0.3),
                                        blurRadius: 8,
                                      ),
                                      Shadow(
                                        color: const Color(0xFFFF7A00)
                                            .withValues(alpha: 0.15),
                                        blurRadius: 4,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        )
                      else
                        Text(
                          'TAP',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _isBlinkOn
                                ? const Color(0xFFFF7A00)
                                : const Color(0xFF6A6A6A),
                            fontSize: widget.labelFontSize ?? 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                            shadows: _isBlinkOn
                                ? [
                                    Shadow(
                                      color: const Color(0xFFFF7A00)
                                          .withValues(alpha: 0.15),
                                      blurRadius: 4,
                                    ),
                                    Shadow(
                                      color: const Color(0xFFFF7A00)
                                          .withValues(alpha: 0.3),
                                      blurRadius: 8,
                                    ),
                                    Shadow(
                                      color: const Color(0xFFFF7A00)
                                          .withValues(alpha: 0.15),
                                      blurRadius: 4,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      if (widget.isTempoSynced) ...[
                        const SizedBox(height: 2),
                        if (widget.useDynamicSize)
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '${widget.bpm}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _isBlinkOn
                                    ? const Color(0xFFFF7A00)
                                    : const Color(0xFF6A6A6A),
                                fontSize: widget.bpmFontSize ?? 9,
                                fontWeight: FontWeight.w400,
                                shadows: _isBlinkOn
                                    ? [
                                        Shadow(
                                          color: const Color(0xFFFF7A00)
                                              .withValues(alpha: 0.3),
                                          blurRadius: 3,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          )
                        else
                          Text(
                            '${widget.bpm}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _isBlinkOn
                                  ? const Color(0xFFFF7A00)
                                  : const Color(0xFF6A6A6A),
                              fontSize: widget.bpmFontSize ?? 9,
                              fontWeight: FontWeight.w400,
                              shadows: _isBlinkOn
                                  ? [
                                      Shadow(
                                        color: const Color(0xFFFF7A00)
                                            .withValues(alpha: 0.3),
                                        blurRadius: 3,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
