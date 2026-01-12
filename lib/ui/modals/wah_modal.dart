import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/pod_controller.dart';
import '../../protocol/cc_map.dart';
import '../../models/patch.dart';
import '../../models/effect_models.dart';
import '../../models/app_settings.dart';
import '../widgets/rotary_knob.dart';
import '../widgets/effect_model_selector.dart';

/// Wah parameters modal with real-time updates.
class WahModal extends StatefulWidget {
  final PodController podController;
  final bool isConnected;
  final AppSettings settings;

  const WahModal({
    super.key,
    required this.podController,
    required this.isConnected,
    required this.settings,
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
    _loadValues();

    // Listen to edit buffer changes for real-time updates
    _editBufferSubscription = widget.podController.onEditBufferChanged.listen((buffer) {
      if (mounted) {
        _loadValues();
      }
    });
  }

  @override
  void didUpdateWidget(WahModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh values when widget updates (e.g., modal reopens)
    _loadValues();
  }

  @override
  void dispose() {
    _editBufferSubscription?.cancel();
    super.dispose();
  }

  void _loadValues() {
    setState(() {
      _wahSelect = widget.podController.getParameter(PodXtCC.wahSelect);
      _wahLevel = widget.podController.getParameter(PodXtCC.wahLevel);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Wah model selector with prev/next arrows and clickable dropdown
          EffectModelSelector(
            models: WahModels.all,
            selectedId: _wahSelect,
            onChanged: (id) {
              setState(() => _wahSelect = id);
              widget.podController.setParameter(PodXtCC.wahSelect, id);
            },
            isEnabled: widget.isConnected,
            pickerTitle: 'Select Wah Model',
            settings: widget.settings,
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
