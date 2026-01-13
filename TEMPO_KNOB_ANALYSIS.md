# Tempo Knob Implementation Analysis & Issues

## Date
January 13, 2026

## Problem Statement
The tempo-based knob for delay time has multiple critical issues:
1. Wrong value calculations (hardware 2000ms shows as 16383ms in app)
2. Inverted division ordering (counter-intuitive)
3. Wrong knob type (270° limitation instead of free-spinning)

## Current Implementation Analysis

### File Structure
```
lib/protocol/effect_param_mappers.dart  - Format functions and parameter mappings
lib/ui/widgets/effect_modal.dart        - Effect modal with knob handling
lib/ui/widgets/lcd_knob_array.dart      - Knob widget implementation
lib/models/effect_models.dart           - NoteDurations definitions
lib/protocol/cc_map.dart                - MIDI CC parameter definitions
```

### MIDI Protocol (from pod-ui)

#### Delay Time Parameters
- **CC 31** (`delayNoteSelect`): Mode selector
  - `0` = MS mode (use MSB/LSB for milliseconds)
  - `1-13` = Tempo sync mode (note divisions)
- **CC 30** (`delayTimeMsb`): Time MSB (bits 7-13)
- **CC 62** (`delayTimeLsb`): Time LSB (bits 0-6)
- **14-bit range**: `0-16383`

#### Conversion Formula (from pod-ui config.rs)
```rust
"delay_time" => VirtualRangeControl {
    config: long!(0, 16383),
    format: Format::Data(FormatData {
        k: 1980.0/16383.0,   // slope
        b: 20.0,              // offset
        format: "{val:1.0f} ms".into()
    }),
}
```

**Forward conversion (MIDI → milliseconds):**
```
ms = (midi_value × 1980.0 / 16383.0) + 20.0
```

**Reverse conversion (milliseconds → MIDI):**
```
midi_value = (ms - 20.0) × 16383.0 / 1980.0
```

**Mapping verification:**
- MIDI `0` → `20ms`
- MIDI `16383` → `2000ms`

## Identified Issues

### Issue 1: Missing Conversion Formula

**Location:** `lib/protocol/effect_param_mappers.dart:9-20`

**Current code:**
```dart
String formatDelayTime(int value) {
  if (value >= 1 && value <= 13) {
    final duration = NoteDurations.byId(value);
    return duration?.name ?? 'Unknown';
  }

  // BUG: Displays raw MIDI value without conversion
  return '${value}ms';
}
```

**Problem:**
When `noteSelect=0` (MS mode), the knob value is the 14-bit MSB/LSB combined value (0-16383). This is displayed directly as milliseconds without applying the conversion formula.

**Example:**
- Hardware: 2000ms
- MIDI value: 16383
- Current display: "16383ms" ❌
- Correct display: "2000ms" ✓

**Fix:**
```dart
String formatDelayTime(int value) {
  if (value >= 1 && value <= 13) {
    final duration = NoteDurations.byId(value);
    return duration?.name ?? 'Unknown';
  }

  // Convert 14-bit MIDI value to milliseconds
  final ms = (value * 1980.0 / 16383.0) + 20.0;
  return '${ms.round()}ms';
}
```

### Issue 2: Wrong Max Value in Mapper

**Location:** `lib/protocol/effect_param_mappers.dart:395`

**Current code:**
```dart
MsbLsbParamMapping(
  label: 'TIME',
  msbParam: PodXtCC.delayNoteSelect,
  lsbParam: PodXtCC.delayTimeLsb,
  formatter: formatDelayTime,
  maxValue: 3000,  // ❌ WRONG
  isNoteSelectBased: true,
),
```

**Problem:**
The max value is set to `3000` (presumably thinking in milliseconds), but the knob value is actually a MIDI value that ranges from 0-16383.

**Fix:**
```dart
maxValue: 16383,  // Max 14-bit MIDI value
```

### Issue 3: Same Issues for Modulation Speed

**Location:** `lib/protocol/effect_param_mappers.dart:22-34`

**Current code:**
```dart
String formatModSpeed(int value) {
  if (value >= 1 && value <= 13) {
    final duration = NoteDurations.byId(value);
    return duration?.name ?? 'Unknown';
  }

  // Value represents Hz * 100 (e.g., 10 = 0.10Hz, 1140 = 11.40Hz)
  final hz = value / 100.0;
  return '${hz.toStringAsFixed(2)} Hz';
}
```

**Problem:**
This might also need a conversion formula. Need to verify with pod-ui for modulation speed encoding.

**Location:** `lib/protocol/effect_param_mappers.dart:299`
```dart
maxValue: 1140,  // Max Hz * 100 (11.4 Hz)
```

If the raw MIDI value is 0-16383, this needs to be `16383` with proper conversion formula.

### Issue 4: Inverted Division Ordering

**Location:** `lib/models/effect_models.dart:208-223`

**Current order (ID ascending = clockwise on knob):**
```
ID 1:  Whole           (1.0x)        ← slowest/longest
ID 2:  Dotted Half     (1.33x)
ID 3:  Half            (2.0x)
...
ID 12: Sixteenth       (16.0x)
ID 13: Sixteenth Tri   (24.0x)       ← fastest/shortest
```

**Problem:**
When MS values follow divisions (IDs 1-13 then jump to MS range), the ordering puts:
- Left/CCW: Whole note (slow/long delays)
- Right/CW: Sixteenth triplet → then jumps to 20ms

