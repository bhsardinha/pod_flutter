/// Reusable value formatting utilities for the POD XT Pro app.
///
/// Contains functions for formatting MIDI values, program numbers,
/// and dB conversions used throughout the UI.

library;

/// Format a MIDI value (0-127) as a 0.0-10.0 scale for display on knobs.
///
/// Example:
/// - 0 → "0.0"
/// - 64 → "5.0"
/// - 127 → "10.0"
String formatKnobValue(int value) {
  final scaled = (value / 127.0 * 10.0);
  return scaled.toStringAsFixed(1);
}

/// Format a program number (0-127) as a bank/letter string.
///
/// Examples:
/// - 0 → "01A"
/// - 1 → "01B"
/// - 4 → "02A"
/// - 127 → "32D"
String formatProgramName(int program) {
  final bank = (program ~/ 4) + 1;
  final letter = String.fromCharCode('A'.codeUnitAt(0) + (program % 4));
  return '${bank.toString().padLeft(2, '0')}$letter';
}

/// Format a MIDI value (0-127) as a percentage (0-100%).
///
/// Example:
/// - 0 → "0%"
/// - 64 → "50%"
/// - 127 → "100%"
String formatPercentage(int midiValue) {
  final percent = (midiValue * 100 / 127).round();
  return '$percent%';
}

/// Format a dB value with sign.
///
/// Examples:
/// - 0.0 → "0.0dB"
/// - 6.3 → "+6.3dB"
/// - -3.2 → "-3.2dB"
String formatDb(double db) {
  final sign = db > 0 ? '+' : '';
  return '$sign${db.toStringAsFixed(1)}dB';
}

/// Convert MIDI value (0-127) to dB (-12.8 to +12.6).
///
/// Formula from pod-ui: dB = (25.4 / 127.0) * midi - 12.8
///
/// Examples:
/// - 0 → -12.8 dB
/// - 64 → ~0.0 dB (center)
/// - 127 → +12.6 dB
double midiToDb(int midi) {
  return (25.4 / 127.0) * midi - 12.8;
}

/// Convert dB (-12.8 to +12.6) to MIDI value (0-127).
///
/// Formula: midi = (dB + 12.8) * 127.0 / 25.4
///
/// Examples:
/// - -12.8 dB → 0
/// - 0.0 dB → ~64
/// - +12.6 dB → 127
int dbToMidi(double db) {
  return ((db + 12.8) * 127.0 / 25.4).round().clamp(0, 127);
}
