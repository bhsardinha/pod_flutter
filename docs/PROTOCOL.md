# MIDI Protocol Documentation

## Overview

POD XT Pro uses standard MIDI for parameter control (CC messages) and Line 6 sysex for patch management. This document describes the complete protocol implementation.

---

## MIDI Basics

### Channel Messages

**Control Change (CC)**: `0xBn cc value`
- `n`: MIDI channel (0-15, typically 0)
- `cc`: Controller number (0-127)
- `value`: Parameter value (0-127)

**Program Change (PC)**: `0xCn program`
- `n`: MIDI channel (0-15, typically 0)
- `program`: Program number (0-127, 192-255)

### System Exclusive (Sysex)

**Format**: `F0 [manufacturer ID] [data...] F7`
- `F0`: Sysex start
- `F7`: Sysex end
- All bytes must be 7-bit (0-127)

**Line 6 Sysex**: `F0 00 01 0C [command...] [data...] F7`
- Manufacturer ID: `[00 01 0C]` (Line 6)

---

## POD XT Pro Device Identification

### Device IDs

```dart
line6ManufacturerId = [0x00, 0x01, 0x0C]
podXtFamily = 0x0003
podXtProMember = 0x0005
```

### Other POD Models (for reference)

| Model | Family | Member |
|-------|--------|--------|
| POD XT | 0x0003 | 0x0002 |
| POD XT Pro | 0x0003 | 0x0005 |
| POD XT Live | 0x0003 | 0x000A |
| Bass POD XT Pro | 0x0003 | 0x0007 |

---

## Control Change (CC) Parameters

### Parameter Definition

```dart
class CCParam {
  final String name;           // Internal name
  final int cc;                // MIDI CC number (0-127)
  final int? address;          // Buffer address (offset 32 + cc typically)
  final int minValue;          // Min value (default 0)
  final int maxValue;          // Max value (default 127)
  final bool inverted;         // Inverted logic (default false)
}
```

### Complete CC Map

#### Switches (Boolean Parameters)

| Name | CC | Address | Notes |
|------|----|---------| |------|
| Noise Gate Enable | 22 | 54 | |
| Wah Enable | 43 | 75 | |
| Stomp Enable | 25 | 57 | |
| Mod Enable | 50 | 82 | |
| Delay Enable | 28 | 60 | |
| Reverb Enable | 36 | 68 | |
| Amp Enable | 111 | 143 | **INVERTED** (0=on, 127=off) |
| Compressor Enable | 26 | 58 | |
| EQ Enable | 63 | 95 | |
| Tuner Enable | 69 | null | MIDI-only (CC 69 = 127 enables, CC 69 = 0 disables) |
| Volume Pedal Enable | 47 | null | MIDI-only |
| Loop Enable | 61 | 93 | |

#### Preamp

| Name | CC | Address | Range |
|------|----|---------||------|
| Amp Select | 12 | 44 | 0-106 (107 models) |
| Drive | 13 | 45 | 0-127 |
| Bass | 14 | 46 | 0-127 |
| Mid | 15 | 47 | 0-127 |
| Treble | 16 | 48 | 0-127 |
| Presence | 21 | 53 | 0-127 |
| Channel Volume | 17 | 49 | 0-127 |
| Bypass Volume | 105 | 137 | 0-127 |

#### Cabinet

| Name | CC | Address | Range |
|------|----|---------||------|
| Cab Select | 71 | 103 | 0-46 (47 models) |
| Mic Select | 70 | 102 | 0-3 (4 positions) |
| Room | 76 | 108 | 0-127 |

#### Noise Gate

| Name | CC | Address | Range |
|------|----|---------||------|
| Gate Threshold | 23 | 55 | 0-96 (-96dB to 0dB) |
| Gate Decay | 24 | 56 | 0-127 |

#### Compressor

| Name | CC | Address | Range |
|------|----|---------||------|
| Comp Threshold | 40 | 72 | 0-127 |
| Comp Gain | 41 | 73 | 0-127 |

#### Reverb

