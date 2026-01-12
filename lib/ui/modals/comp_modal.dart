import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/pod_controller.dart';
import '../../protocol/cc_map.dart';
import '../../models/patch.dart';
import '../widgets/rotary_knob.dart';

/// Compressor parameters modal with real-time updates.
class CompModal extends StatefulWidget {
  final PodController podController;
  final bool isConnected;

  const CompModal({
    super.key,
    required this.podController,
    required this.isConnected,
  });

  @override
  State<CompModal> createState() => _CompModalState();
}

class _CompModalState extends State<CompModal> {
  late int _threshold;
  late int _gain;
  StreamSubscription<EditBuffer>? _editBufferSubscription;

  @override
  void initState() {
    super.initState();
    _threshold = widget.podController.getParameter(PodXtCC.compressorThreshold);
    _gain = widget.podController.getParameter(PodXtCC.compressorGain);

    // Listen to edit buffer changes for real-time updates
    _editBufferSubscription = widget.podController.onEditBufferChanged.listen((buffer) {
      if (mounted) {
        setState(() {
          _threshold = widget.podController.getParameter(PodXtCC.compressorThreshold);
          _gain = widget.podController.getParameter(PodXtCC.compressorGain);
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
          // Threshold knob (-63.0 to 0.0 dB)
          // Formula from pod-ui: dB = value * (63.0/127.0) - 63.0
          RotaryKnob(
            label: 'THRESHOLD',
            value: _threshold,
            onValueChanged: (v) {
              setState(() => _threshold = v);
              if (widget.isConnected) {
                widget.podController.setParameter(PodXtCC.compressorThreshold, v);
              }
            },
            size: 60,
            valueFormatter: (v) {
              final db = (v * 63.0 / 127.0) - 63.0;
              return db.toStringAsFixed(1);
            },
          ),
          // Gain knob (0.0 to 16.0 dB)
          // Formula from pod-ui: dB = value * (16.0/127.0) + 0.0
          RotaryKnob(
            label: 'GAIN',
            value: _gain,
            onValueChanged: (v) {
              setState(() => _gain = v);
              if (widget.isConnected) {
                widget.podController.setParameter(PodXtCC.compressorGain, v);
              }
            },
            size: 60,
            valueFormatter: (v) {
              final db = v * 16.0 / 127.0;
              return db.toStringAsFixed(1);
            },
          ),
        ],
      ),
    );
  }
}
