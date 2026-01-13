# Effect Modal Refactor Plan

## Overview

Refactor all effect modals (Wah, Stomp, Mod, Delay, Reverb) to use a single unified `EffectModal` component with dynamic parameter mapping. This eliminates code duplication and provides consistent UX across all effect types.

## Current State

- **wah_modal.dart**: Custom modal with model selector + 1 fixed knob (POSITION)
- **stomp_modal.dart**: TODO stub
- **mod_modal.dart**: TODO stub with unused param fields
- **delay_modal.dart**: TODO stub with unused param fields
- **reverb_modal.dart**: TODO stub

Each effect type has:
- Different CC parameter for model selection
- Different number of generic CC parameters (stompParam2-6, modParam2-4, etc.)
- Each model within a type has different parameter counts and names
- Special cases: MSB/LSB for time/speed, tempo sync, fixed params like Mix

## Goals

1. **Single Modal Component**: One `EffectModal` widget for all 5 effect types
2. **Dynamic Parameters**: Automatically generate knobs based on selected model's parameters
3. **Reusable Selector**: Use existing `EffectModelSelector` for all types
4. **Type Safety**: Strongly typed parameter mappings
5. **Maintainability**: Parameter definitions in one place, easy to extend
6. **Consistency**: Same UX patterns across all effect types

## Architecture

### Component Hierarchy

```
EffectModal (single modal widget)
  ├─ EffectModelSelector (model picker with list/grid view)
  │   └─ Uses EffectParamMapper.models
  └─ Dynamic Knobs (generated from mapper)
      ├─ Model-specific params (from EffectModel.params)
      └─ Fixed params (always shown, like Mix/Level)

EffectParamMapper (abstract base class)
  ├─ WahParamMapper
  ├─ StompParamMapper
  ├─ ModParamMapper
  ├─ DelayParamMapper
  └─ ReverbParamMapper
```

### Data Flow

1. User opens modal → `EffectModal` receives `mapper` and initial state
2. `EffectModal` reads current model ID from `podController`
3. `EffectModelSelector` displays current model, allows selection
4. On model change:
   - `mapper.mapParams(newModel)` returns parameter mappings
   - Modal rebuilds knobs dynamically
   - Each knob sends CC via `mapper.getParamCC(index)`
5. Knob value changes → Send MIDI CC → Update local state

## File Structure

```
lib/
├── protocol/
│   ├── cc_map.dart (existing - CC parameter definitions)
│   └── effect_param_mappers.dart (NEW - parameter mapping logic)
│
├── ui/
│   ├── widgets/
│   │   ├── effect_model_selector.dart (existing - model picker)
│   │   ├── rotary_knob.dart (existing - knob widget)
│   │   └── effect_modal.dart (NEW - unified modal)
│   │
│   ├── modals/
│   │   ├── wah_modal.dart (DELETE - replaced by EffectModal)
│   │   ├── stomp_modal.dart (DELETE - replaced by EffectModal)
│   │   ├── mod_modal.dart (DELETE - replaced by EffectModal)
│   │   ├── delay_modal.dart (DELETE - replaced by EffectModal)
│   │   ├── reverb_modal.dart (DELETE - replaced by EffectModal)
│   │   ├── amp_modal.dart (keep - different pattern)
│   │   ├── comp_modal.dart (keep - different pattern)
│   │   └── gate_modal.dart (keep - different pattern)
│   │
│   └── screens/
│       └── main_screen.dart (UPDATE - use EffectModal for all effects)
│
└── models/
    ├── effect_models.dart (existing - model definitions)
    └── app_settings.dart (existing - settings)
```

## Implementation Details

### 1. `lib/protocol/effect_param_mappers.dart`

#### Base Classes