| Name | CC | Address | Range |
|------|----|---------||------|
| Reverb Select | 18 | 50 | 0-14 (15 models) |
| Reverb Decay | 19 | 51 | 0-127 |
| Reverb Tone | 20 | 52 | 0-127 |
| Reverb Pre-Delay | 37 | 69 | 0-127 (spring: dwell) |
| Reverb Level | 106 | 138 | 0-127 |
| Reverb Effect Select | 107 | 139 | 0-14 |

#### Stomp

| Name | CC | Address | Range |
|------|----|---------||------|
| Stomp Select | 75 | 107 | 0-30 (31 models) |
| Stomp Param 2 | 78 | 110 | Model-dependent |
| Stomp Param 3 | 79 | 111 | Model-dependent |
| Stomp Param 4 | 80 | 112 | Model-dependent |
| Stomp Param 5 | 81 | 113 | Model-dependent |
| Stomp Param 6 | 82 | 114 | Model-dependent |

**Special Stomp Parameter Encodings**:

Some stomp effects use discrete step parameters instead of continuous 0-127 values:

- **Wave parameters** (synth effects): 8 discrete steps
  - UI: Wave 1-8 (0-7)
  - MIDI: 0, 16, 32, 48, 64, 80, 96, 112
  - Formula: `midiValue = step * 16`
  - Exception: Synth Harmony uses percentage (0-127) for Wave

- **Octave parameters** (Synth Harmony): 9 discrete steps
  - UI: -1 oct, -maj 6th, -min 6th, -4th, unison, min 3rd, maj 3rd, 5th, 1 oct (0-8)
  - MIDI: 0, 16, 32, 48, 64, 80, 96, 112, 127
  - Formula: `midiValue = (step >= 8) ? 127 : step * 16`

- **Heel/Toe parameters** (Bender): 49 discrete steps
  - UI: -24 to +24 semitones
  - Internal: 0-48
  - MIDI special mapping:
    - 0 → 0 (MIDI)
    - 1-47 → `(internal - 1) * 2 + 18` (MIDI 18-110)
    - 48 → 127 (MIDI)

**Parameter Mapping Rules** (skip() offsets):

Some effects skip parameters, requiring offset calculations:

- **Dingo-Tron** (ID 15): `skip().control("Sens").control("Q")`
  - Param2 is skipped → Sens uses Param3, Q uses Param4

- **Seismik Synth** (ID 17): `wave("Wave").skip().skip().control("Mix")`
  - Param2=Wave, Param3-4 skipped → Mix uses Param5

- **Rotary Drum + Horn / Rotary Drum** (ID 8-9): `skip().control("Tone")`
  - Speed is controlled via modSpeed MSB/LSB (2-position switch)
  - Param2 is skipped → Tone uses Param3

**displayOrder Support**:

Some effects reorder parameters for display to match hardware layout:

- **Tube Drive** (ID 11): Display order [0, 2, 1, 3] → Drive, Gain, Treble, Bass
- **Blue Comp Treb** (ID 14): Display order [1, 0] → Sustain, Level

#### Modulation

| Name | CC | Address | Range |
|------|----|---------||------|
| Mod Select | 58 | 90 | 0-23 (24 models) |
| Mod Speed MSB | 51 | 83 | 14-bit (with LSB) |
| Mod Speed LSB | 52 | 84 | |
| Mod Note Select | 57 | 89 | Tempo sync |
| Mod Param 2 | 53 | 85 | Model-dependent |
| Mod Param 3 | 54 | 86 | Model-dependent |
| Mod Param 4 | 55 | 87 | Model-dependent |
| Mod Mix | 56 | 88 | 0-127 |

**Special Modulation Parameter Encodings**:

- **Rotary Speed** (Rotary Drum + Horn, Rotary Drum): 2-position switch
  - UI: "SLOW" or "FAST" (0-1)
  - MIDI: 990 (~1.0 Hz) or 8684 (~8.0 Hz)
  - Uses Mod Speed MSB/LSB (NOT a standard 0-127 parameter)
  - Threshold at ~2.0 Hz (2200 in 14-bit MIDI value)
  - Note Select (CC 51) must be 0 to enable MSB/LSB mode

