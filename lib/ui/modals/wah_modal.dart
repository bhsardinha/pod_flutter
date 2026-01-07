import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/pod_controller.dart';
import '../../protocol/cc_map.dart';
import '../../models/patch.dart';
import '../../models/effect_models.dart';
import '../widgets/rotary_knob.dart';
import '../theme/pod_theme.dart';

/// Wah parameters modal with real-time updates.
///
/// TODO: Implement full wah controls
/// - Model selector (CC 91 - wahSelect) - 8 types from WahModels
/// - Level knob (CC 4 - wahLevel)
class WahModal extends StatefulWidget {
  final PodController podController;
  final bool isConnected;

  const WahModal({
    super.key,
    required this.podController,
    required this.isConnected,
  });

  @override
  State<WahModal> createState() => _WahModalState();
}

class _WahModalState extends State<WahModal> {
  late int _wahSelect;
  late int _wahLevel;
  StreamSubscription<EditBuffer>? _editBufferSubscription;

  @override
  void initState() {
    super.initState();
    // TODO: Initialize from podController
    _wahSelect = widget.podController.getParameter(PodXtCC.wahSelect);
    _wahLevel = widget.podController.getParameter(PodXtCC.wahLevel);

    // Subscribe for real-time updates
    _editBufferSubscription = widget.podController.onEditBufferChanged.listen((buffer) {
      if (mounted) {
        setState(() {
          _wahSelect = widget.podController.getParameter(PodXtCC.wahSelect);
          _wahLevel = widget.podController.getParameter(PodXtCC.wahLevel);
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
    // TODO: Get current wah model
    final wahModel = WahModels.byId(_wahSelect);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'TODO: Implement wah model selector',
            style: TextStyle(color: PodColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            'Current Model: ${wahModel?.name ?? "Unknown"}',
            style: const TextStyle(color: PodColors.accent, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            'Available: ${WahModels.all.length} wah types',
            style: const TextStyle(color: PodColors.textSecondary, fontSize: 10),
          ),
          const SizedBox(height: 20),
          // TODO: Wah Level knob (CC 4)
          RotaryKnob(
            label: 'LEVEL',
            value: _wahLevel,
            onValueChanged: (v) {
              setState(() => _wahLevel = v);
              if (widget.isConnected) {
                widget.podController.setParameter(PodXtCC.wahLevel, v);
              }
            },
            size: 60,
          ),
        ],
      ),
    );
  }
}
