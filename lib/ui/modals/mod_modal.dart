import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/pod_controller.dart';
import '../../protocol/cc_map.dart';
import '../../models/patch.dart';
import '../../models/effect_models.dart';
import '../widgets/rotary_knob.dart';
import '../theme/pod_theme.dart';

/// Modulation effect parameters modal with real-time updates.
///
/// TODO: Implement full mod controls
/// - Model selector (CC 58 - modSelect) - 24 types from ModModels
/// - Speed MSB/LSB (CC 29/61) or Note Select (CC 51) - tempo sync toggle
/// - Dynamic params 2-4 (CC 52-54) based on selected model
/// - Mix (CC 56) and Position (CC 57)
class ModModal extends StatefulWidget {
  final PodController podController;
  final bool isConnected;

  const ModModal({
    super.key,
    required this.podController,
    required this.isConnected,
  });

  @override
  State<ModModal> createState() => _ModModalState();
}

class _ModModalState extends State<ModModal> {
  late int _modSelect;
  late int _speedMsb, _speedLsb, _noteSelect;
  late int _param2, _param3, _param4;
  late int _mix, _position;
  StreamSubscription<EditBuffer>? _editBufferSubscription;

  @override
  void initState() {
    super.initState();
    // TODO: Initialize all parameters from podController
    _modSelect = widget.podController.getParameter(PodXtCC.modSelect);
    _speedMsb = widget.podController.getParameter(PodXtCC.modSpeedMsb);
    _speedLsb = widget.podController.getParameter(PodXtCC.modSpeedLsb);
    _noteSelect = widget.podController.getParameter(PodXtCC.modNoteSelect);
    _param2 = widget.podController.getParameter(PodXtCC.modParam2);
    _param3 = widget.podController.getParameter(PodXtCC.modParam3);
    _param4 = widget.podController.getParameter(PodXtCC.modParam4);
    _mix = widget.podController.getParameter(PodXtCC.modMix);
    _position = widget.podController.getParameter(PodXtCC.modPosition);

    // Subscribe for real-time updates
    _editBufferSubscription = widget.podController.onEditBufferChanged.listen((buffer) {
      if (mounted) {
        setState(() {
          _modSelect = widget.podController.getParameter(PodXtCC.modSelect);
          _speedMsb = widget.podController.getParameter(PodXtCC.modSpeedMsb);
          _speedLsb = widget.podController.getParameter(PodXtCC.modSpeedLsb);
          _noteSelect = widget.podController.getParameter(PodXtCC.modNoteSelect);
          _param2 = widget.podController.getParameter(PodXtCC.modParam2);
          _param3 = widget.podController.getParameter(PodXtCC.modParam3);
          _param4 = widget.podController.getParameter(PodXtCC.modParam4);
          _mix = widget.podController.getParameter(PodXtCC.modMix);
          _position = widget.podController.getParameter(PodXtCC.modPosition);
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
    // TODO: Get current mod model
    final modModel = ModModels.byId(_modSelect);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'TODO: Implement mod model selector',
              style: TextStyle(color: PodColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              'Current Model: ${modModel?.name ?? "Unknown"}',
              style: const TextStyle(color: PodColors.accent, fontSize: 14),
            ),
            const SizedBox(height: 20),
            const Text(
              'TODO: Speed control with tempo sync toggle',
              style: TextStyle(color: PodColors.textSecondary, fontSize: 10),
            ),
            Text(
              'Speed MSB/LSB: $_speedMsb/$_speedLsb | Note: $_noteSelect',
              style: const TextStyle(color: PodColors.textPrimary, fontSize: 10),
            ),
            const SizedBox(height: 20),
            const Text(
              'TODO: Dynamic param knobs (1-3 based on model)',
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
                      widget.podController.setParameter(PodXtCC.modMix, v);
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
                      widget.podController.setParameter(PodXtCC.modPosition, v);
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