```dart
/// Represents a parameter mapping from EffectParam to CC control
class EffectParamMapping {
  final String label;                    // Display label (from EffectParam.name or custom)
  final CCParam ccParam;                 // CC parameter to control
  final String Function(int) formatter;  // Value display formatter
  final int minValue;                    // Min MIDI value (default 0)
  final int maxValue;                    // Max MIDI value (default 127)

  const EffectParamMapping({
    required this.label,
    required this.ccParam,
    required this.formatter,
    this.minValue = 0,
    this.maxValue = 127,
  });
}

/// Special parameter type for MSB/LSB pairs (time, speed)
class MsbLsbParamMapping {
  final String label;
  final CCParam msbParam;
  final CCParam lsbParam;
  final String Function(int) formatter;
  final int maxValue;  // Combined 14-bit value max

  const MsbLsbParamMapping({
    required this.label,
    required this.msbParam,
    required this.lsbParam,
    required this.formatter,
    this.maxValue = 16383,  // 2^14 - 1
  });
}

/// Base mapper class for all effect types
abstract class EffectParamMapper {
  /// Display title for the modal
  String get modalTitle;

  /// Display title for the model picker
  String get pickerTitle;

  /// All available models for this effect type
  List<EffectModel> get models;

  /// CC parameter for model selection
  CCParam get selectParam;

  /// Map a specific model's parameters to CC controls
  /// Returns mappings in order of model.params
  List<EffectParamMapping> mapModelParams(EffectModel model);

  /// Get fixed parameters (always shown regardless of model)
  /// Examples: Mix (mod/delay), Position (wah)
  List<EffectParamMapping> getFixedParams();

  /// Get MSB/LSB parameters (time, speed)
  List<MsbLsbParamMapping> getMsbLsbParams();

  /// Whether this effect supports tempo sync
  bool get hasTempoSync => false;

  /// Tempo sync note select CC parameter (if hasTempoSync)
  CCParam? get tempoSyncParam => null;
}
```

#### Concrete Mappers