This is counter-intuitive because:
- Smaller ms = faster = should be CW
- Larger ms = slower = should be CCW

**Expected behavior:**
The knob should have faster/smaller values clockwise:
```
CCW ←                              → CW
2000ms ... 500ms ... Whole ... Sixteenth Tri ... 20ms
(slow)                                        (fast)
```

**Current behavior:**
```
CCW ←                              → CW
Whole ... Sixteenth Tri ... 20ms ... 2000ms
(slow)                                 (slow)
```

**Fix:**
Reverse the NoteDurations array ordering, or handle the ordering in the UI layer.

### Issue 5: Knob Has 270° Limitation

**Location:** `lib/ui/widgets/lcd_knob_array.dart:219-222`

**Current code:**
```dart
// Draw black dash indicator showing value position
// 270° sweep: 135° to 405° (0.0 = bottom-left, 0.5 = noon/top, 1.0 = bottom-right)
const startAngle = 135.0 * math.pi / 180.0; // Bottom-left (7:30)
const sweepRange = 270.0 * math.pi / 180.0; // 270° sweep
```

**Problem:**
The knob is designed as a traditional rotary potentiometer with a 270° rotation limit. The hardware knob is free-spinning with only value limits (20ms and 2000ms).

**Fix:**
The knob widget needs to:
1. Allow continuous rotation (no visual angle limits)
2. Stop changing values when reaching min (20ms) or max (2000ms)
3. Provide visual feedback when at limits

**Implementation approach:**
- Remove the 270° angle constraint from visualization
- Track accumulated rotation independently of angle
- Clamp value changes at min/max boundaries
- Show full 360° circle with indicator

### Issue 6: Gap Between Note Divisions and MS Values

**Location:** `lib/ui/widgets/effect_modal.dart:247-253`

**Current code:**
```dart
// Handle the gap between subdivisions (1-13) and MS/Hz values (20+ or 10+)
int adjustedValue = v;
if (v > 13 && v < minMsHzValue) {
  // Snap to minimum MS/Hz value
  adjustedValue = minMsHzValue;
}
```

**Problem:**
When using the knob, values 14-19 are invalid (there's a gap between note divisions and MS mode). The code snaps to 20, but this creates a dead zone that's confusing.

**Better approach:**
Map the knob position continuously without gaps:
- Positions 0-12: Note divisions (IDs 1-13)
- Position 13+: MS values (20-2000ms) mapped linearly

This requires changing how the knob value maps to actual parameter values.

## Note Duration Multipliers Explained

From pod-ui reference:
```rust
NOTE_DURATION = vec!(
    0.0,        // 0:  Off
    1.0,        // 1:  Whole Note
    4.0/3.0,    // 2:  Dotted Half Note (1.333)
    2.0,        // 3:  Half
    3.0,        // 4:  Half Note Triplet
    8.0/3.0,    // 5:  Dotted Quarter (2.667)
    4.0,        // 6:  Quarter
    6.0,        // 7:  Quarter Note Triplet
    16.0/3.0,   // 8:  Dotted Eighth (5.333)
    8.0,        // 9:  Eighth
    12.0,       // 10: Eighth Note Triplet
    32.0/3.0,   // 11: Dotted Sixteenth (10.667)
    16.0,       // 12: Sixteenth
    24.0,       // 13: Sixteenth Note Triplet
)
```

**These are NOT time duration multipliers!**

They represent **divisions per whole note** (how many times faster than a whole note):
- Whole note = 1 division per whole note
- Half note = 2 divisions per whole note
- Quarter = 4 divisions per whole note
- Eighth = 8 divisions per whole note
- Sixteenth = 16 divisions per whole note

**To calculate delay time from tempo:**
```
delay_ms = (60000 / BPM) / note_multiplier
```

Example at 120 BPM:
- Whole: (60000 / 120) / 1.0 = 500ms
- Quarter: (60000 / 120) / 4.0 = 125ms
- Eighth: (60000 / 120) / 8.0 = 62.5ms

**Current Flutter implementation matches pod-ui ✓**

## Summary of Required Changes

### Priority 1: Critical Bugs
1. **Fix `formatDelayTime()`**: Apply conversion formula for MS mode values
2. **Fix `formatModSpeed()`**: Verify and apply conversion formula if needed
3. **Fix max values**: Change from ms/Hz to 14-bit MIDI range (0-16383)

### Priority 2: UX Issues
4. **Reverse division ordering**: Make faster/smaller values go clockwise
5. **Fix knob visualization**: Remove 270° limitation, implement free-spinning
6. **Fix value gaps**: Smooth mapping between divisions and MS values

### Files to Modify
1. `lib/protocol/effect_param_mappers.dart` - Formatters and max values
2. `lib/models/effect_models.dart` - Note duration ordering
3. `lib/ui/widgets/lcd_knob_array.dart` - Knob visualization
4. `lib/ui/widgets/effect_modal.dart` - Value mapping logic

## Testing Checklist
- [ ] Hardware at 20ms → App shows 20ms
- [ ] Hardware at 2000ms → App shows 2000ms
- [ ] Hardware at 1000ms → App shows ~1000ms (verify exact value)
- [ ] Whole note at 120 BPM → Shows "Whole" not ms value
- [ ] Knob rotation: faster values go clockwise
- [ ] Knob can spin freely without angular limits
- [ ] Knob stops at 20ms minimum
- [ ] Knob stops at 2000ms maximum
- [ ] No gaps or dead zones while turning knob
- [ ] Modulation speed works correctly with same fixes