#### Delay

| Name | CC | Address | Range |
|------|----|---------||------|
| Delay Select | 29 | 61 | 0-13 (14 models) |
| Delay Time MSB | 30 | 62 | 14-bit (with LSB) |
| Delay Time LSB | 31 | 63 | |
| Delay Note Select | 35 | 67 | Tempo sync |
| Delay Param 2 | 32 | 64 | Model-dependent |
| Delay Param 3 | 33 | 65 | Model-dependent |
| Delay Param 4 | 34 | 66 | Model-dependent |
| Delay Mix | 27 | 59 | 0-127 |

**Special Delay Parameter Encodings**:

- **Heads parameter** (Multi-Head, Echo Platter): 9 discrete steps
  - UI: "12--", "1-3-", "1--4", "-23-", "123-", "12-4", "1-34", "-234", "1234" (0-8)
  - MIDI: 0, 16, 32, 48, 64, 80, 96, 112, 127
  - Formula: `midiValue = (step >= 8) ? 127 : step * 16`

- **Bits parameter** (Low Rez): 9 discrete steps
  - UI: "12", "11", "10", "9", "8", "7", "6", "5", "4" (0-8)
  - MIDI: 0, 16, 32, 48, 64, 80, 96, 112, 127
  - Formula: `midiValue = (step >= 8) ? 127 : step * 16`

#### Digital I/O (D.I.)

| Name | CC | Address | Range |
|------|----|---------||------|
| D.I. Model | 108 | 140 | 0-15 |
| D.I. Delay | 109 | 141 | 0-127 |
| D.I. Xover | 110 | 142 | 0-127 |

#### Volume Pedal

| Name | CC | Address | Range |
|------|----|---------||------|
| Volume Pedal Level | 7 | null | MIDI-only |
| Volume Pedal Minimum | 46 | 78 | 0-127 |

#### Wah

| Name | CC | Address | Range |
|------|----|---------||------|
| Wah Select | 4 | 36 | 0-7 (8 models) |
| Wah Level | 1 | 33 | 0-127 (position) |

#### EQ (4-Band Parametric)

| Name | CC | Address | Range |
|------|----|---------||------|
| EQ 1 Freq | 114 | 146 | 0-127 |
| EQ 1 Gain | 115 | 147 | 0-127 (±15dB) |
| EQ 2 Freq | 116 | 148 | 0-127 |
| EQ 2 Gain | 117 | 149 | 0-127 (±15dB) |
| EQ 3 Freq | 118 | 150 | 0-127 |
| EQ 3 Gain | 119 | 151 | 0-127 (±15dB) |
| EQ 4 Freq | 120 | 152 | 0-127 |
| EQ 4 Gain | 121 | 153 | 0-127 (±15dB) |

#### Tempo

| Name | CC | Address | Range |
|------|----|---------||------|
| Tempo MSB | 89 | null | 14-bit (300-2400 = 30.0-240.0 BPM) |
| Tempo LSB | 90 | null | |

#### Tweaks

| Name | CC | Address | Range |
|------|----|---------||------|
| Tweak Param | 1 | 33 | 0-127 |
| Pedal Assign | 64 | 96 | 0-127 |

### 14-Bit Parameters

Some parameters use two CCs for 14-bit precision:

**Encoding**:
```dart
// Encode 14-bit value to two 7-bit values
msb = (value >> 7) & 0x7F;  // Upper 7 bits
lsb = value & 0x7F;          // Lower 7 bits

// Decode two 7-bit values to 14-bit value
value = (msb << 7) | lsb;
```

**Examples**:
- **Tempo**: MSB (CC 89) + LSB (CC 90) = 300-2400 (divide by 10 for BPM)
- **Delay Time**: MSB (CC 30) + LSB (CC 31) = 0-3000ms (when not tempo-synced)
- **Mod Speed**: MSB (CC 51) + LSB (CC 52) = 0-1500 (10ths of Hz, when not tempo-synced)