```dart
/// Wah parameter mapper
class WahParamMapper extends EffectParamMapper {
  @override
  String get modalTitle => 'Wah';

  @override
  String get pickerTitle => 'Select Wah Model';

  @override
  List<EffectModel> get models => WahModels.all;

  @override
  CCParam get selectParam => PodXtCC.wahSelect;

  @override
  List<EffectParamMapping> mapModelParams(EffectModel model) {
    // Wah models have no model-specific params (params list is empty)
    return [];
  }

  @override
  List<EffectParamMapping> getFixedParams() {
    return [
      EffectParamMapping(
        label: 'POSITION',
        ccParam: PodXtCC.wahLevel,
        formatter: (v) => '${(v * 100 / 127).round()}%',
      ),
    ];
  }

  @override
  List<MsbLsbParamMapping> getMsbLsbParams() => [];
}

/// Stomp parameter mapper
class StompParamMapper extends EffectParamMapper {
  @override
  String get modalTitle => 'Stomp';

  @override
  String get pickerTitle => 'Select Stomp Effect';

  @override
  List<EffectModel> get models => StompModels.all;

  @override
  CCParam get selectParam => PodXtCC.stompSelect;

  @override
  List<EffectParamMapping> mapModelParams(EffectModel model) {
    // Generic CC params for stomp: stompParam2 through stompParam6
    final ccParams = [
      PodXtCC.stompParam2,  // Index 0
      PodXtCC.stompParam3,  // Index 1
      PodXtCC.stompParam4,  // Index 2
      PodXtCC.stompParam5,  // Index 3
      PodXtCC.stompParam6,  // Index 4
    ];

    // Map each parameter from the model to its corresponding CC
    return List.generate(
      model.params.length,
      (i) => EffectParamMapping(
        label: model.params[i].name.toUpperCase(),
        ccParam: ccParams[i],
        formatter: _getFormatterForParam(model.params[i].name),
        minValue: model.params[i].minValue,
        maxValue: model.params[i].maxValue,
      ),
    );
  }

  String Function(int) _getFormatterForParam(String paramName) {
    final lower = paramName.toLowerCase();

    // Smart formatters based on parameter name patterns
    if (lower.contains('level') ||
        lower.contains('mix') ||
        lower.contains('blend') ||
        lower.contains('sustain') ||
        lower.contains('depth')) {
      return (v) => '${(v * 100 / 127).round()}%';
    }

    if (lower.contains('gain') || lower.contains('drive')) {
      return (v) => '${(v * 100 / 127).round()}%';
    }

    if (lower.contains('tone') || lower.contains('treble') || lower.contains('bass')) {
      return (v) => '${(v * 100 / 127).round()}%';
    }

    if (lower.contains('freq')) {
      // Frequency - could be more sophisticated with actual Hz mapping
      return (v) => '${(v * 100 / 127).round()}%';
    }

    if (lower.contains('wave')) {
      // Wave type - raw value
      return (v) => '$v';
    }

    // Default: percentage
    return (v) => '${(v * 100 / 127).round()}%';
  }

  @override
  List<EffectParamMapping> getFixedParams() => [];

  @override
  List<MsbLsbParamMapping> getMsbLsbParams() => [];
}

/// Mod parameter mapper
class ModParamMapper extends EffectParamMapper {
  @override
  String get modalTitle => 'Modulation';

  @override
  String get pickerTitle => 'Select Modulation Effect';

  @override
  List<EffectModel> get models => ModModels.all;

  @override
  CCParam get selectParam => PodXtCC.modSelect;

  @override
  List<EffectParamMapping> mapModelParams(EffectModel model) {
    final ccParams = [
      PodXtCC.modParam2,
      PodXtCC.modParam3,
      PodXtCC.modParam4,
    ];

    return List.generate(
      model.params.length,
      (i) => EffectParamMapping(
        label: model.params[i].name.toUpperCase(),
        ccParam: ccParams[i],
        formatter: _getFormatterForParam(model.params[i].name),
        minValue: model.params[i].minValue,
        maxValue: model.params[i].maxValue,
      ),
    );
  }

  String Function(int) _getFormatterForParam(String paramName) {
    // Similar to stomp but with mod-specific patterns
    final lower = paramName.toLowerCase();

    if (lower.contains('feedback')) {
      return (v) => '${(v * 100 / 127).round()}%';
    }

    if (lower.contains('depth') || lower.contains('manual')) {
      return (v) => '${(v * 100 / 127).round()}%';
    }

    if (lower.contains('tone') || lower.contains('bass') || lower.contains('treble')) {
      return (v) => '${(v * 100 / 127).round()}%';
    }

    if (lower.contains('wave')) {
      return (v) => '$v';
    }

    if (lower.contains('q')) {
      return (v) => '${(v * 100 / 127).round()}%';
    }

    return (v) => '${(v * 100 / 127).round()}%';
  }

  @override
  List<EffectParamMapping> getFixedParams() {
    return [
      EffectParamMapping(
        label: 'MIX',
        ccParam: PodXtCC.modMix,
        formatter: (v) => '${(v * 100 / 127).round()}%',
      ),
    ];
  }

  @override
  List<MsbLsbParamMapping> getMsbLsbParams() {
    return [
      MsbLsbParamMapping(
        label: 'SPEED',
        msbParam: PodXtCC.modSpeedMsb,
        lsbParam: PodXtCC.modSpeedLsb,
        formatter: (v) => '${(v / 100).toStringAsFixed(2)} Hz',
        maxValue: 16383,
      ),
    ];
  }

  @override
  bool get hasTempoSync => true;

  @override
  CCParam get tempoSyncParam => PodXtCC.modNoteSelect;
}

/// Delay parameter mapper
class DelayParamMapper extends EffectParamMapper {
  @override
  String get modalTitle => 'Delay';

  @override
  String get pickerTitle => 'Select Delay Effect';

  @override
  List<EffectModel> get models => DelayModels.all;

  @override
  CCParam get selectParam => PodXtCC.delaySelect;

  @override
  List<EffectParamMapping> mapModelParams(EffectModel model) {
    final ccParams = [
      PodXtCC.delayParam2,
      PodXtCC.delayParam3,
      PodXtCC.delayParam4,
    ];

    return List.generate(
      model.params.length,
      (i) => EffectParamMapping(
        label: model.params[i].name.toUpperCase(),
        ccParam: ccParams[i],
        formatter: _getFormatterForParam(model.params[i].name),
        minValue: model.params[i].minValue,
        maxValue: model.params[i].maxValue,
      ),
    );
  }

  String Function(int) _getFormatterForParam(String paramName) {
    final lower = paramName.toLowerCase();

    if (lower.contains('feedback')) {
      return (v) => '${(v * 100 / 127).round()}%';
    }

    if (lower.contains('bass') || lower.contains('treble') || lower.contains('tone')) {
      return (v) => '${(v * 100 / 127).round()}%';
    }

    if (lower.contains('flutter') || lower.contains('drive')) {
      return (v) => '${(v * 100 / 127).round()}%';
    }

    if (lower.contains('heads') || lower.contains('bits')) {
      return (v) => '$v';
    }

    if (lower.contains('speed') || lower.contains('depth')) {
      return (v) => '${(v * 100 / 127).round()}%';
    }

    if (lower.contains('offset') || lower.contains('spread')) {
      return (v) => '${(v * 100 / 127).round()}%';
    }

    return (v) => '${(v * 100 / 127).round()}%';
  }

  @override
  List<EffectParamMapping> getFixedParams() {
    return [
      EffectParamMapping(
        label: 'MIX',
        ccParam: PodXtCC.delayMix,
        formatter: (v) => '${(v * 100 / 127).round()}%',
      ),
    ];
  }

  @override
  List<MsbLsbParamMapping> getMsbLsbParams() {
    return [
      MsbLsbParamMapping(
        label: 'TIME',
        msbParam: PodXtCC.delayTimeMsb,
        lsbParam: PodXtCC.delayTimeLsb,
        formatter: (v) => '${v}ms',
        maxValue: 16383,
      ),
    ];
  }

  @override
  bool get hasTempoSync => true;

  @override
  CCParam get tempoSyncParam => PodXtCC.delayNoteSelect;
}

/// Reverb parameter mapper
class ReverbParamMapper extends EffectParamMapper {
  @override
  String get modalTitle => 'Reverb';

  @override
  String get pickerTitle => 'Select Reverb Effect';

  @override
  List<EffectModel> get models => ReverbModels.all;

  @override
  CCParam get selectParam => PodXtCC.reverbSelect;

  @override
  List<EffectParamMapping> mapModelParams(EffectModel model) {
    // Reverb has named parameters (not generic)
    // But all reverbs share the same 4 params (empty params list in model)
    return [];
  }

  @override
  List<EffectParamMapping> getFixedParams() {
    // All reverbs have the same 3 parameters
    // NOTE: Reverb LEVEL is excluded - it's controlled by the main screen reverb knob
    return [
      EffectParamMapping(
        label: 'DECAY',
        ccParam: PodXtCC.reverbDecay,
        formatter: (v) => '${(v * 100 / 127).round()}%',
      ),
      EffectParamMapping(
        label: 'TONE',
        ccParam: PodXtCC.reverbTone,
        formatter: (v) => '${(v * 100 / 127).round()}%',
      ),
      EffectParamMapping(
        label: 'PRE DELAY',
        ccParam: PodXtCC.reverbPreDelay,
        formatter: (v) => '${v}ms',
      ),
    ];
  }

  @override
  List<MsbLsbParamMapping> getMsbLsbParams() => [];
}
```

