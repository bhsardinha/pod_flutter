import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/pod_controller.dart';
import '../../protocol/cc_map.dart';
import '../../models/patch.dart';
import '../../models/effect_models.dart';
import '../widgets/rotary_knob.dart';
import '../theme/pod_theme.dart';

/// Wah parameters modal with real-time updates.
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
    _wahSelect = widget.podController.getParameter(PodXtCC.wahSelect);
    _wahLevel = widget.podController.getParameter(PodXtCC.wahLevel);

    // Listen to edit buffer changes for real-time updates
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Wah model selector with prev/next arrows
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: PodColors.surfaceLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: PodColors.accent.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Previous button
                IconButton(
                  icon: const Icon(Icons.arrow_left, color: PodColors.accent),
                  onPressed: widget.isConnected ? () {
                    final newIndex = (_wahSelect - 1) % WahModels.all.length;
                    final newValue = newIndex < 0 ? WahModels.all.length - 1 : newIndex;
                    setState(() => _wahSelect = newValue);
                    widget.podController.setParameter(PodXtCC.wahSelect, newValue);
                  } : null,
                ),
                // Current model name
                Expanded(
                  child: Text(
                    WahModels.byId(_wahSelect)?.name ?? 'Unknown',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: PodColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // Next button
                IconButton(
                  icon: const Icon(Icons.arrow_right, color: PodColors.accent),
                  onPressed: widget.isConnected ? () {
                    final newValue = (_wahSelect + 1) % WahModels.all.length;
                    setState(() => _wahSelect = newValue);
                    widget.podController.setParameter(PodXtCC.wahSelect, newValue);
                  } : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Wah position knob (0-100%)
          RotaryKnob(
            label: 'POSITION',
            value: _wahLevel,
            onValueChanged: (v) {
              setState(() => _wahLevel = v);
              if (widget.isConnected) {
                widget.podController.setParameter(PodXtCC.wahLevel, v);
              }
            },
            size: 60,
            valueFormatter: (v) => '${(v * 100 / 127).round()}%',
          ),
        ],
      ),
    );
  }
}