### Tempo Sync Parameters

**Mod Note Select** (CC 57) and **Delay Note Select** (CC 35):

| Value | Meaning |
|-------|---------|
| < 0 | Tempo-synced (note division) |
| 0 | Off (use Time MSB/LSB in absolute units) |
| > 0 | Absolute units (Hz for mod, ms for delay) |

**Negative Values** (tempo-synced):
```
-1 = Whole note
-2 = Dotted half
-3 = Half note
-4 = Half note triplet
-5 = Dotted quarter
-6 = Quarter note
-7 = Quarter note triplet
-8 = Dotted eighth
-9 = Eighth note
-10 = Eighth note triplet
-11 = Dotted sixteenth
-12 = Sixteenth note
-13 = Sixteenth note triplet
```

**Encoding** (stored as unsigned in patch):
```dart
// Convert signed note value (-13 to -1) to unsigned (0-12)
unsignedValue = -noteValue - 1;

// Convert unsigned (0-12) back to signed
signedValue = -(unsignedValue + 1);
```

---

## Sysex Messages

### Command Format

All Line 6 sysex follows this structure:

```
F0 00 01 0C [command bytes] [data...] F7
```

### Edit Buffer Commands

#### Request Edit Buffer Dump

**Send**: `F0 00 01 0C 03 75 F7`

**Response**: Edit Buffer Dump (see below)

#### Edit Buffer Dump Response

**Receive**: `F0 00 01 0C 03 74 [ID] [160 bytes data] F7`

- `ID`: Device ID (1 byte, typically 0x05 for POD XT Pro)
- `data`: 160 bytes of raw patch data (NOT nibble-encoded)

**CRITICAL**: POD XT Pro responds with this message for BOTH edit buffer requests (03 75) AND patch dump requests (03 73)!

### Patch Dump Commands

#### Request Patch Dump

**Send**: `F0 00 01 0C 03 73 [P1] [P2] [ID] F7`

- `P1`: Upper 7 bits of patch number
- `P2`: Lower 7 bits of patch number
- `ID`: Device ID (0x05 for POD XT Pro)

**Patch Number Encoding** (non-contiguous):
```dart
int encodePatchNumber(int patch) {
  int midiProgram;

  if (patch < 64) {
    midiProgram = patch;        // 0-63 maps directly
  } else {
    midiProgram = patch + 128;  // 64-127 maps to 192-255
  }

  int p1 = (midiProgram >> 7) & 0x7F;  // Upper 7 bits
  int p2 = midiProgram & 0x7F;          // Lower 7 bits

  return [p1, p2];
}
```

**Response**: Edit Buffer Dump (03 74) containing the requested patch

**QUIRK**: POD XT Pro does NOT respond with Patch Dump Response (03 71). It responds with Edit Buffer Dump (03 74). You must track which patch you requested to know where to store the response.

#### Patch Dump Response (Theoretical)

**Receive**: `F0 00 01 0C 03 71 [P_LSB] [P_MSB] [ID] [160 bytes data] F7`

**NOTE**: POD XT Pro NEVER sends this message. Other POD models might.

#### Patch Dump End Marker

**Receive**: `F0 00 01 0C 03 72 F7`

**CRITICAL QUIRK**: POD XT Pro sends this after EVERY patch response (even individual patch requests), NOT just at the end of bulk operations.

**Implications**:
- During bulk import, you will receive 128 `03 72` messages (one per patch)
- Do NOT treat `03 72` as completion signal during bulk import
- Only treat as completion when your request loop finishes

### Store Patch Command

#### Store Edit Buffer to Patch

**Send**: `F0 00 01 0C 03 71 [ID] [P1] [P2] [160 bytes data] F7`

- `ID`: Device ID (0x05)
- `P1`: Upper 7 bits of patch number
- `P2`: Lower 7 bits of patch number
- `data`: 160 bytes of patch data