### 2. `lib/ui/widgets/effect_modal.dart`

```dart
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
  late Map<CCParam, int> _paramValues;  // Cache of all parameter values
  StreamSubscription<EditBuffer>? _editBufferSubscription;

  @override
  void initState() {
    super.initState();
    _loadValues();

    _editBufferSubscription = widget.podController.onEditBufferChanged.listen((buffer) {
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
      _selectedModelId = widget.podController.getParameter(widget.mapper.selectParam);

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
        _paramValues[param.ccParam] = widget.podController.getParameter(param.ccParam);
      }

      // Load fixed params
      final fixedParams = widget.mapper.getFixedParams();
      for (final param in fixedParams) {
        _paramValues[param.ccParam] = widget.podController.getParameter(param.ccParam);
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

  void _onModelChanged(int newModelId) {
    setState(() => _selectedModelId = newModelId);
    widget.podController.setParameter(widget.mapper.selectParam, newModelId);
    // Reload values for new model
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

          const SizedBox(height: 20),

          // Dynamic LCD knob array section
          if (msbLsbParams.isNotEmpty || modelParams.isNotEmpty || fixedParams.isNotEmpty)
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
```

### 3. Create `lib/ui/widgets/lcd_knob_array.dart`

**NEW REQUIREMENT**: Replace rotary knobs with POD XT LCD-style parameter display.

