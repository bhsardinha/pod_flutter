import 'package:flutter/material.dart';
import '../theme/pod_theme.dart';
import 'dart:math' as math;

/// Tuner modal with 3-segment visual tuner display
///
/// Features:
/// - Red arrow pointing up (note is flat/below pitch)
/// - Green inverted triangle (note is in tune)
/// - Red arrow pointing down (note is sharp/above pitch)
/// - Note name display (C, C#, D, etc.)
/// - Frequency display in Hz
///
/// Demo mode: Tap the tuner display to cycle through states
class TunerModal extends StatefulWidget {
  const TunerModal({super.key});

  @override
  State<TunerModal> createState() => _TunerModalState();
}

class _TunerModalState extends State<TunerModal> {
  // Demo mode state
  int _demoStateIndex = 0;
  final List<_TunerState> _demoStates = [
    _TunerState(note: 'A', frequency: 440.0, cents: 0), // In tune
    _TunerState(note: 'A', frequency: 437.5, cents: -20), // Flat
    _TunerState(note: 'A', frequency: 442.5, cents: 15), // Sharp
    _TunerState(note: 'E', frequency: 329.0, cents: -10), // Flat
    _TunerState(note: 'E', frequency: 329.6, cents: 0), // In tune
    _TunerState(note: 'G', frequency: 392.5, cents: 5), // Slight sharp
    _TunerState(note: 'C', frequency: 261.6, cents: 0), // In tune
    _TunerState(note: 'D', frequency: 293.0, cents: -25), // Very flat
    _TunerState(note: 'B', frequency: 495.0, cents: 10), // Sharp
  ];

  _TunerState get _currentState => _demoStates[_demoStateIndex];

  void _cycleDemoState() {
    setState(() {
      _demoStateIndex = (_demoStateIndex + 1) % _demoStates.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.8,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          const Text(
            'TUNER',
            style: TextStyle(
              color: PodColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Demo Mode - Tap to cycle states',
            style: TextStyle(
              color: PodColors.textSecondary.withValues(alpha: 0.7),
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 32),

          // Note name display
          Text(
            _currentState.note,
            style: const TextStyle(
              color: PodColors.textPrimary,
              fontSize: 72,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 16),

          // Frequency display
          Text(
            '${_currentState.frequency.toStringAsFixed(1)} Hz',
            style: TextStyle(
              color: PodColors.textSecondary.withValues(alpha: 0.9),
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 32),

          // 3-segment tuner display
          GestureDetector(
            onTap: _cycleDemoState,
            child: _build3SegmentTuner(_currentState.cents),
          ),
          const SizedBox(height: 24),

          // Cents indicator (numerical)
          Text(
            _currentState.cents == 0
                ? 'IN TUNE'
                : '${_currentState.cents > 0 ? '+' : ''}${_currentState.cents} cents',
            style: TextStyle(
              color: _getTunerColor(_currentState.cents),
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _build3SegmentTuner(int cents) {
    final isFlat = cents < -5;
    final isSharp = cents > 5;
    final isInTune = !isFlat && !isSharp;

    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Left segment - Flat (arrow pointing up)
          Expanded(
            child: _buildSegment(
              isActive: isFlat,
              child: Icon(
                Icons.arrow_drop_up,
                size: 80,
                color: isFlat
                    ? Colors.red.shade600
                    : PodColors.textSecondary.withValues(alpha: 0.2),
              ),
            ),
          ),
          const SizedBox(width: 20),

          // Center segment - In Tune (inverted triangle)
          Expanded(
            child: _buildSegment(
              isActive: isInTune,
              child: Transform.rotate(
                angle: math.pi,
                child: Icon(
                  Icons.arrow_drop_up,
                  size: 80,
                  color: isInTune
                      ? PodColors.buttonOnGreen
                      : PodColors.textSecondary.withValues(alpha: 0.2),
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),

          // Right segment - Sharp (arrow pointing down)
          Expanded(
            child: _buildSegment(
              isActive: isSharp,
              child: Icon(
                Icons.arrow_drop_down,
                size: 80,
                color: isSharp
                    ? Colors.red.shade600
                    : PodColors.textSecondary.withValues(alpha: 0.2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegment({required bool isActive, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: isActive
            ? PodColors.surfaceLight
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? PodColors.accent.withValues(alpha: 0.3)
              : PodColors.surfaceLight.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Center(child: child),
    );
  }

  Color _getTunerColor(int cents) {
    if (cents.abs() <= 5) {
      return PodColors.buttonOnGreen;
    } else {
      return Colors.red.shade600;
    }
  }
}

/// Tuner state representation
class _TunerState {
  final String note;
  final double frequency;
  final int cents; // -50 to +50, 0 = in tune

  _TunerState({
    required this.note,
    required this.frequency,
    required this.cents,
  });
}
