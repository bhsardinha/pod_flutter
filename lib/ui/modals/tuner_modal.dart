import 'package:flutter/material.dart';
import 'dart:async';
import '../theme/pod_theme.dart';
import '../../services/pod_controller.dart';
import '../../protocol/sysex.dart';

/// Tuner modal with 3-segment visual tuner display
///
/// Features:
/// - Red arrow pointing up (note is flat/below pitch)
/// - Green inverted triangle (note is in tune)
/// - Red arrow pointing down (note is sharp/above pitch)
/// - Note name display (C, C#, D, etc.)
/// - Frequency display in Hz (calculated from MIDI note)
/// - Real-time pitch detection from POD XT Pro via MIDI
class TunerModal extends StatefulWidget {
  final PodController podController;
  final bool isConnected;

  const TunerModal({
    super.key,
    required this.podController,
    required this.isConnected,
  });

  @override
  State<TunerModal> createState() => _TunerModalState();
}

class _TunerModalState extends State<TunerModal> {
  Timer? _tunerPollTimer;
  _TunerState _currentState = _TunerState.noSignal();
  StreamSubscription<TunerData>? _tunerSubscription;
  StreamSubscription? _ccSubscription;
  StreamSubscription? _pcSubscription;

  @override
  void initState() {
    super.initState();
    if (widget.isConnected) {
      _startTuner();
      _listenForMidiSignals();
    }
  }

  @override
  void dispose() {
    _stopTuner();
    _ccSubscription?.cancel();
    _pcSubscription?.cancel();
    super.dispose();
  }

  /// Listen for any MIDI signal (CC, PC) and close modal
  /// User may exit tuner mode via hardware (foot controller, POD buttons)
  void _listenForMidiSignals() {
    // Close modal on any parameter change (CC messages)
    _ccSubscription = widget.podController.onParameterChanged.listen((_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });

    // Close modal on any program change
    _pcSubscription = widget.podController.onProgramChanged.listen((_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  void _startTuner() {
    // Enable tuner mode on POD (CC 69 = 127)
    widget.podController.setTunerEnabled(true);

    // Subscribe to tuner data from POD controller
    _tunerSubscription = widget.podController.onTunerData.listen((data) {
      setState(() {
        _currentState = _TunerState.fromTunerData(data);
      });
    });

    // Start polling tuner data (1 Hz rate)
    _tunerPollTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (widget.isConnected) {
        widget.podController.requestTunerData();
      }
    });

    // Request initial tuner data
    widget.podController.requestTunerData();
  }

  void _stopTuner() {
    _tunerPollTimer?.cancel();
    _tunerSubscription?.cancel();

    // Disable tuner mode on POD (CC 69 = 0)
    if (widget.isConnected) {
      widget.podController.setTunerEnabled(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      width: MediaQuery.of(context).size.width * 0.75,
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.8, // Limit to 80% of screen height
      ),
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            const Text(
              'TUNER',
              style: TextStyle(
                color: PodColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.isConnected ? 'Play a note to tune' : 'Not connected',
              style: TextStyle(
                color: PodColors.textSecondary.withValues(alpha: 0.7),
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 20),

            // Note name and octave (horizontal)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  _currentState.note,
                  style: const TextStyle(
                    color: PodColors.textPrimary,
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                if (_currentState.octave != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    '${_currentState.octave}',
                    style: TextStyle(
                      color: PodColors.textSecondary.withValues(alpha: 0.7),
                      fontSize: 28,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            // Frequency display
            if (_currentState.frequency != null)
              Text(
                '${_currentState.frequency!.toStringAsFixed(1)} Hz',
                style: TextStyle(
                  color: PodColors.textSecondary.withValues(alpha: 0.9),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            const SizedBox(height: 20),

            // 3-segment tuner display
            _build3SegmentTuner(_currentState.cents),
            const SizedBox(height: 16),

            // Cents indicator (numerical)
            Text(
              _currentState.hasSignal
                  ? (_currentState.cents == 0
                      ? 'IN TUNE'
                      : '${_currentState.cents > 0 ? '+' : ''}${_currentState.cents} cents')
                  : 'NO SIGNAL',
              style: TextStyle(
                color: _currentState.hasSignal
                    ? _getTunerColor(_currentState.cents)
                    : PodColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _build3SegmentTuner(int cents) {
    final isFlat = cents < -2;
    final isSharp = cents > 2;
    final isInTune = cents >= -2 && cents <= 2;

    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Left segment - Flat (arrow pointing up)
          Expanded(
            child: _buildSegment(
              isActive: isFlat,
              child: Icon(
                Icons.arrow_drop_up,
                size: 60,
                color: isFlat
                    ? Colors.red.shade600
                    : PodColors.textSecondary.withValues(alpha: 0.2),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Center segment - In Tune (filled circle)
          Expanded(
            child: _buildSegment(
              isActive: isInTune,
              child: Icon(
                Icons.circle,
                size: 48,
                color: isInTune
                    ? PodColors.buttonOnGreen
                    : PodColors.textSecondary.withValues(alpha: 0.2),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Right segment - Sharp (arrow pointing down)
          Expanded(
            child: _buildSegment(
              isActive: isSharp,
              child: Icon(
                Icons.arrow_drop_down,
                size: 60,
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
    if (cents >= -2 && cents <= 2) {
      return PodColors.buttonOnGreen;
    } else {
      return Colors.red.shade600;
    }
  }
}

/// Tuner state representation
class _TunerState {
  final String note;
  final int? octave;
  final double? frequency;
  final int cents; // -50 to +50, 0 = in tune
  final bool hasSignal;

  _TunerState({
    required this.note,
    this.octave,
    this.frequency,
    required this.cents,
    this.hasSignal = true,
  });

  /// Create a no-signal state
  factory _TunerState.noSignal() {
    return _TunerState(
      note: '—',
      octave: null,
      frequency: null,
      cents: 0,
      hasSignal: false,
    );
  }

  /// Create from tuner data received from POD
  factory _TunerState.fromTunerData(TunerData data) {
    if (!data.hasSignal) {
      return _TunerState.noSignal();
    }

    return _TunerState(
      note: data.noteName,
      octave: data.octave,
      frequency: data.frequency,
      cents: data.cents,
      hasSignal: true,
    );
  }
}