#### Design Requirements:
- Use `dot_matrix_lcd.dart` as base
- 3-line display for each parameter:
  - **Top line**: Parameter label (uppercase)
  - **Center**: Orange pixelated LCD-style interactive knob (visual indicator)
  - **Bottom line**: Current value with formatter
- Orange marker on active parameter (inverted font color)
- Authentic LCD aesthetic matching POD XT/XT Pro hardware
- Support 14-bit values for MSB/LSB parameters (0-16383)

#### Implementation:

```dart
/// LCD-style parameter knob resembling POD XT/XT Pro LCD display
class LcdKnob extends StatelessWidget {
  final String label;
  final int value;
  final int minValue;
  final int maxValue;
  final ValueChanged<int> onValueChanged;
  final String Function(int) valueFormatter;
  final bool isActive;  // Whether this knob is currently selected/active
  final double width;
  final double height;

  const LcdKnob({
    super.key,
    required this.label,
    required this.value,
    required this.onValueChanged,
    this.minValue = 0,
    this.maxValue = 127,
    required this.valueFormatter,
    this.isActive = false,
    this.width = 100,
    this.height = 80,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedValue = (value - minValue) / (maxValue - minValue);

    return GestureDetector(
      onPanUpdate: (details) => _handleDrag(details),
      onTap: () => _setActive(),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(
            color: isActive
                ? const Color(0xFFFF7A00)  // Orange when active
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Label (inverted when active)
            _DotText(
              label,
              size: 10,
              color: isActive
                  ? Colors.black
                  : const Color(0xFFFF7A00),
              backgroundColor: isActive
                  ? const Color(0xFFFF7A00)
                  : Colors.transparent,
            ),
            const SizedBox(height: 4),
            // LCD knob visualization (arc/bar showing value)
            _LcdKnobIndicator(
              value: normalizedValue,
              size: 30,
              isActive: isActive,
            ),
            const SizedBox(height: 4),
            // Value display
            _DotText(
              valueFormatter(value),
              size: 10,
              color: const Color(0xFFFF7A00),
            ),
          ],
        ),
      ),
    );
  }

  void _handleDrag(DragUpdateDetails details) {
    // Vertical drag to change value
    const sensitivity = 2.0;
    final steps = (-details.delta.dy / sensitivity).round();
    if (steps != 0) {
      final newValue = (value + steps).clamp(minValue, maxValue);
      onValueChanged(newValue);
    }
  }

  void _setActive() {
    // Mark this knob as active (for navigation)
  }
}

/// Renders pixelated LCD-style knob indicator (arc or bar)
class _LcdKnobIndicator extends StatelessWidget {
  final double value;  // 0.0 to 1.0
  final double size;
  final bool isActive;

  const _LcdKnobIndicator({
    required this.value,
    required this.size,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _LcdKnobPainter(
        value: value,
        color: isActive
            ? const Color(0xFFFF7A00)
            : const Color(0xFFCC5E00),  // Dimmer when inactive
      ),
    );
  }
}

/// Painter for LCD knob - draws pixelated arc or horizontal bar
class _LcdKnobPainter extends CustomPainter {
  final double value;
  final Color color;

  _LcdKnobPainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    // Draw pixelated arc segments (11 segments for LCD look)
    const segmentCount = 11;
    const arcSweep = 270.0 * math.pi / 180.0;
    const startAngle = 135.0 * math.pi / 180.0;

    final filledSegments = (value * segmentCount).round();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (int i = 0; i < filledSegments; i++) {
      final angle = startAngle + (i / segmentCount) * arcSweep;
      final x = center.dx + math.cos(angle) * radius;
      final y = center.dy + math.sin(angle) * radius;

      // Draw pixelated dot (2x2 pixels)
      canvas.drawRect(
        Rect.fromLTWH(x - 1, y - 1, 2, 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_LcdKnobPainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.color != color;
  }
}

/// Dot-matrix text matching DotMatrixLCD style
class _DotText extends StatelessWidget {
  final String text;
  final double size;
  final Color color;
  final Color? backgroundColor;

  const _DotText(
    this.text, {
    required this.size,
    required this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: backgroundColor != null
          ? const EdgeInsets.symmetric(horizontal: 4, vertical: 2)
          : EdgeInsets.zero,
      color: backgroundColor,
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Doto',
          fontWeight: FontWeight.w600,
          fontSize: size,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Array of LCD knobs arranged horizontally
class LcdKnobArray extends StatefulWidget {
  final List<LcdKnobConfig> knobs;
  final EdgeInsets padding;

  const LcdKnobArray({
    super.key,
    required this.knobs,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  });

  @override
  State<LcdKnobArray> createState() => _LcdKnobArrayState();
}

class _LcdKnobArrayState extends State<LcdKnobArray> {
  int _activeIndex = 0;

  @override
  Widget build(BuildContext context) {
    return DotMatrixLCD(
      padding: widget.padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(widget.knobs.length, (index) {
          final config = widget.knobs[index];
          return LcdKnob(
            label: config.label,
            value: config.value,
            minValue: config.minValue,
            maxValue: config.maxValue,
            onValueChanged: config.onValueChanged,
            valueFormatter: config.valueFormatter,
            isActive: index == _activeIndex,
            width: 100,
            height: 80,
          );
        }),
      ),
    );
  }
}

/// Configuration for a single LCD knob
class LcdKnobConfig {
  final String label;
  final int value;
  final int minValue;
  final int maxValue;
  final ValueChanged<int> onValueChanged;
  final String Function(int) valueFormatter;

  const LcdKnobConfig({
    required this.label,
    required this.value,
    required this.onValueChanged,
    this.minValue = 0,
    this.maxValue = 127,
    required this.valueFormatter,
  });
}
```

