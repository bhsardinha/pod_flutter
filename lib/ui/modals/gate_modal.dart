import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/pod_controller.dart';
import '../../protocol/cc_map.dart';
import '../../models/patch.dart';
import '../widgets/lcd_knob_array.dart';

/// Noise gate parameters modal with real-time updates.
///
/// Uses LCD-style knobs matching POD XT hardware aesthetic.
class GateModal extends StatefulWidget {
  final PodController podController;
  final bool isConnected;

  const GateModal({
    super.key,
    required this.podController,
    required this.isConnected,
  });

  @override
  State<GateModal> createState() => _GateModalState();
}

class _GateModalState extends State<GateModal> {
  late int _threshold;
  late int _decay;
  StreamSubscription<EditBuffer>? _editBufferSubscription;

  @override
  void initState() {
    super.initState();
    _threshold = widget.podController.gateThreshold;
    _decay = widget.podController.getParameter(PodXtCC.gateDecay);

    // Listen to edit buffer changes for real-time updates
    _editBufferSubscription = widget.podController.onEditBufferChanged.listen((buffer) {
      if (mounted) {
        setState(() {
          _threshold = widget.podController.gateThreshold;
          _decay = widget.podController.getParameter(PodXtCC.gateDecay);
        });
      }
    });
  }

  @override
  void dispose() {
    _editBufferSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: LcdKnobArray(
        knobs: [
          // Threshold knob (-96 to 0, physically reversed)
          LcdKnobConfig(
            label: 'THRESHOLD',
            value: 96 - _threshold, // Invert for display (makes knob work backwards)
            minValue: 0,
            maxValue: 96,
            onValueChanged: (v) {
              final invertedValue = 96 - v; // Invert: clockwise decreases, counterclockwise increases
              setState(() => _threshold = invertedValue);
              if (widget.isConnected) {
                widget.podController.setGateThreshold(invertedValue);
              }
            },
            valueFormatter: (v) => (v - 96).toString(), // Display as -96 to 0
          ),
          // Decay knob (0-100%)
          LcdKnobConfig(
            label: 'DECAY',
            value: _decay,
            minValue: 0,
            maxValue: 127,
            onValueChanged: (v) {
              setState(() => _decay = v);
              if (widget.isConnected) {
                widget.podController.setParameter(PodXtCC.gateDecay, v);
              }
            },
            valueFormatter: (v) => '${(v * 100 / 127).round()}%', // Display as percentage
          ),
        ],
      ),
    );
  }
}