**NOTE**: Send format has different byte order than receive format!
- Send: `[ID] [P1] [P2] [data]`
- Receive (theoretical): `[P1] [P2] [ID] [data]`

**CRITICAL**: Must send Patch Dump End marker after store command!

**Send**: `F0 00 01 0C 03 72 F7`

#### Store Response

**Success**: `F0 00 01 0C 03 50 F7`

**Failure**: `F0 00 01 0C 03 51 F7`

**Timeout**: pod-ui uses 5-second timeout. If no response within 5s, treat as failure.

### Utility Commands

#### Request Installed Packs

**Send**: `F0 00 01 0C 03 0E F7`

**Response**: `F0 00 01 0C 03 0E [flags] F7`

**Flags** (bitfield):
- Bit 0 (0x01): MS - Metal Shop Amp Expansion
- Bit 1 (0x02): CC - Collector's Classic Amp Expansion
- Bit 2 (0x04): FX - FX Junkie Effects Expansion
- Bit 3 (0x08): BX - Bass Expansion

**Example**:
```
0x0F = All packs installed (MS + CC + FX + BX)
0x03 = Only MS and CC installed
```

#### Request Program Number

**Send**: `F0 00 01 0C 03 57 11 F7`

**Response**: `F0 00 01 0C 03 56 11 [P1] [P2] F7`

- `P1`: Upper 7 bits of program number
- `P2`: Lower 7 bits of program number

**Decode**:
```dart
int program = (p1 << 7) | p2;

if (program < 64) {
  patch = program;
} else if (program >= 192 && program < 256) {
  patch = program - 128;  // 192-255 maps to 64-127
}
```

#### Tuner Protocol

**Enable Tuner Mode**: Send CC 69 = 127 (via MIDI CC message)

**Disable Tuner Mode**: Send CC 69 = 0 (via MIDI CC message)

**Request Tuner Note**:

**Send**: `F0 00 01 0C 03 57 16 F7`

**Response**: `F0 00 01 0C 03 56 16 [P1] [P2] [P3] [P4] F7`

- `P1-P4`: Four nibbles encoding 16-bit note value
- Decode: `note = (P1 << 12) | (P2 << 8) | (P3 << 4) | P4`
- Special value `0xFFFE` = no signal detected

**Request Tuner Offset**:

**Send**: `F0 00 01 0C 03 57 17 F7`

**Response**: `F0 00 01 0C 03 56 17 [P1] [P2] [P3] [P4] F7`

- `P1-P4`: Four nibbles encoding 16-bit signed offset value (cents)
- Decode: `offset = (P1 << 12) | (P2 << 8) | (P3 << 4) | P4`
- Convert to signed: `if (offset > 32767) offset = offset - 65536`
- Special value `97` = no signal detected
- Range: -50 to +50 cents (clamped)

**POD Note Numbering**:
- POD note 0 = B0 (not C-1 like standard MIDI)
- Offset of +23 semitones from standard MIDI note numbering
- POD note to MIDI note: `midiNote = podNote + 23`

**Frequency Calculation**:
```dart
// POD note to frequency (A440 standard)
double frequency = 440.0 * pow(2, (podNote - 46) / 12.0);
```

**Note Names** (POD uses B-based numbering):
```
0=B, 1=C, 2=C#, 3=D, 4=D#, 5=E, 6=F, 7=F#, 8=G, 9=G#, 10=A, 11=A#
```

**Octave Calculation**:
```dart
int octave = (podNote ~/ 12) + 1;  // 1-based octave numbering
```

**Usage Notes**:
- Tuner data must be polled periodically (recommended: 1 Hz)
- Not event-driven - POD doesn't send tuner data automatically
- Must enable tuner mode via CC 69 before requesting data
- Disable tuner mode when done to avoid interfering with normal operation