### 4. Update `lib/ui/screens/main_screen.dart`

Replace all effect modal calls:

```dart
void _showWahModal() {
  showPodModal(
    context: context,
    title: WahParamMapper().modalTitle,
    child: EffectModal(
      podController: widget.podController,
      isConnected: _isConnected,
      settings: widget.settings,
      mapper: WahParamMapper(),
    ),
  );
}

void _showStompModal() {
  showPodModal(
    context: context,
    title: StompParamMapper().modalTitle,
    child: EffectModal(
      podController: widget.podController,
      isConnected: _isConnected,
      settings: widget.settings,
      mapper: StompParamMapper(),
    ),
  );
}

void _showModModal() {
  showPodModal(
    context: context,
    title: ModParamMapper().modalTitle,
    child: EffectModal(
      podController: widget.podController,
      isConnected: _isConnected,
      settings: widget.settings,
      mapper: ModParamMapper(),
    ),
  );
}

void _showDelayModal() {
  showPodModal(
    context: context,
    title: DelayParamMapper().modalTitle,
    child: EffectModal(
      podController: widget.podController,
      isConnected: _isConnected,
      settings: widget.settings,
      mapper: DelayParamMapper(),
    ),
  );
}

void _showReverbModal() {
  showPodModal(
    context: context,
    title: ReverbParamMapper().modalTitle,
    child: EffectModal(
      podController: widget.podController,
      isConnected: _isConnected,
      settings: widget.settings,
      mapper: ReverbParamMapper(),
    ),
  );
}
```

## Special Cases Handling

### 1. MSB/LSB Parameters (14-bit values)

**Used for:**
- Mod Speed: `modSpeedMsb` + `modSpeedLsb`
- Delay Time: `delayTimeMsb` + `delayTimeLsb`

**Implementation:**
- Display as single knob with range 0-16383
- Split into MSB/LSB on send: `msb = (value >> 7) & 0x7F`, `lsb = value & 0x7F`
- Combine on receive: `combined = (msb << 7) | lsb`
- Send both CC messages when value changes

