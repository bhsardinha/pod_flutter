/// Effect parameter mapping classes for unified effect modals
/// Maps effect models and their parameters to MIDI CC controls

library;

import 'package:pod_flutter/protocol/cc_map.dart';
import 'package:pod_flutter/models/effect_models.dart';

/// Format delay time - handles both note divisions (negative values) and MS mode (0+)
String formatDelayTime(int value) {
  // Negative values: Note subdivisions (inverted: -13 to -1)
  if (value < 0) {
    final duration = NoteDurations.byId(-value); // Convert back to positive ID
    return duration?.label ?? 'Unknown';
  }

  // Positive values: Milliseconds mode (0-16383)
  // Convert 14-bit MIDI value (0-16383) to milliseconds (20-2000)
  // Formula from pod-ui: ms = (value × 1980.0/16383.0) + 20.0
  // This maps: 0→20ms, 16383→2000ms
  final ms = (value * 1980.0 / 16383.0) + 20.0;
  return '${ms.round()}ms';
}

/// Format modulation speed - handles both note divisions (negative values) and Hz mode (0+)
String formatModSpeed(int value) {
  // Negative values: Note subdivisions (inverted: -13 to -1)
  if (value < 0) {
    final duration = NoteDurations.byId(-value); // Convert back to positive ID
    return duration?.label ?? 'Unknown';
  }

  // Positive values: Hz mode (0-16383)
  // Convert 14-bit MIDI value (0-16383) to Hz (0.1-15.0)
  // Formula from pod-ui: Hz = (value × 14.9/16383.0) + 0.1
  // This maps: 0→0.1Hz, 16383→15.0Hz
  final hz = (value * 14.9 / 16383.0) + 0.1;
  return '${hz.toStringAsFixed(2)} Hz';
}

/// Represents a parameter mapping from EffectParam to CC control
class EffectParamMapping {
  final String label; // Display label (from EffectParam.name or custom)
  final CCParam ccParam; // CC parameter to control
  final String Function(int) formatter; // Value display formatter
  final int minValue; // Min MIDI value (default 0)
  final int maxValue; // Max MIDI value (default 127)
  final int Function(int)?
      valueScaler; // Optional: transform value before sending

  const EffectParamMapping({
    required this.label,
    required this.ccParam,
    required this.formatter,
    this.minValue = 0,
    this.maxValue = 127,
    this.valueScaler,
  });
}

/// Special parameter type for time/speed parameters
/// These can be either MSB/LSB pairs OR single noteSelect parameters
class MsbLsbParamMapping {
  final String label;
  final CCParam msbParam;  // Also used as primary param for noteSelect-based controls
  final CCParam? lsbParam;  // Null for noteSelect-based controls
  final String Function(int) formatter;
  final int minValue;
  final int maxValue;
  final bool isNoteSelectBased;  // True if this uses noteSelect (negative values = divisions, 0+ = time/Hz)

  const MsbLsbParamMapping({
    required this.label,
    required this.msbParam,
    this.lsbParam,
    required this.formatter,
    this.minValue = 0,
    this.maxValue = 16383,
    this.isNoteSelectBased = false,
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
        msbParam: PodXtCC.modNoteSelect,
        lsbParam: PodXtCC.modSpeedLsb,  // Used for Hz mode
        formatter: formatModSpeed,
        minValue: -13,  // Negative values for note divisions (-13 to -1)
        maxValue: 16383,  // Max 14-bit MIDI value (converts to 15.0 Hz)
        isNoteSelectBased: true,
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

    final List<EffectParamMapping> mappings = [];
    for (int i = 0; i < model.params.length; i++) {
      final param = model.params[i];
      final paramName = param.name.toLowerCase();
      int Function(int)? scaler;

      if (paramName.contains('heads') || paramName.contains('bits')) {
        // Scale 0-8 knob value to 0-127 MIDI value
        // Based on pod-ui RangeConfig::Short edge algorithm:
        // scale = 128 / (8 - 0 + 1) = 16
        // MIDI = (step - 0) * 16, with special case: step >= 8 → 127
        // Maps: 0→0, 1→16, 2→32, 3→48, 4→64, 5→80, 6→96, 7→112, 8→127
        scaler = (v) {
          print('[DelayParamMapper] scaler: step $v → MIDI ${v >= 8 ? 127 : v * 16}');
          return v >= 8 ? 127 : v * 16;
        };
      }

      mappings.add(
        EffectParamMapping(
          label: param.name.toUpperCase(),
          ccParam: ccParams[i],
          formatter: _getFormatterForParam(param.name),
          minValue: param.minValue,
          maxValue: param.maxValue,
          valueScaler: scaler,
        ),
      );
    }
    return mappings;
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

    if (lower.contains('heads')) {
      // Heads parameter: knob value is already a step (0-8), just map to label
      return (v) {
        const labels = ['12--', '1-3-', '1--4', '-23-', '123-', '12-4', '1-34', '-234', '1234'];
        return labels[v.clamp(0, 8)];
      };
    }

    if (lower.contains('bits')) {
      // Bits parameter: knob value is already a step (0-8), just map to label
      return (v) {
        const labels = ['12', '11', '10', '9', '8', '7', '6', '5', '4'];
        return labels[v.clamp(0, 8)];
      };
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
        msbParam: PodXtCC.delayNoteSelect,
        lsbParam: PodXtCC.delayTimeLsb,  // Used for ms mode
        formatter: formatDelayTime,
        minValue: -13,  // Negative values for note divisions (-13 to -1)
        maxValue: 16383,  // Max 14-bit MIDI value (converts to 2000ms)
        isNoteSelectBased: true,
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
    // Spring reverbs (0-2) have [Dwell, Tone]
    // Other reverbs (3-14) have [Pre-Delay, Decay, Tone]
    // Map parameters based on their names to correct CC values
    final ccParams = model.id <= 2
        ? [
            PodXtCC.reverbDecay, // Index 0: Dwell (for springs)
            PodXtCC.reverbTone,  // Index 1: Tone (for springs)
          ]
        : [
            PodXtCC.reverbPreDelay, // Index 0: Pre-Delay (for others)
            PodXtCC.reverbDecay,    // Index 1: Decay (for others)
            PodXtCC.reverbTone,     // Index 2: Tone (for others)
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

    if (lower.contains('pre') && lower.contains('delay')) {
      return (v) => '${v}ms';
    }

    // Dwell, Decay, Tone - all percentage
    return (v) => '${(v * 100 / 127).round()}%';
  }

  @override
  List<EffectParamMapping> getFixedParams() {
    // All reverbs have LEVEL as a fixed parameter
    return [
      EffectParamMapping(
        label: 'LEVEL',
        ccParam: PodXtCC.reverbLevel,
        formatter: (v) => '${(v * 100 / 127).round()}%',
      ),
    ];
  }

  @override
  List<MsbLsbParamMapping> getMsbLsbParams() => [];
}