**Example**:
```dart
// Enable tuner
await midi.sendControlChange(0, 69, 127);

// Poll tuner data at 1 Hz
Timer.periodic(Duration(seconds: 1), (_) async {
  await midi.sendSysex([0xF0, 0x00, 0x01, 0x0C, 0x03, 0x57, 0x16, 0xF7]);
  await midi.sendSysex([0xF0, 0x00, 0x01, 0x0C, 0x03, 0x57, 0x17, 0xF7]);
});

// Disable tuner when done
await midi.sendControlChange(0, 69, 0);
```

### All Programs Dump (NOT SUPPORTED)

**Send**: `F0 00 01 0C 01 00 02 F7`

**POD XT Pro does NOT support this command**. Use individual patch requests instead.

---

## Patch Data Structure

### Patch Format (160 Bytes)

```
Offset   Length   Description
------   ------   -----------
0-15     16       Patch name (ASCII, space-padded, NOT null-terminated)
16-159   144      Parameter data (72 parameters at 2 bytes each)
```

### Parameter Storage

Each CC parameter has a buffer address (typically 32 + CC number):

```dart
int bufferAddress = param.address ?? (32 + param.cc);
```

**Read parameter**:
```dart
int value = patchData[bufferAddress];
```

**Write parameter**:
```dart
patchData[bufferAddress] = value;
```

**14-bit parameters**:
```dart
// Read
int msb = patchData[msbAddress];
int lsb = patchData[lsbAddress];
int value = (msb << 7) | lsb;

// Write
patchData[msbAddress] = (value >> 7) & 0x7F;
patchData[lsbAddress] = value & 0x7F;
```

**Boolean parameters**:
```dart
// Read
bool enabled = patchData[address] >= 64;

// With inversion (e.g., amp enable)
if (param.inverted) {
  enabled = patchData[address] < 64;
}

// Write
int value = enabled ? 127 : 0;
if (param.inverted) {
  value = enabled ? 0 : 127;
}
patchData[address] = value;
```

### Patch Name Encoding

**Format**: 16-byte ASCII string, space-padded

```dart
// Encode name
String name = "My Patch";
List<int> bytes = List.filled(16, 0x20);  // Fill with spaces
for (int i = 0; i < name.length && i < 16; i++) {
  bytes[i] = name.codeUnitAt(i);
}

// Decode name
String name = String.fromCharCodes(patchData.sublist(0, 16)).trimRight();
```

---

## BLE-MIDI Specifics

### Packet Size Limitation

BLE-MIDI packets are limited to 20 bytes per packet.

**Implication**: Large sysex messages (like 160-byte patch dumps) span multiple packets.

### Multi-Packet Sysex Assembly

```dart
List<int>? _sysexBuffer;
bool _receivingSysex = false;

void handleMidiData(List<int> data) {
  for (int byte in data) {
    if (byte == 0xF0) {
      // Start of sysex
      _receivingSysex = true;
      _sysexBuffer = [0xF0];
    } else if (_receivingSysex) {
      _sysexBuffer!.add(byte);

      if (byte == 0xF7) {
        // End of sysex
        _emitSysex(_sysexBuffer!);
        _receivingSysex = false;
        _sysexBuffer = null;
      }
    } else {
      // Regular MIDI message
      _handleMidi(byte);
    }
  }
}
```

### BLE-MIDI Timestamp

BLE-MIDI prepends a timestamp byte (ignored in this implementation):

```
[timestamp] [MIDI byte 1] [MIDI byte 2] ...
```

**Flutter_midi_command**: The package handles timestamp parsing automatically.

---

## Implementation Examples

### Connect and Read Edit Buffer

```dart
// Create services
final midi = BleMidiService();
final pod = PodController(midi);

// Scan for devices
final devices = await pod.scanDevices();

// Connect to first POD XT Pro
await pod.connect(devices.first);

// Edit buffer is automatically requested on connection
// Listen for it
pod.onEditBufferChanged.listen((buffer) {
  print('Edit buffer loaded: ${buffer.patch.name}');
});
```

### Set Parameter

```dart
// Set drive to 75%
await pod.setParameter(PodXtCC.drive, 95);

// Or use convenience setter
await pod.setDrive(95);
```

### Change Amp Model

