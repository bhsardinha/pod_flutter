import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/pod_controller.dart';
import '../../models/patch.dart';
import '../../models/app_settings.dart';
import '../../protocol/cc_map.dart';
import '../../protocol/effect_param_mappers.dart';
import 'effect_model_selector.dart';
import 'lcd_knob_array.dart';

/// Unified modal for all effect types (Wah, Stomp, Mod, Delay, Reverb)
/// Dynamically generates controls based on selected model and mapper
class EffectModal extends StatefulWidget {
  final PodController podController;
  final bool isConnected;
  final AppSettings settings;
  final EffectParamMapper mapper;

  const EffectModal({
    super.key,
    required this.podController,
    required this.isConnected,
    required this.settings,
    required this.mapper,
  });

  @override
  State<EffectModal> createState() => _EffectModalState();
}

class _EffectModalState extends State<EffectModal> {
  late int _selectedModelId;
  late Map<CCParam, int> _paramValues; // Cache of all parameter values
  StreamSubscription<EditBuffer>? _editBufferSubscription;

  @override
  void initState() {
    super.initState();
    _loadValues();

    _editBufferSubscription =
        widget.podController.onEditBufferChanged.listen((buffer) {
      if (mounted) {
        _loadValues();
      }
    });
  }

  @override
  void didUpdateWidget(EffectModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadValues();
  }

  @override
  void dispose() {
    _editBufferSubscription?.cancel();
    super.dispose();
  }

  void _loadValues() {
    setState(() {
      // Load current model
      _selectedModelId =
          widget.podController.getParameter(widget.mapper.selectParam);

      // Load all parameter values
      _paramValues = {};

      // Get current model
      final model = widget.mapper.models.firstWhere(
        (m) => m.id == _selectedModelId,
        orElse: () => widget.mapper.models.first,
      );

      // Load model-specific params
      final modelParams = widget.mapper.mapModelParams(model);
      for (final param in modelParams) {
        _paramValues[param.ccParam] =
            widget.podController.getParameter(param.ccParam);
      }

      // Load fixed params
      final fixedParams = widget.mapper.getFixedParams();
      for (final param in fixedParams) {
        _paramValues[param.ccParam] =
            widget.podController.getParameter(param.ccParam);
      }

      // Load MSB/LSB params (combined into single value)
      final msbLsbParams = widget.mapper.getMsbLsbParams();
      for (final param in msbLsbParams) {
        final msb = widget.podController.getParameter(param.msbParam);
        final lsb = widget.podController.getParameter(param.lsbParam);
        final combined = (msb << 7) | lsb;
        // Store as MSB param key with combined value
        _paramValues[param.msbParam] = combined;
      }
    });
  }

  void _onModelChanged(int newModelId) async {
    setState(() => _selectedModelId = newModelId);
    widget.podController.setParameter(widget.mapper.selectParam, newModelId);

    // Request edit buffer from hardware to get default parameter values
    await widget.podController.refreshEditBuffer();

    // Reload values from updated buffer
    _loadValues();
  }

  void _onParamChanged(CCParam param, int value) {
    setState(() {
      _paramValues[param] = value;
    });
    widget.podController.setParameter(param, value);
  }

  void _onMsbLsbParamChanged(MsbLsbParamMapping mapping, int combinedValue) {
    // Split 14-bit value into MSB (7 bits) and LSB (7 bits)
    final msb = (combinedValue >> 7) & 0x7F;
    final lsb = combinedValue & 0x7F;

    setState(() {
      _paramValues[mapping.msbParam] = combinedValue;
    });

    // Send both CC messages
    widget.podController.setParameter(mapping.msbParam, msb);
    widget.podController.setParameter(mapping.lsbParam, lsb);
  }

  @override
  Widget build(BuildContext context) {
    final currentModel = widget.mapper.models.firstWhere(
      (m) => m.id == _selectedModelId,
      orElse: () => widget.mapper.models.first,
    );

    final modelParams = widget.mapper.mapModelParams(currentModel);
    final fixedParams = widget.mapper.getFixedParams();
    final msbLsbParams = widget.mapper.getMsbLsbParams();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Model selector
          EffectModelSelector(
            models: widget.mapper.models,
            selectedId: _selectedModelId,
            onChanged: _onModelChanged,
            isEnabled: widget.isConnected,
            pickerTitle: widget.mapper.pickerTitle,
            settings: widget.settings,
          ),

          const SizedBox(height: 28),

          // Dynamic LCD knob array section
          if (msbLsbParams.isNotEmpty ||
              modelParams.isNotEmpty ||
              fixedParams.isNotEmpty)
            LcdKnobArray(
              knobs: [
                // MSB/LSB knobs (time, speed)
                ...msbLsbParams.map((param) => LcdKnobConfig(
                      label: param.label,
                      value: _paramValues[param.msbParam] ?? 0,
                      minValue: 0,
                      maxValue: param.maxValue,
                      onValueChanged: (v) => _onMsbLsbParamChanged(param, v),
                      valueFormatter: param.formatter,
                    )),

                // Model-specific knobs
                ...modelParams.map((param) => LcdKnobConfig(
                      label: param.label,
                      value: _paramValues[param.ccParam] ?? 0,
                      minValue: param.minValue,
                      maxValue: param.maxValue,
                      onValueChanged: (v) => _onParamChanged(param.ccParam, v),
                      valueFormatter: param.formatter,
                    )),

                // Fixed knobs (always shown)
                ...fixedParams.map((param) => LcdKnobConfig(
                      label: param.label,
                      value: _paramValues[param.ccParam] ?? 0,
                      minValue: param.minValue,
                      maxValue: param.maxValue,
                      onValueChanged: (v) => _onParamChanged(param.ccParam, v),
                      valueFormatter: param.formatter,
                    )),
              ],
            ),
        ],
      ),
    );
  }
}
