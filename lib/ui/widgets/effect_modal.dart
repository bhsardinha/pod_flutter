import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/pod_controller.dart';
import '../../models/patch.dart';
import '../../models/app_settings.dart';
import '../../protocol/cc_map.dart';
import '../../protocol/effect_param_mappers.dart';
import 'effect_model_selector.dart';
import 'lcd_knob_array.dart';
import '../theme/pod_theme.dart';

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
        final midiValue = widget.podController.getParameter(param.ccParam);

        // If this param has a scaler, we need to reverse it when reading
        // Scaler converts UI value → MIDI, so we need MIDI → UI
        if (param.valueScaler != null) {
          final paramName = param.label.toLowerCase();
          if (paramName.contains('heads') || paramName.contains('bits')) {
            // Reverse of step → MIDI conversion
            // Based on pod-ui RangeConfig::Short edge algorithm:
            // scale = 128 / (8 - 0 + 1) = 16
            // step = value / 16, with special case: value == 127 → 8
            // Maps: 0-15→0, 16-31→1, 32-47→2, 48-63→3, 64-79→4, 80-95→5, 96-111→6, 112-126→7, 127→8
            final stepValue = midiValue == 127 ? 8 : (midiValue ~/ 16).clamp(0, 8);
            print('[EffectModal] descaler: MIDI $midiValue → step $stepValue (${param.label})');
            _paramValues[param.ccParam] = stepValue;
          } else if (paramName.contains('wave')) {
            // Reverse of Wave step → MIDI conversion (8 steps: 0-7)
            // Based on pod-ui: steps!(0, 16, 32, 48, 64, 80, 96, 112)
            // step = value / 16 (no special case for 127)
            // Maps: 0-15→0, 16-31→1, 32-47→2, 48-63→3, 64-79→4, 80-95→5, 96-111→6, 112-127→7
            final stepValue = (midiValue ~/ 16).clamp(0, 7);
            print('[EffectModal] descaler: MIDI $midiValue → step $stepValue (Wave)');
            _paramValues[param.ccParam] = stepValue;
          } else if (paramName.contains('heel') || paramName.contains('toe')) {
            // Reverse of Heel/Toe MIDI → display conversion
            // Based on pod-ui heel_toe_from_midi function
            // MIDI 0-127 → Internal 0-48 → Display -24 to +24
            int internal;
            if (midiValue <= 17) {
              internal = 0;
            } else if (midiValue >= 112) {
              internal = 48;
            } else {
              internal = ((midiValue - 18) ~/ 2) + 1;
            }

            // Convert internal (0-48) to display (-24 to +24)
            final displayValue = internal - 24;
            print('[EffectModal] descaler: MIDI $midiValue → internal $internal → display $displayValue (${param.label})');
            _paramValues[param.ccParam] = displayValue;
          } else if (paramName.contains('1m335') || paramName.contains('1457')) {
            // Reverse of Synth Harmony octave step → MIDI conversion (9 steps: 0-8)
            // Based on pod-ui: short!(@edge 0, 8) - same as Heads/Bits
            // step = value / 16, with special case: value == 127 → 8
            // Maps: 0-15→0, 16-31→1, 32-47→2, 48-63→3, 64-79→4, 80-95→5, 96-111→6, 112-126→7, 127→8
            final stepValue = midiValue == 127 ? 8 : (midiValue ~/ 16).clamp(0, 8);
            print('[EffectModal] descaler: MIDI $midiValue → step $stepValue (${param.label})');
            _paramValues[param.ccParam] = stepValue;
          } else {
            _paramValues[param.ccParam] = midiValue;
          }
        } else {
          _paramValues[param.ccParam] = midiValue;
        }
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
        if (param.isNoteSelectBased) {
          // NoteSelect-based: Check if in tempo sync (1-13) or MS/Hz mode (0)
          final noteSelect = widget.podController.getParameter(param.msbParam);
          if (noteSelect >= 1 && noteSelect <= 13) {
            // Tempo sync mode: knob value = NEGATIVE noteSelect (-13 to -1)
            _paramValues[param.msbParam] = -noteSelect;
          } else {
            // MS/Hz mode: knob value = actual MSB/LSB value (0-16383)
            // noteSelect = 0, read time/speed from MSB/LSB
            final isMod = widget.mapper is ModParamMapper;
            final msb = widget.podController.getParameter(
              isMod ? PodXtCC.modSpeedMsb : PodXtCC.delayTimeMsb
            );
            final lsb = widget.podController.getParameter(
              isMod ? PodXtCC.modSpeedLsb : PodXtCC.delayTimeLsb
            );
            final msbLsbValue = (msb << 7) | lsb;

            // Knob value directly represents the MSB/LSB value
            _paramValues[param.msbParam] = msbLsbValue;
          }
        } else if (param.lsbParam != null) {
          // Traditional MSB/LSB pair
          final msb = widget.podController.getParameter(param.msbParam);
          final lsb = widget.podController.getParameter(param.lsbParam!);
          final combined = (msb << 7) | lsb;
          _paramValues[param.msbParam] = combined;
        }
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

  void _onNoteSelectParamChanged(MsbLsbParamMapping mapping, int knobValue) {
    setState(() {
      _paramValues[mapping.msbParam] = knobValue;
    });

    if (knobValue < 0) {
      // Negative value: note division mode (-13 to -1)
      // Convert to positive and send as noteSelect (13 to 1)
      widget.podController.setParameter(mapping.msbParam, -knobValue);
    } else {
      // Positive value: MS/Hz mode (0-16383)
      // Set noteSelect to 0 to enable MS/Hz mode
      widget.podController.setParameter(mapping.msbParam, 0);

      // Determine which MSB/LSB parameters to use
      final isMod = widget.mapper is ModParamMapper;
      final msbParam = isMod ? PodXtCC.modSpeedMsb : PodXtCC.delayTimeMsb;
      final lsbParam = isMod ? PodXtCC.modSpeedLsb : PodXtCC.delayTimeLsb;

      // knobValue directly represents the 14-bit MSB/LSB value
      final msbLsbValue = knobValue;

      // Split into MSB (high 7 bits) and LSB (low 7 bits)
      final msb = (msbLsbValue >> 7) & 0x7F;
      final lsb = msbLsbValue & 0x7F;

      // Send both CC messages
      widget.podController.setParameter(msbParam, msb);
      widget.podController.setParameter(lsbParam, lsb);
    }
  }

  void _onMsbLsbParamChanged(MsbLsbParamMapping mapping, int combinedValue) {
    // Only process if we have an LSB parameter (traditional MSB/LSB pair)
    if (mapping.lsbParam == null) return;

    // Split 14-bit value into MSB (7 bits) and LSB (7 bits)
    final msb = (combinedValue >> 7) & 0x7F;
    final lsb = combinedValue & 0x7F;

    setState(() {
      _paramValues[mapping.msbParam] = combinedValue;
    });

    // Send both CC messages
    widget.podController.setParameter(mapping.msbParam, msb);
    widget.podController.setParameter(mapping.lsbParam!, lsb);
  }

  /// Check if this effect supports PRE/POST positioning
  bool get _supportsPositioning {
    return widget.mapper is ModParamMapper ||
        widget.mapper is DelayParamMapper ||
        widget.mapper is ReverbParamMapper;
  }

  /// Get current position (PRE or POST)
  bool get _isPostPosition {
    if (widget.mapper is ModParamMapper) {
      return widget.podController.modPositionPost;
    } else if (widget.mapper is DelayParamMapper) {
      return widget.podController.delayPositionPost;
    } else if (widget.mapper is ReverbParamMapper) {
      return widget.podController.reverbPositionPost;
    }
    return false;
  }

  /// Toggle position
  Future<void> _togglePosition() async {
    final isPost = _isPostPosition;
    if (widget.mapper is ModParamMapper) {
      await widget.podController.setModPosition(!isPost);
    } else if (widget.mapper is DelayParamMapper) {
      await widget.podController.setDelayPosition(!isPost);
    } else if (widget.mapper is ReverbParamMapper) {
      await widget.podController.setReverbPosition(!isPost);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final currentModel = widget.mapper.models.firstWhere(
      (m) => m.id == _selectedModelId,
      orElse: () => widget.mapper.models.first,
    );

    final modelParams = widget.mapper.mapModelParams(currentModel);

    // Reorder params for display if model specifies displayOrder
    final displayParams = currentModel.displayOrder != null
        ? currentModel.displayOrder!.map((i) => modelParams[i]).toList()
        : modelParams;

    final fixedParams = widget.mapper.getFixedParams();
    final msbLsbParams = widget.mapper.getMsbLsbParams();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // PRE/POST toggle (MOD, DELAY, REVERB only)
          if (_supportsPositioning) ...[
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: widget.isConnected ? _togglePosition : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isPostPosition
                      ? PodColors.surfaceLight
                      : PodColors.background,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _isPostPosition
                        ? PodColors.accent
                        : PodColors.textSecondary.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'PRE',
                        style: TextStyle(
                          color: !_isPostPosition
                            ? PodColors.accent
                            : PodColors.textSecondary.withValues(alpha: 0.5),
                          fontSize: 12,
                          fontWeight: !_isPostPosition
                            ? FontWeight.bold
                            : FontWeight.normal,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '/',
                        style: TextStyle(
                          color: PodColors.textSecondary.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'POST',
                        style: TextStyle(
                          color: _isPostPosition
                            ? PodColors.accent
                            : PodColors.textSecondary.withValues(alpha: 0.5),
                          fontSize: 12,
                          fontWeight: _isPostPosition
                            ? FontWeight.bold
                            : FontWeight.normal,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

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
                // MSB/LSB knobs (time, speed) - may be noteSelect-based or true MSB/LSB
                ...msbLsbParams.map((param) {
                  if (param.isNoteSelectBased) {
                    // NoteSelect-based: Linear knob from -13 to 16383
                    // Negative values (-13 to -1): note divisions
                    // Positive values (0 to 16383): MS/Hz mode
                    final value = _paramValues[param.msbParam] ?? -1;

                    return LcdKnobConfig(
                      label: param.label,
                      value: value,
                      minValue: param.minValue,  // -13
                      maxValue: param.maxValue,  // 16383
                      onValueChanged: (v) => _onNoteSelectParamChanged(param, v),
                      valueFormatter: param.formatter,
                    );
                  } else {
                    // Traditional MSB/LSB pair
                    final value = _paramValues[param.msbParam] ?? 0;

                    return LcdKnobConfig(
                      label: param.label,
                      value: value,
                      minValue: 0,
                      maxValue: param.maxValue,
                      onValueChanged: (v) => _onMsbLsbParamChanged(param, v),
                      valueFormatter: param.formatter,
                    );
                  }
                }),

                // Model-specific knobs (reordered per displayOrder if specified)
                ...displayParams.map((param) => LcdKnobConfig(
                      label: param.label,
                      value: _paramValues[param.ccParam] ?? 0,
                      minValue: param.minValue,
                      maxValue: param.maxValue,
                      onValueChanged: (v) {
                        final scaledValue = param.valueScaler != null
                            ? param.valueScaler!(v)
                            : v;
                        _onParamChanged(param.ccParam, scaledValue);
                      },
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
