import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/pod_controller.dart';
import '../../protocol/cc_map.dart';
import '../../models/patch.dart';
import '../../models/effect_models.dart';
import '../widgets/rotary_knob.dart';
import '../theme/pod_theme.dart';

/// Stomp effect parameters modal with real-time updates.
///
/// TODO: Implement full stomp controls
/// - Model selector (CC 75 - stompSelect) - 31 types from StompModels
/// - Dynamic params 2-6 (CC 79-83) based on selected model
class StompModal extends StatefulWidget {
  final PodController podController;
  final bool isConnected;

  const StompModal({
    super.key,
    required this.podController,
    required this.isConnected,
  });

  @override
  State<StompModal> createState() => _StompModalState();
}

class _StompModalState extends State<StompModal> {
  late int _stompSelect;
  late int _param2, _param3, _param4, _param5, _param6;
  StreamSubscription<EditBuffer>? _editBufferSubscription;

  @override
  void initState() {
    super.initState();
    // TODO: Initialize all parameters from podController
    _stompSelect = widget.podController.getParameter(PodXtCC.stompSelect);
    _param2 = widget.podController.getParameter(PodXtCC.stompParam2);
    _param3 = widget.podController.getParameter(PodXtCC.stompParam3);
    _param4 = widget.podController.getParameter(PodXtCC.stompParam4);
    _param5 = widget.podController.getParameter(PodXtCC.stompParam5);
    _param6 = widget.podController.getParameter(PodXtCC.stompParam6);

    // Subscribe for real-time updates
    _editBufferSubscription = widget.podController.onEditBufferChanged.listen((buffer) {
      if (mounted) {
        setState(() {
          _stompSelect = widget.podController.getParameter(PodXtCC.stompSelect);
          _param2 = widget.podController.getParameter(PodXtCC.stompParam2);
          _param3 = widget.podController.getParameter(PodXtCC.stompParam3);
          _param4 = widget.podController.getParameter(PodXtCC.stompParam4);
          _param5 = widget.podController.getParameter(PodXtCC.stompParam5);
          _param6 = widget.podController.getParameter(PodXtCC.stompParam6);
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
    // TODO: Get current stomp model to determine which params to show
    final stompModel = StompModels.byId(_stompSelect);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'TODO: Implement stomp model selector',
              style: TextStyle(color: PodColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              'Current Model: ${stompModel?.name ?? "Unknown"}',
              style: const TextStyle(color: PodColors.accent, fontSize: 14),
            ),
            if (stompModel?.pack != null)
              Text(
                'Pack: ${stompModel!.pack}',
                style: const TextStyle(color: PodColors.textSecondary, fontSize: 10),
              ),
            const SizedBox(height: 8),
            Text(
              'Parameters: ${stompModel?.params.length ?? 0}',
              style: const TextStyle(color: PodColors.textPrimary, fontSize: 12),
            ),
            const SizedBox(height: 20),
            const Text(
              'TODO: Dynamic param knobs based on selected model',
              style: TextStyle(color: PodColors.textSecondary, fontSize: 10),
            ),
            const SizedBox(height: 12),
            // TODO: Map stompModel.params to RotaryKnob widgets
            // param2 → stompParam2, param3 → stompParam3, etc.
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                if (stompModel != null && stompModel.params.isNotEmpty)
                  ...List.generate(
                    stompModel.params.length,
                    (index) => RotaryKnob(
                      label: stompModel.params[index].name.toUpperCase(),
                      value: [_param2, _param3, _param4, _param5, _param6][index],
                      onValueChanged: (v) {
                        setState(() {
                          switch (index) {
                            case 0:
                              _param2 = v;
                              if (widget.isConnected) {
                                widget.podController.setParameter(PodXtCC.stompParam2, v);
                              }
                              break;
                            case 1:
                              _param3 = v;
                              if (widget.isConnected) {
                                widget.podController.setParameter(PodXtCC.stompParam3, v);
                              }
                              break;
                            case 2:
                              _param4 = v;
                              if (widget.isConnected) {
                                widget.podController.setParameter(PodXtCC.stompParam4, v);
                              }
                              break;
                            case 3:
                              _param5 = v;
                              if (widget.isConnected) {
                                widget.podController.setParameter(PodXtCC.stompParam5, v);
                              }
                              break;
                            case 4:
                              _param6 = v;
                              if (widget.isConnected) {
                                widget.podController.setParameter(PodXtCC.stompParam6, v);
                              }
                              break;
                          }
                        });
                      },
                      size: 60,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
