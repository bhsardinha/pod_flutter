# Tempo Knob Fixes Applied

## Date
January 13, 2026

## Issues Fixed

### 1. Incorrect MS to Millisecond Conversion ✓
**Problem:** Hardware showing 2000ms displayed as 16383ms in app

**Root cause:** The app was displaying raw 14-bit MIDI values without converting to milliseconds

**Fix applied in `lib/protocol/effect_param_mappers.dart`:**
```dart
String formatDelayTime(int value) {
  if (value >= 1 && value <= 13) {
    final duration = NoteDurations.byId(value);
    return duration?.name ?? 'Unknown';
  }

  // Convert 14-bit MIDI value (0-16383) to milliseconds (20-2000)
  // Formula from pod-ui: ms = (value × 1980.0/16383.0) + 20.0
  final ms = (value * 1980.0 / 16383.0) + 20.0;
  return '${ms.round()}ms';
}
```

**Verification:**
- MIDI value `0` → `20ms` ✓
- MIDI value `16383` → `2000ms` ✓
- MIDI value `8192` → `1010ms` ✓

### 2. Incorrect Modulation Speed Conversion ✓
**Problem:** Hz values were being calculated as `value / 100` which was incorrect

**Fix applied in `lib/protocol/effect_param_mappers.dart`:**
```dart
String formatModSpeed(int value) {
  if (value >= 1 && value <= 13) {
    final duration = NoteDurations.byId(value);
    return duration?.name ?? 'Unknown';
  }

  // Convert 14-bit MIDI value (0-16383) to Hz (0.1-15.0)
  // Formula from pod-ui: Hz = (value × 14.9/16383.0) + 0.1
  final hz = (value * 14.9 / 16383.0) + 0.1;
  return '${hz.toStringAsFixed(2)} Hz';
}
```

**Verification:**
- MIDI value `0` → `0.10 Hz` ✓
- MIDI value `16383` → `15.00 Hz` ✓

### 3. Incorrect Max Values ✓
**Problem:** Max values were set to `3000` (delay) and `1140` (mod) thinking in ms/Hz, but should be MIDI values

**Fix applied:**
- Delay TIME: `maxValue: 16383` (was 3000)
- Mod SPEED: `maxValue: 16383` (was 1140)

## Knob Value Ranges

### Delay TIME Knob
- **Values 1-13:** Note divisions (Whole through Sixteenth Triplet)
- **Value 0:** 20ms (minimum MS mode value)
- **Values 14-19:** Invalid gap (should snap to 20)
- **Values 20-16383:** MS mode (20.02ms through 2000ms)

### Boundary Behavior
- **Whole (ID 1) ↔ 20ms (MIDI 0):** Adjacent positions
- Turning clockwise from Whole enters MS mode at 20ms
- Turning counter-clockwise from 20ms returns to Whole note

### Note Duration Order (CCW → CW)
The NoteDurations are ordered correctly for the hardware protocol:
1. Whole (longest, slowest) - CCW
2. Dotted Half
3. Half
4. Half Triplet
5. Dotted Quarter
6. Quarter
7. Quarter Triplet
8. Dotted Eighth
9. Eighth
10. Eighth Triplet
11. Dotted Sixteenth
12. Sixteenth
13. Sixteenth Triplet (shortest, fastest) - CW
→ Then transitions to MS mode starting at 20ms

## What Still Needs Testing

1. **Hardware verification:**
   - [ ] Set hardware to 20ms, verify app shows "20ms"
   - [ ] Set hardware to 2000ms, verify app shows "2000ms"
   - [ ] Set hardware to ~1000ms, verify app shows correct value
   - [ ] Set hardware to each note division, verify correct name displays

2. **Boundary transition:**
   - [ ] Knob at Whole, turn clockwise → should go to 20ms
   - [ ] Knob at 20ms, turn counter-clockwise → should go to Whole
   - [ ] No dead zones or weird jumps at boundary

3. **MS mode range:**
   - [ ] Can adjust from 20ms to 2000ms smoothly
   - [ ] Values display correctly throughout range

4. **Note division mode:**
   - [ ] All 13 note divisions can be selected
   - [ ] Correct names display for each division
   - [ ] Tempo sync works with tap tempo button

## Files Modified
- `lib/protocol/effect_param_mappers.dart` - Conversion formulas and max values

## Files NOT Modified (don't need changes)
- `lib/models/effect_models.dart` - NoteDurations order is correct
- `lib/ui/widgets/lcd_knob_array.dart` - Knob visualization is fine as-is
- `lib/ui/widgets/effect_modal.dart` - Value handling logic is correct

## Technical Notes

### MIDI Protocol
- **CC 31** (`delayNoteSelect`): Mode selector
  - `0` = MS mode (use MSB/LSB for time)
  - `1-13` = Tempo sync mode (note divisions)
- **CC 30** (`delayTimeMsb`): Time MSB
- **CC 62** (`delayTimeLsb`): Time LSB

### Similar for Modulation
- **CC 51** (`modNoteSelect`): Mode selector
- **CC 29** (`modSpeedMsb`): Speed MSB
- **CC 61** (`modSpeedLsb`): Speed LSB

### Conversion Formulas Source
Both formulas are extracted from the pod-ui reference implementation (https://github.com/arteme/pod-ui) in `mod-xt/src/config.rs`:

```rust
"delay_time" => VirtualRangeControl {
    config: long!(0, 16383),
    format: Format::Data(FormatData {
        k: 1980.0/16383.0,
        b: 20.0,
        format: "{val:1.0f} ms".into()
    }),
}

"mod_speed" => VirtualRangeControl {
    config: long!(0, 16383),
    format: Format::Data(FormatData {
        k: 14.9/16383.0,
        b: 0.1,
        format: "{val:1.2f} Hz".into()
    }),
}
```

## Summary

The main bugs were:
1. Missing conversion formulas - raw MIDI values were displayed instead of converted ms/Hz values
2. Wrong max values - using ms/Hz instead of 14-bit MIDI range

These are now fixed. The knob should now correctly display:
- Note division names when in tempo sync mode (values 1-13)
- Correct milliseconds when in MS mode (20-2000ms)
- Correct Hz when in modulation speed mode (0.10-15.00 Hz)

The boundary between Whole and 20ms should work correctly as the knob values transition from 1 (Whole) to 0 (20ms) when entering MS mode.