**Formatter Examples:**
- Speed: `(v) => '${(v / 100).toStringAsFixed(2)} Hz'`
- Time: `(v) => '${v}ms'`

### 2. Tempo Sync (Note Duration)

**Used for:**
- Mod: `modNoteSelect`
- Delay: `delayNoteSelect`

**Implementation (Phase 2):**
- Add toggle button: "Tempo Sync On/Off"
- When ON: Replace time/speed knob with note duration dropdown
- Use `NoteDurations.all` from effect_models.dart
- When OFF: Show normal time/speed knob

**For initial implementation:** Skip tempo sync, just show time/speed knob

### 3. No Parameters (Reverb models)

All reverb models share the same 4 fixed parameters (Decay, Tone, Pre Delay, Level), so:
- `mapModelParams()` returns empty list
- `getFixedParams()` returns the 4 reverb params
- Model selector changes reverb type, knobs stay the same

### 4. Pack Identification (FX Junkie)

Already handled by `EffectModelSelector`:
- `EffectModel.pack` field identifies pack ('FX', 'BX', etc.)
- Grid view groups by pack with color coding
- List view shows pack badge

## Migration Steps

### Phase 1: Core Implementation
1. ⏳ Create `effect_param_mappers.dart` with base classes and all 5 mappers
2. ⏳ Create `lcd_knob_array.dart` with LCD-style parameter knobs (replaces rotary knobs)
3. ⏳ Create `effect_modal.dart` with dynamic parameter generation using LCD knobs
4. ⏳ Update `main_screen.dart` to use EffectModal for all 5 effects
5. ⏳ Delete old modal files: wah_modal.dart, stomp_modal.dart, mod_modal.dart, delay_modal.dart, reverb_modal.dart
6. ⏳ Remove reverb LEVEL knob from ReverbParamMapper (already on main screen)

### Phase 2: Advanced Features (Future)
- Tempo sync toggle and note duration selector
- More sophisticated formatters (actual Hz/ms calculations from MIDI values)
- Animation when changing models
- Parameter presets/favorites

### Phase 3: Testing
- Test all 5 effect types
- Test model changes (verify parameters update correctly)
- Test parameter value persistence across modal reopens
- Test with hardware POD (verify MIDI CC sent correctly)
- Test MSB/LSB parameters (mod speed, delay time)
- Test edge cases: empty params, max params, FX pack models

## Benefits Summary

✅ **95% less code**: One modal instead of 5 separate modals
✅ **Consistency**: Same UX across all effect types
✅ **Maintainability**: Parameter logic in one place
✅ **Flexibility**: Easy to add new effect types or parameters
✅ **Type Safety**: Strongly typed parameter mappings
✅ **Dynamic**: Automatically adapts to each model's parameter count
✅ **Reusable**: Mapper pattern can be extended to other modals
✅ **DRY**: No duplicate code
✅ **Future-proof**: Easy to add tempo sync, presets, etc.

## Open Questions / Decisions Needed

1. **MSB/LSB formatter precision**: How should we convert MIDI values to actual Hz/ms?
   - Option A: Direct mapping (0-16383 = 0-16383ms)
   - Option B: Logarithmic/exponential scaling for musically useful ranges
   - **Recommendation**: Check pod-ui source for exact formulas

2. **Tempo sync implementation**: Phase 1 or Phase 2?
   - **Recommendation**: Phase 2 (not blocking for basic functionality)

3. **Parameter ordering**: Model params first or fixed params first?
   - **Recommendation**: MSB/LSB first, then model params, then fixed params (matches hardware)

4. **Knob size in modal**: Current 60, adjust for multiple knobs?
   - **Recommendation**: Keep 60, use Wrap for responsive layout

## Success Criteria

- [ ] All 5 effect modals working with EffectModal
- [ ] Model selection updates parameters correctly
- [ ] Parameter changes send correct MIDI CC
- [ ] Values persist across modal reopens
- [ ] MSB/LSB parameters work correctly
- [ ] FX pack models display correctly in picker
- [ ] No analyzer warnings
- [ ] Clean git history (one feature branch)
