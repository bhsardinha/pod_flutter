import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/pod_controller.dart';
import '../../protocol/cc_map.dart';
import '../../models/patch.dart';
import '../widgets/rotary_knob.dart';

/// Noise gate parameters modal with real-time updates.
///
/// This is the REFERENCE PATTERN for all effect modals that need
/// real-time updates from the POD device via StreamSubscription.
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
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Threshold knob (-96 to 0, physically reversed)
          RotaryKnob(
            label: 'THRESHOLD',
            value: 96 - _threshold, // Invert for display (makes knob work backwards)
            maxValue: 96,
            onValueChanged: (v) {
              final invertedValue = 96 - v; // Invert: clockwise decreases, counterclockwise increases
              setState(() => _threshold = invertedValue);
              if (widget.isConnected) {
                widget.podController.setGateThreshold(invertedValue);
              }
            },
            size: 60,
            valueFormatter: (v) => (v - 96).toString(), // Display as -96 to 0
          ),
          // Decay knob (0-100%)
          RotaryKnob(
            label: 'DECAY',
            value: _decay,
            onValueChanged: (v) {
              setState(() => _decay = v);
              if (widget.isConnected) {
                widget.podController.setParameter(PodXtCC.gateDecay, v);
              }
            },
            size: 60,
            valueFormatter: (v) => '${(v * 100 / 127).round()}%', // Display as percentage
          ),
        ],
      ),
    );
  }
}
