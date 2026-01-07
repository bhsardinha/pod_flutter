import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/pod_controller.dart';
import '../../protocol/cc_map.dart';
import '../../models/patch.dart';
import '../widgets/rotary_knob.dart';
import '../theme/pod_theme.dart';

/// Compressor parameters modal with real-time updates.
///
/// TODO: Implement full compressor controls
/// - Threshold knob (CC 9 - compressorThreshold)
/// - Gain knob (CC 5 - compressorGain)
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
    // TODO: Initialize threshold and gain from podController
    _threshold = widget.podController.getParameter(PodXtCC.compressorThreshold);
    _gain = widget.podController.getParameter(PodXtCC.compressorGain);

    // TODO: Subscribe to edit buffer for real-time updates
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'TODO: Implement compressor controls',
            style: TextStyle(color: PodColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // TODO: Threshold knob (CC 9)
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
                valueFormatter: (v) => '${v}', // TODO: Add proper formatter
              ),
              // TODO: Gain knob (CC 5)
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
                valueFormatter: (v) => '$v', // TODO: Add proper formatter
              ),
            ],
          ),
        ],
      ),
    );
  }
}
