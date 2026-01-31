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

/// Format 0-127 value as percentage (0%-100%)
String formatPercentage(int value) {
  final percent = (value / 127 * 100).round();
  return '$percent%';
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
  final List<String>? positionLabels;  // If present, renders as discrete positions (e.g., ["Slow", "Fast"])
  final List<int>? positionValues;     // Corresponding MIDI values for each position

  const MsbLsbParamMapping({
    required this.label,
    required this.msbParam,
    this.lsbParam,
    required this.formatter,
    this.minValue = 0,
    this.maxValue = 16383,
    this.isNoteSelectBased = false,
    this.positionLabels,
    this.positionValues,
  });

  /// Whether this is a discrete position parameter (2-position switch, etc.)
  bool get isPositionBased => positionLabels != null && positionValues != null;

  /// Get MIDI value for a specific position index (0, 1, etc.)
  int getPositionValue(int positionIndex) {
    if (!isPositionBased) return positionIndex;
    return positionValues![positionIndex.clamp(0, positionValues!.length - 1)];
  }

  /// Get position index from MIDI value
  int getPositionFromValue(int value) {
    if (!isPositionBased) return value;

    // Find closest position
    int closestIndex = 0;
    int closestDiff = (value - positionValues![0]).abs();

    for (int i = 1; i < positionValues!.length; i++) {
      final diff = (value - positionValues![i]).abs();
      if (diff < closestDiff) {
        closestDiff = diff;
        closestIndex = i;
      }
    }

    return closestIndex;
  }
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
  /// Optional model parameter for model-specific behavior
  List<MsbLsbParamMapping> getMsbLsbParams([EffectModel? model]);

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
  List<MsbLsbParamMapping> getMsbLsbParams([EffectModel? model]) => [];
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

  /// Get CC parameter indices for a specific effect, accounting for skip()
  List<CCParam> _getCCParamsForEffect(EffectModel model) {
    // Default CC params for stomp: stompParam2 through stompParam6
    final allParams = [
      PodXtCC.stompParam2,  // Index 0
      PodXtCC.stompParam3,  // Index 1
      PodXtCC.stompParam4,  // Index 2
      PodXtCC.stompParam5,  // Index 3
      PodXtCC.stompParam6,  // Index 4
    ];

    // Handle effects with skip() in pod-ui config
    switch (model.id) {
      case 15: // Dingo-Tron: skip().control("Sens").control("Q")
        return [allParams[1], allParams[2]]; // Skip param2, use param3 and param4
      case 17: // Seismik Synth: wave("Wave").skip().skip().control("Mix")
        return [allParams[0], allParams[3]]; // param2, skip param3/param4, param5
      case 18: // Double Bass: control("-1OCTG").control("-2OCTG").skip().control("Mix")
        return [allParams[0], allParams[1], allParams[3]]; // param2, param3, skip param4, param5
      case 21: // Saturn 5 Ring M: wave("Wave").skip().skip().control("Mix")
        return [allParams[0], allParams[3]]; // param2, skip param3/param4, param5
      case 28: // Bronze Master: control("Drive").wave("Tone").skip().control("Blend")
        return [allParams[0], allParams[1], allParams[3]]; // param2, param3, skip param4, param5
      case 29: // Sub Octaves: control("-1OCTG").control("-2OCTG").skip().control("Mix")
        return [allParams[0], allParams[1], allParams[3]]; // param2, param3, skip param4, param5
      default:
        // Most effects use sequential params
        return allParams.sublist(0, model.params.length);
    }
  }

  @override
  List<EffectParamMapping> mapModelParams(EffectModel model) {
    final ccParams = _getCCParamsForEffect(model);

    final mappings = <EffectParamMapping>[];
    for (int i = 0; i < model.params.length; i++) {
      final param = model.params[i];
      final paramName = param.name.toLowerCase();
      int Function(int)? scaler;
      int maxValue = param.maxValue;
      int minValue = param.minValue;

      if (paramName.contains('wave') && model.id != 24) {
        // Wave parameter: 8 discrete steps (0-7) mapped to MIDI
        // Based on pod-ui: steps!(0, 16, 32, 48, 64, 80, 96, 112)
        // Display as Wave 1-8
        // Exception: Synth Harmony (24) uses percentage for Wave, not discrete steps
        maxValue = 7;  // 8 steps: 0-7
        scaler = (v) {
          // Maps: 0→0, 1→16, 2→32, 3→48, 4→64, 5→80, 6→96, 7→112
          return v * 16;
        };
      } else if (paramName.contains('heel') || paramName.contains('toe')) {
        // Heel/Toe parameters: -24 to +24 semitones
        // Based on pod-ui heel_toe_to_midi function
        // Display: -24 to +24 → Internal: 0 to 48 → MIDI: special mapping
        scaler = (v) {
          // Convert display (-24 to +24) to internal (0 to 48)
          final internal = v + 24;

          // Convert internal to MIDI using pod-ui algorithm
          int midi;
          if (internal == 0) {
            midi = 0;
          } else if (internal == 48) {
            midi = 127;
          } else {
            midi = (internal - 1) * 2 + 18;
          }

          return midi;
        };
      } else if (paramName.contains('1m335') || paramName.contains('1457')) {
        // Synth Harmony octave parameters: 9 discrete steps (0-8) mapped to MIDI
        // Based on pod-ui: short!(@edge 0, 8) - same as Heads/Bits
        // Maps: 0→0, 1→16, 2→32, 3→48, 4→64, 5→80, 6→96, 7→112, 8→127
        scaler = (v) {
          return v >= 8 ? 127 : v * 16;
        };
      }

      mappings.add(
        EffectParamMapping(
          label: param.name.toUpperCase(),
          ccParam: ccParams[i],
          formatter: _getFormatterForParam(param.name, model.id),
          minValue: minValue,
          maxValue: maxValue,
          valueScaler: scaler,
        ),
      );
    }
    return mappings;
  }

  String Function(int) _getFormatterForParam(String paramName, int modelId) {
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
      // Wave parameter: knob value is already a step (0-7), display as Wave 1-8
      // Exception: Synth Harmony (24) uses percentage for Wave
      if (modelId == 24) {
        return (v) => '${(v * 100 / 127).round()}%';
      }
      return (v) => 'Wave ${v + 1}';
    }

    if (lower.contains('heel') || lower.contains('toe')) {
      // Heel/Toe parameters: display -24 to +24 with sign
      return (v) => v >= 0 ? '+$v' : '$v';
    }

    // Synth Harmony octave parameters: "1M335" and "1457"
    if (paramName == '1M335') {
      // 1M335: -1 oct, -maj 6th, -min 6th, -4th, unison, min 3rd, maj 3rd, 5th, 1 oct
      return (v) {
        const labels = ['-1 oct', '-maj 6th', '-min 6th', '-4th', 'unison', 'min 3rd', 'maj 3rd', '5th', '1 oct'];
        return labels[v.clamp(0, 8)];
      };
    }

    if (paramName == '1457') {
      // 1457: -1 oct, -5th, -4th, -2nd, unison, 4th, 5th, 7th, 1 oct
      return (v) {
        const labels = ['-1 oct', '-5th', '-4th', '-2nd', 'unison', '4th', '5th', '7th', '1 oct'];
        return labels[v.clamp(0, 8)];
      };
    }

    // Default: percentage
    return (v) => '${(v * 100 / 127).round()}%';
  }

  @override
  List<EffectParamMapping> getFixedParams() => [];

  @override
  List<MsbLsbParamMapping> getMsbLsbParams([EffectModel? model]) => [];
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
    // Rotary effects (8, 9) have Speed handled separately in getMsbLsbParams()
    // Only map Tone parameter here
    if (model.id == 8 || model.id == 9) {
      return [
        EffectParamMapping(
          label: 'TONE',
          ccParam: PodXtCC.modParam3, // Tone uses param3 (skip param2 for Speed)
          formatter: (v) => '${(v * 100 / 127).round()}%',
        ),
      ];
    }

    // All other mod effects use sequential params
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
      return formatPercentage;
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
  List<MsbLsbParamMapping> getMsbLsbParams([EffectModel? model]) {
    // Rotary effects (Drum + Horn, Drum) use 2-position speed (slow/fast)
    // Formula: Hz = (value × 14.9/16383.0) + 0.1
    // Inverse: value = (Hz - 0.1) × 16383.0 / 14.9
    // Slow (1.0 Hz) ≈ 990, Fast (8.0 Hz) ≈ 8684
    if (model != null && (model.id == 8 || model.id == 9)) {
      const slowValue = 990;   // ~1.0 Hz
      const fastValue = 8684;  // ~8.0 Hz

      return [
        MsbLsbParamMapping(
          label: 'SPEED',
          msbParam: PodXtCC.modNoteSelect,
          lsbParam: PodXtCC.modSpeedLsb,
          formatter: (v) {
            // This formatter is used for display - but with position labels,
            // the labels take precedence
            if (v < 2200) return 'SLOW';
            return 'FAST';
          },
          minValue: 0,      // UI position range: 0-1
          maxValue: 1,
          isNoteSelectBased: false,
          positionLabels: ['SLOW', 'FAST'],      // Display labels
          positionValues: [slowValue, fastValue], // Actual MIDI values
        ),
      ];
    }

    // All other mod effects use full-range speed
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
  List<MsbLsbParamMapping> getMsbLsbParams([EffectModel? model]) {
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
  List<MsbLsbParamMapping> getMsbLsbParams([EffectModel? model]) => [];
}
