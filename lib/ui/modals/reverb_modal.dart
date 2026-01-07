import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/pod_controller.dart';
import '../../protocol/cc_map.dart';
import '../../models/patch.dart';
import '../../models/effect_models.dart';
import '../widgets/rotary_knob.dart';
import '../theme/pod_theme.dart';

/// Reverb parameters modal with real-time updates.
///
/// TODO: Implement full reverb controls
/// - Model selector (CC 37 - reverbSelect) - 15 types from ReverbModels
/// - Decay (CC 38), Tone (CC 39), Pre-Delay (CC 40), Level (CC 18)
class ReverbModal extends StatefulWidget {
  final PodController podController;
  final bool isConnected;

  const ReverbModal({
    super.key,
    required this.podController,
    required this.isConnected,
  });

  @override
  State<ReverbModal> createState() => _ReverbModalState();
}

class _ReverbModalState extends State<ReverbModal> {
  late int _reverbSelect;
  late int _decay, _tone, _preDelay, _level;
  StreamSubscription<EditBuffer>? _editBufferSubscription;

  @override
  void initState() {
    super.initState();
    // TODO: Initialize from podController
    _reverbSelect = widget.podController.getParameter(PodXtCC.reverbSelect);
    _decay = widget.podController.getParameter(PodXtCC.reverbDecay);
    _tone = widget.podController.getParameter(PodXtCC.reverbTone);
    _preDelay = widget.podController.getParameter(PodXtCC.reverbPreDelay);
    _level = widget.podController.getParameter(PodXtCC.reverbLevel);

    // Subscribe for real-time updates
    _editBufferSubscription = widget.podController.onEditBufferChanged.listen((buffer) {
      if (mounted) {
        setState(() {
          _reverbSelect = widget.podController.getParameter(PodXtCC.reverbSelect);
          _decay = widget.podController.getParameter(PodXtCC.reverbDecay);
          _tone = widget.podController.getParameter(PodXtCC.reverbTone);
          _preDelay = widget.podController.getParameter(PodXtCC.reverbPreDelay);
          _level = widget.podController.getParameter(PodXtCC.reverbLevel);
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
    // TODO: Get current reverb model
    final reverbModel = ReverbModels.byId(_reverbSelect);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'TODO: Implement reverb model selector',
              style: TextStyle(color: PodColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              'Current Model: ${reverbModel?.name ?? "Unknown"}',
              style: const TextStyle(color: PodColors.accent, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Available: ${ReverbModels.all.length} reverb types',
              style: const TextStyle(color: PodColors.textSecondary, fontSize: 10),
            ),
            const SizedBox(height: 20),
            // TODO: Four RotaryKnobs for decay, tone, pre-delay, level
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                RotaryKnob(
                  label: 'DECAY',
                  value: _decay,
                  onValueChanged: (v) {
                    setState(() => _decay = v);
                    if (widget.isConnected) {
                      widget.podController.setParameter(PodXtCC.reverbDecay, v);
                    }
                  },
                  size: 60,
                ),
                RotaryKnob(
                  label: 'TONE',
                  value: _tone,
                  onValueChanged: (v) {
                    setState(() => _tone = v);
                    if (widget.isConnected) {
                      widget.podController.setParameter(PodXtCC.reverbTone, v);
                    }
                  },
                  size: 60,
                ),
                RotaryKnob(
                  label: 'PRE-DELAY',
                  value: _preDelay,
                  onValueChanged: (v) {
                    setState(() => _preDelay = v);
                    if (widget.isConnected) {
                      widget.podController.setParameter(PodXtCC.reverbPreDelay, v);
                    }
                  },
                  size: 60,
                ),
                RotaryKnob(
                  label: 'LEVEL',
                  value: _level,
                  onValueChanged: (v) {
                    setState(() => _level = v);
                    if (widget.isConnected) {
                      widget.podController.setParameter(PodXtCC.reverbLevel, v);
                    }
                  },
                  size: 60,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