```dart
// Change to Brit J-800
await pod.setAmpModel(22);
```

### Select Program

```dart
// Select program 5 (Bank A, patch 6)
await pod.selectProgram(5);

// Program change is sent via MIDI
// Edit buffer is requested via sysex
// UI updates when edit buffer arrives
```

### Save Patch to Hardware

```dart
// Save current edit buffer to program 10
await pod.savePatchToHardware(10);

// Listen for result
pod.onStoreResult.listen((result) {
  if (result.success) {
    print('Patch saved to ${result.patchNumber}');
  } else {
    print('Save failed: ${result.error}');
  }
});
```

### Bulk Import All Patches

```dart
// Import all 128 patches from hardware
await pod.importAllPatchesFromHardware();

// Listen for progress
pod.onSyncProgress.listen((progress) {
  print('Progress: ${progress.current}/${progress.total}');
  print('Message: ${progress.message}');
});

// Total time: ~6.4 seconds (50ms × 128 patches)
```

---

## Troubleshooting

### Problem: Edit Buffer Not Updating

**Symptoms**: UI doesn't reflect hardware changes

**Causes**:
1. Not listening to `onParameterChanged` stream
2. Connection lost
3. Sysex buffering issue (multi-packet message corrupted)

**Solution**:
```dart
// Listen for parameter changes
pod.onParameterChanged.listen((change) {
  print('${change.param.name} = ${change.value}');
  setState(() { /* update UI */ });
});

// Check connection
pod.onConnectionStateChanged.listen((connected) {
  if (!connected) {
    print('Connection lost!');
  }
});
```

### Problem: Bulk Import Fails or Stalls

**Symptoms**: Import progress stops midway

**Causes**:
1. Timeout too short
2. Hardware responds slowly
3. Sysex message corrupted

**Solution**:
- Ensure 50ms delay between requests (already implemented)
- Use Completer to wait for actual response, not fixed delay
- Check for 03 72 confusion (should be ignored during bulk import)

### Problem: Store Patch Fails

**Symptoms**: No 03 50 response after save

**Causes**:
1. Didn't send 03 72 end marker
2. Timeout too short
3. Patch number out of range

**Solution**:
```dart
// Always send end marker after patch dump
await _midi.sendSysex(storePatch(patchNum, data));
await _midi.sendSysex(requestPatchDumpEnd());

// Wait for response (with timeout)
final result = await _storeCompleter.future.timeout(
  Duration(seconds: 5),
  onTimeout: () => StoreResult(success: false, error: 'Timeout'),
);
```

### Problem: Wrong Patch Loaded During Bulk Import

**Symptoms**: Patches appear in wrong slots after import

**Causes**:
1. POD responds with 03 74 for patch requests
2. `_expectedPatchNumber` not tracked correctly
3. Response/request mismatch (too many requests in flight)

**Solution**:
- Track `_expectedPatchNumber` before each request
- Wait for response before sending next request (use Completer)
- Never send multiple patch requests simultaneously

---

## Reference

### POD-UI (Rust Reference Implementation)

POD-UI is the authoritative source for POD XT protocol details:

**Key Files**:
- `/pod-ui-master/mod-xt/src/config.rs` - Device configuration
- `/pod-ui-master/mod-xt/src/handler.rs` - Message handling
- `/pod-ui-master/core/src/midi.rs` - MIDI protocol
- `/pod-ui-master/core/src/model.rs` - Data models

**Confirmed Behaviors**:
1. POD XT Pro uses 160-byte patches (line 469: `program_size: 72*2 + 16`)
2. POD responds with 03 74 for patch requests (handler.rs:292-316)
3. Store timeout is 5 seconds (handler.rs:206)
4. Non-contiguous patch mapping (0-63, 192-255)

### Line 6 Documentation

**Official POD XT Pro Documentation**:
- MIDI Implementation Chart (in manual)
- Sysex specification (not publicly available, reverse-engineered)

**Note**: Line 6 has never publicly released complete sysex documentation. This implementation is based on pod-ui reverse-engineering and hardware testing.
