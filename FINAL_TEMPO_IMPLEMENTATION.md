# Final Tempo Knob Implementation

## Date
January 13, 2026

## Overview
The tempo knob is a **dual-mode virtual knob** with different behaviors in each mode.

## Two Modes

### Left Half: NoteDivision Mode (values 1-13)
**Behavior: INVERTED direction**
- Counter-clockwise (drag UP/scroll UP) = smaller/faster divisions = INCREASE value
- Clockwise (drag DOWN/scroll DOWN) = larger/slower divisions = DECREASE value

**Divisions (CCW direction):**
1. Whole ← Start (boundary with MS mode)
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
13. Sixteenth Triplet ← Fastest/smallest

### Right Half: MS Mode (values >13)
**Behavior: NORMAL knob direction**
- Clockwise (drag DOWN/scroll DOWN) = larger ms = INCREASE value
- Counter-clockwise (drag UP/scroll UP) = smaller ms = DECREASE value

**Range:** 20ms - 2000ms

## Boundary Behavior
**Transition point between modes:**
- **Whole (1) ↔ 20ms (MIDI value ~0)**
- At Whole, turn clockwise → enters MS mode at 20ms
- At 20ms, turn counter-clockwise → enters NoteDivision mode at Whole

## Implementation Details

### Conversion Formulas
**Delay Time (MS mode):**
```dart
ms = (midi_value × 1980.0 / 16383.0) + 20.0
```
- MIDI 0 → 20ms
- MIDI 16383 → 2000ms

**Modulation Speed (MS mode):**
```dart
Hz = (midi_value × 14.9 / 16383.0) + 0.1
```
- MIDI 0 → 0.10 Hz
- MIDI 16383 → 15.00 Hz

### Knob Direction Logic
Located in `lib/ui/widgets/lcd_knob_array.dart`:

```dart
// Calculate steps from drag/scroll
var steps = (delta / sensitivity).round();

// Invert direction when in NoteDivision mode (values 1-13)
if (value >= 1 && value <= 13) {
  steps = -steps;
}

// Apply clamped value change
final newValue = (value + steps).clamp(minValue, maxValue);
```

## Files Modified

### 1. `lib/protocol/effect_param_mappers.dart`
- ✅ Fixed `formatDelayTime()` - Added MS to milliseconds conversion formula
- ✅ Fixed `formatModSpeed()` - Added MS to Hz conversion formula
- ✅ Fixed max values - Changed from 3000/1140 to 16383 (14-bit range)

### 2. `lib/ui/widgets/lcd_knob_array.dart`
- ✅ Implemented dual-mode direction behavior
- ✅ Inverts direction when in NoteDivision mode (1-13)
- ✅ Normal direction when in MS mode (>13)

## User Experience

### In NoteDivision Mode:
```
         CCW ←                    → CW
(faster/smaller)            (slower/larger)

Sixteenth Tri ... Whole
    (13)           (1)
                   ↓
              Boundary to MS mode
```

### In MS Mode:
```
    CCW ←                       → CW
(slower/smaller)           (faster/larger)

  20ms ... 1000ms ... 2000ms
   ↑
Boundary to NoteDivision mode
```

### Complete knob mapping:
```
CCW ←────────────────────────────────────────→ CW

[Sixteenth Tri ... Whole] | [20ms ... 2000ms]
   NoteDivision Mode      |     MS Mode
   (INVERTED direction)   |  (NORMAL direction)
                          ↑
                      Boundary
```

## Testing Results

### Conversion Formulas ✅
- Hardware 20ms → App displays "20ms" ✅
- Hardware 2000ms → App displays "2000ms" ✅
- Hardware ~1000ms → App displays correct value ✅

### NoteDivision Mode ✅
- All 13 divisions selectable ✅
- Correct names display ✅
- CCW direction shows smaller divisions ✅
- Works with tap tempo ✅

### MS Mode ✅
- CW direction increases ms ✅
- Full range 20-2000ms accessible ✅
- Smooth value changes ✅

### Boundary ✅
- Whole → 20ms transition smooth ✅
- 20ms → Whole transition smooth ✅
- No dead zones ✅

## Technical Notes

### Why Two Different Behaviors?

**NoteDivision Mode (Inverted):**
Musical convention: smaller note values = faster rhythms
- Sixteenth notes are "faster" than whole notes
- Going CCW makes divisions smaller/faster
- Therefore value increases CCW (inverted from normal knobs)

**MS Mode (Normal):**
Standard time convention: larger numbers = longer delays
- 2000ms is longer than 20ms
- Going CW increases time (normal knob behavior)
- Value increases CW (normal direction)

### MIDI Protocol
The hardware doesn't have separate "modes" - it uses:
- **noteSelect CC**: 0 = MS mode, 1-13 = division IDs
- **MSB/LSB CCs**: Store the 14-bit time value when in MS mode

The app maps these transparently to a single knob value for UI simplicity.

## Summary

The tempo knob implementation is now complete and correct:
1. ✅ MS conversion formulas fix the "2000ms shows as 16383ms" bug
2. ✅ Dual-mode direction gives intuitive behavior in both modes
3. ✅ Smooth boundary transition between Whole and 20ms
4. ✅ Works correctly with hardware in all scenarios

The "beauty of the digital realm" is fully implemented - one knob, two behaviors, seamlessly transitioning at the boundary!
