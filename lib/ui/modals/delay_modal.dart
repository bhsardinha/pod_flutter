import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/pod_controller.dart';
import '../../protocol/cc_map.dart';
import '../../models/patch.dart';
import '../../models/effect_models.dart';
import '../widgets/rotary_knob.dart';
import '../theme/pod_theme.dart';

/// Delay effect parameters modal with real-time updates.
///
/// TODO: Implement full delay controls
/// - Model selector (CC 88 - delaySelect) - 14 types from DelayModels
/// - Time MSB/LSB (CC 30/62) or Note Select (CC 31) - tempo sync toggle
/// - Dynamic params 2-4 (CC 33/35/85) based on selected model
/// - Mix (CC 34) and Position (CC 87)
class DelayModal extends StatefulWidget {
  final PodController podController;
  final bool isConnected;

  const DelayModal({
    super.key,
    required this.podController,
    required this.isConnected,
  });

  @override
  State<DelayModal> createState() => _DelayModalState();
}

class _DelayModalState extends State<DelayModal> {
  late int _delaySelect;
  late int _timeMsb, _timeLsb, _noteSelect;
  late int _param2, _param3, _param4;
  late int _mix, _position;
  StreamSubscription<EditBuffer>? _editBufferSubscription;

  @override
  void initState() {
    super.initState();
    // TODO: Initialize all parameters from podController
    _delaySelect = widget.podController.getParameter(PodXtCC.delaySelect);
    _timeMsb = widget.podController.getParameter(PodXtCC.delayTimeMsb);
    _timeLsb = widget.podController.getParameter(PodXtCC.delayTimeLsb);
    _noteSelect = widget.podController.getParameter(PodXtCC.delayNoteSelect);
    _param2 = widget.podController.getParameter(PodXtCC.delayParam2);
    _param3 = widget.podController.getParameter(PodXtCC.delayParam3);
    _param4 = widget.podController.getParameter(PodXtCC.delayParam4);
    _mix = widget.podController.getParameter(PodXtCC.delayMix);
    _position = widget.podController.getParameter(PodXtCC.delayPosition);

    // Subscribe for real-time updates
    _editBufferSubscription = widget.podController.onEditBufferChanged.listen((buffer) {
      if (mounted) {
        setState(() {
          _delaySelect = widget.podController.getParameter(PodXtCC.delaySelect);
          _timeMsb = widget.podController.getParameter(PodXtCC.delayTimeMsb);
          _timeLsb = widget.podController.getParameter(PodXtCC.delayTimeLsb);
          _noteSelect = widget.podController.getParameter(PodXtCC.delayNoteSelect);
          _param2 = widget.podController.getParameter(PodXtCC.delayParam2);
          _param3 = widget.podController.getParameter(PodXtCC.delayParam3);
          _param4 = widget.podController.getParameter(PodXtCC.delayParam4);
          _mix = widget.podController.getParameter(PodXtCC.delayMix);
          _position = widget.podController.getParameter(PodXtCC.delayPosition);
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
    // TODO: Get current delay model
    final delayModel = DelayModels.byId(_delaySelect);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'TODO: Implement delay model selector',
              style: TextStyle(color: PodColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              'Current Model: ${delayModel?.name ?? "Unknown"}',
              style: const TextStyle(color: PodColors.accent, fontSize: 14),
            ),
            const SizedBox(height: 20),
            const Text(
              'TODO: Time control with tempo sync toggle',
              style: TextStyle(color: PodColors.textSecondary, fontSize: 10),
            ),
            Text(
              'Time MSB/LSB: $_timeMsb/$_timeLsb | Note: $_noteSelect',
              style: const TextStyle(color: PodColors.textPrimary, fontSize: 10),
            ),
            const SizedBox(height: 20),
            const Text(
              'TODO: Dynamic param knobs (2-3 based on model)',
              style: TextStyle(color: PodColors.textSecondary, fontSize: 10),
            ),
            const SizedBox(height: 12),
            // TODO: Show controls for mix and position
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                RotaryKnob(
                  label: 'MIX',
                  value: _mix,
                  onValueChanged: (v) {
                    setState(() => _mix = v);
                    if (widget.isConnected) {
                      widget.podController.setParameter(PodXtCC.delayMix, v);
                    }
                  },
                  size: 60,
                ),
                RotaryKnob(
                  label: 'POSITION',
                  value: _position,
                  onValueChanged: (v) {
                    setState(() => _position = v);
                    if (widget.isConnected) {
                      widget.podController.setParameter(PodXtCC.delayPosition, v);
                    }
                  },
                  size: 60,
                  valueFormatter: (v) => v > 63 ? 'POST' : 'PRE',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
