# Tempo-Based Delay Parameter Research

## Research Date
January 13, 2026

## Purpose
Understanding the Line 6 POD XT Pro tempo-based delay implementation to fix calculation and UI behavior issues in the Flutter app.

## Hardware Specifications

### Delay Time Range
- **Minimum:** 20ms
- **Maximum:** 2000ms (2 seconds)
- **Resolution:** 1ms per step

### Delay Time Ranges by Knob Position (from Line 6 FAQs)
| Knob Position | Delay Time Range |
|---------------|------------------|
| 0 | 0-75ms |
| 1 | 76ms |
| 2 | 100ms |
| 3 | 146ms |
| 4 | 225ms |
| 5 | 350ms |
| 6 | 625ms |
| 7 | 850ms |
| 8 | 1400ms |
| 9 | 2600ms |

Note: The maximum shown here (2600ms) exceeds the stated 2000ms limit, suggesting different modes or parameters.

## Tempo Sync Mechanism

### How Hardware Tempo Works
1. User taps the TAP/TUNER footswitch multiple times to set tempo (BPM)
2. Delay and modulation effects can be synced to this tempo
3. Note division control selects which rhythmic subdivision the delay follows
4. Hardware calculates delay time automatically:

```
Delay Time (ms) = (60000 / BPM) × Note Division Multiplier
```

Example: At 120 BPM with quarter note:
```
Delay Time = (60000 / 120) × 0.25 = 125ms
```

## Note Division Values

Standard note divisions and their multipliers (relative to whole note):

| Division | Multiplier | At 120 BPM |
|----------|-----------|------------|
| Whole (1/1) | 1.0 | 2000ms |
| Half (1/2) | 0.5 | 1000ms |
| Quarter (1/4) | 0.25 | 500ms |
| Eighth (1/8) | 0.125 | 250ms |
| Sixteenth (1/16) | 0.0625 | 125ms |

### Dotted Notes
Multiply base note by 1.5:
- Dotted Quarter (1/4.) = 0.25 × 1.5 = 0.375
- Dotted Eighth (1/8.) = 0.125 × 1.5 = 0.1875

### Triplet Notes
Multiply base note by 2/3:
- Quarter Triplet (1/4T) = 0.25 × (2/3) = 0.1667
- Eighth Triplet (1/8T) = 0.125 × (2/3) = 0.0833

## Expected Hardware Behavior

### Knob Rotation Direction
- **Clockwise:** Shorter delays (faster subdivisions)
- **Counter-Clockwise:** Longer delays (slower subdivisions)

This is intuitive because:
- Smaller ms values = faster repeats
- Faster subdivisions (1/16, 1/8) should be clockwise
- Slower subdivisions (1/2, whole) should be counter-clockwise

### Knob Type
- **Free-spinning knob** (not 270° limited)
- Stops changing values when reaching either end (20ms or 2000ms)
- Can spin continuously within the valid range

## Current Implementation Issues

### 1. Incorrect Value Calculation
- Hardware at 2000ms shows as 16383ms in app
- UI allows setting values between 20ms and 3000ms
- Hardware values don't match app display

**Problem:** MIDI value to millisecond conversion is wrong

### 2. Inverted Division Order
- UI shows whole note first (left), faster divisions clockwise
- This is counter-intuitive: smaller ms = faster = should be clockwise
- Hardware likely has faster divisions clockwise

**Problem:** Division ordering is backwards

### 3. Wrong Knob Type
- UI knob has 270° limitation (typical rotary pot behavior)
- Hardware knob spins freely with value limits

**Problem:** Wrong knob widget implementation

## MIDI Protocol Information

### Relevant CC Parameters (from pod-ui reference)
- Delay effects use specific CC numbers for timing
- Note division control is a separate CC parameter
- "Note" control simultaneously updates "Delay Time" (confirmed in pod-ui v1.4.0)

### MIDI Value Encoding
POD XT uses 14-bit MIDI values (0-16383) for fine-grained control:
- Most parameters use two CC messages (MSB + LSB)
- 14-bit values give 16384 discrete steps
- Need to determine correct mapping formula

## Reference Implementation

### pod-ui (Rust/GTK Desktop App)
- Version 1.4.0 (January 2024) added tempo controls
- Quote: "PODxt, Bass PODxt: Tempo controls added. Now Delay & Modulation effect 'Note' control also set the 'Delay Time'/'Modulation speed' control like it is done in Line6 Edit."
- This confirms bidirectional relationship between note divisions and delay time

## Action Items for Fix

1. **Find correct MIDI mapping formula**
   - Examine current cc_map.dart for delay time parameter
   - Check if it's 7-bit (0-127) or 14-bit (0-16383)
   - Calculate correct formula: `ms = f(midi_value)` where ms ∈ [20, 2000]

2. **Reverse division order**
   - Find division array in code
   - Reverse ordering so faster divisions are clockwise

3. **Replace knob widget**
   - Remove 270° arc knob
   - Implement free-spinning knob with value-based limits
   - Ensure it stops at 20ms and 2000ms boundaries

4. **Verify tempo calculation**
   - Check BPM to ms conversion formula
   - Ensure note division multipliers are correct
   - Test against known hardware values

## Sources
- [pod-ui GitHub Repository](https://github.com/arteme/pod-ui)
- [POD XT Manual - Version 3 (Rev H)](https://line6.com/data/l/0a06000f1665c4447e238b4e76/application/pdf/PODxt%20Manual%20-%20Version%203%20(Rev%20H)%20-%20English.pdf)
- Line 6 POD/PODxt FAQs
- Musical tempo calculation standards
