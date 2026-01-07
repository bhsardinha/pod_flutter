/// EQ frequency mapping utilities for the POD XT Pro 4-band parametric EQ.
///
/// Each EQ band has different frequency ranges and stepped scaling rules:
/// - Band 1 (LOW): 50-690 Hz, +5 Hz per step
/// - Band 2 (LO MID): 50-6050 Hz, variable steps
/// - Band 3 (HI MID): 100-11300 Hz, 50/100 Hz steps
/// - Band 4 (HIGH): 500-9300 Hz, variable steps

library;

/// EQ frequency ranges for each band from pod-ui config
class EqFrequencyRanges {
  /// Band 1 (LOW): 50 Hz to 690 Hz
  static const eq1 = (min: 50.0, max: 690.0);

  /// Band 2 (LO MID): 50 Hz to 6050 Hz
  static const eq2 = (min: 50.0, max: 6050.0);

  /// Band 3 (HI MID): 100 Hz to 11300 Hz
  static const eq3 = (min: 100.0, max: 11300.0);

  /// Band 4 (HIGH): 500 Hz to 9300 Hz
  static const eq4 = (min: 500.0, max: 9300.0);
}

/// Format EQ frequency value with Hz or k suffix.
///
/// Examples:
/// - 50 → "50"
/// - 690 → "690"
/// - 1500 → "1.5k"
/// - 11300 → "11.3k"
String formatEqFreq(
  int midiValue,
  int band,
  ({double min, double max}) range,
) {
  final freq = midiEqFreqToHz(midiValue, band, range);
  if (freq >= 1000) {
    return '${(freq / 1000).toStringAsFixed(1)}k';
  }
  return '$freq';
}

/// Convert MIDI 0-127 EQ frequency value to Hz using stepped rules.
///
/// Each band has different stepping logic to match the POD XT Pro hardware:
///
/// **Band 1**: Start at 50 Hz, +5 Hz per step (max step 127 = 690 Hz)
///
/// **Band 2**: Variable steps:
/// - <130 Hz: +5 Hz per step
/// - 130-450 Hz: +10 Hz per step
/// - 450-2900 Hz: +50 Hz per step
/// - 2900-5800 Hz: +100 Hz per step
/// - ≥5800 Hz: +200 Hz per step
///
/// **Band 3**:
/// - <1700 Hz: +50 Hz per step
/// - ≥1700 Hz: +100 Hz per step
///
/// **Band 4**: Four lanes with arbitrary thresholds:
/// - <1300 Hz: +25 Hz per step
/// - 1300-2900 Hz: +50 Hz per step
/// - 2900-9100 Hz: +100 Hz per step
/// - ≥9100 Hz: +200 Hz per step
///
/// [midiValue]: MIDI value (0-127)
/// [band]: EQ band number (1-4)
/// [range]: Frequency range with min/max
///
/// Returns: Frequency in Hz
int midiEqFreqToHz(
  int midiValue,
  int band,
  ({double min, double max}) range,
) {
  // Ensure midiValue in [0,127]
  final steps = midiValue.clamp(0, 127);

  // Starting frequency depends on band (use provided range.min where appropriate)
  int freq;
  if (band == 1) {
    // Band 1: start 50 Hz, +5 Hz per step
    // Special-case: ensure maximum step (127) maps to 690 Hz
    if (steps >= 127) {
      return 690;
    }
    freq = 50 + steps * 5;
    return freq.clamp(range.min.toInt(), range.max.toInt());
  }

  // For bands 2-4 start from the band's minimum frequency
  freq = range.min.toInt();

  for (int i = 0; i < steps; i++) {
    int stepSize;
    if (band == 2) {
      // Band 2: 5Hz until <130, then 10Hz until <450, then 50Hz until <2900, then 100Hz afterwards
      if (freq < 130) {
        stepSize = 5;
      } else if (freq < 450) {
        stepSize = 10;
      } else if (freq < 2900) {
        stepSize = 50;
      } else if (freq < 5800) {
        stepSize = 100;
      } else {
        stepSize = 200;
      }
    } else if (band == 3) {
      // Band 3: 50Hz steps until <1700, then 100Hz
      stepSize = freq < 1700 ? 50 : 100;
    } else if (band == 4) {
      // Band 4: four lanes with arbitrary thresholds for manual tuning.
      // Lane thresholds are intentionally 'random' so you can adjust them.
      if (freq < 1300) {
        // lane 1: fine-grain first step
        stepSize = 25;
      } else if (freq < 2900) {
        // lane 2
        stepSize = 50;
      } else if (freq < 9100) {
        stepSize = 100;
      } else {
        stepSize = 200;
      }
    } else {
      // Fallback: linear logarithmic-ish step
      stepSize = 1;
    }

    freq += stepSize;
    // Cap at band's max
    if (freq >= range.max) {
      freq = range.max.toInt();
      break;
    }
  }

  return freq;
}
