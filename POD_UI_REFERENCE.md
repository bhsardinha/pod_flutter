# POD-UI Reference Architecture

This document maps pod-ui (Rust) components to Flutter app implementation for **POD XT Pro** specifically.

**⚠️ IMPORTANT: This reference is EXCLUSIVELY for POD XT Pro. Other POD models may differ.**

## POD XT Pro Specifications

**Device Identification** (from `mod-xt/src/config.rs`):
- **Family**: `0x0003`
- **Member**: `0x0005`
- **Patch Size**: 160 bytes (16 bytes name + 144 bytes parameters)
- **Program Count**: 128 patches (1A-32D)

**Protocol Characteristics**:
- Uses **RAW 8-bit data** (NOT nibble-packed)
- Supports individual patch dump requests (03 73)
- Does NOT support AllProgramsDump
- Responds to patch dump requests with edit buffer dumps (03 74)

## CRITICAL: POD XT Pro Patch Number Mapping

**POD XT Pro uses NON-CONTIGUOUS patch mapping** (from `core/src/midi.rs`):

### User Patches (0-127) → MIDI Patch Mapping

```rust
// From pod-ui core/src/midi.rs PodXtPatch::to_midi
pub fn to_midi(value: u16) -> u16 {
    let bank = (value >> 8) & 0xff;
    let patch = value & 0xff;
    match (bank, patch) {
        (0, 0 ..= 63) => patch,              // Patches 0-63 → MIDI 0-63
        (0, 64 ..= 127) => patch + 128,      // Patches 64-127 → MIDI 192-255
        // ... other banks for effects etc
    }
}
```

**Critical Mapping**:
- User Patch 0-63 (1A-16D) → MIDI Patch 0-63
- User Patch 64-127 (17A-32D) → MIDI Patch **192-255** (NOT 64-127!)

### Reverse Mapping (MIDI → User Patch)

```rust
// From pod-ui core/src/midi.rs PodXtPatch::from_midi
pub fn from_midi(value: u16) -> u16 {
    let (bank, patch) = match value {
        0 ..= 63 => (0, value),           // MIDI 0-63 → Patch 0-63
        192 ..= 255 => (0, value - 128),  // MIDI 192-255 → Patch 64-127
        // ... other ranges for different banks
    };
    (bank << 8) | patch
}
```

### Encoding: 14-bit to Two 7-bit Bytes

```rust
// From pod-ui core/src/util.rs
pub fn u16_to_2_u7(v: u16) -> (u8, u8) {
    let b1 = v >> 7;        // Upper 7 bits
    let b2 = v & 0x7f;      // Lower 7 bits
    (b1 as u8, b2 as u8)
}

pub fn u16_from_2_u7(v1: u8, v2: u8) -> u16 {
    (v1 as u16) << 7 | (v2 as u16)
}
```

### Flutter Implementation

```dart
// lib/protocol/sysex.dart
static Uint8List requestPatch(int patchNumber) {
  // Step 1: Convert user patch (0-127) to MIDI patch
  int midiPatch;
  if (patchNumber >= 0 && patchNumber <= 63) {
    midiPatch = patchNumber;        // 0-63 → MIDI 0-63
  } else if (patchNumber >= 64 && patchNumber <= 127) {
    midiPatch = patchNumber + 128;  // 64-127 → MIDI 192-255
  }

  // Step 2: Encode MIDI patch as two 7-bit bytes
  final p1 = (midiPatch >> 7) & 0x7F;  // Upper 7 bits
  final p2 = midiPatch & 0x7F;         // Lower 7 bits

  // Step 3: Build message
  return buildMessage(
    SysexCommand.patchDumpRequest,
    [p1, p2, 0x00, 0x00],
  );
}
```

## Layer Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     Application Layer                       │
│  mod-xt/handler.rs → PodController (pod_controller.dart)    │
│  - Queue management for sysex requests/responses            │
│  - Expansion pack detection                                 │
│  - Tuner control                                            │
│  - Store acknowledgment                                     │
├─────────────────────────────────────────────────────────────┤
│                    State Management                         │
│  controller.rs → CCParam state tracking                     │
│  edit.rs → EditBuffer (current patch)                       │
│  dump.rs → PatchLibrary (128 patches)                       │
│  program.rs → Serialization helpers                         │
├─────────────────────────────────────────────────────────────┤
│                    Protocol Layer                           │
│  midi.rs → sysex.dart                                       │
│  - MidiMessage enum → Dart classes                          │
│  - to_bytes() → encodeXxx() methods                         │
│  - from_bytes() → decodeXxx() methods                       │
│  - Patch number mapping (PodXtPatch)                        │
│  - 14-bit encoding (u16_to_2_u7)                            │
├─────────────────────────────────────────────────────────────┤
│                   Transport Layer                           │
│  midi_io.rs → MidiService (abstract)                        │
│              → BleMidiService (concrete)                    │
│  - UDI handshake (autodetect)                               │
│  - Channel detection                                        │
│  - BLE-MIDI framing                                         │
└─────────────────────────────────────────────────────────────┘
```

## Sysex Protocol Reference

### Message Formats (POD XT Pro)

All messages use Line6 sysex prefix: `[0xF0, 0x00, 0x01, 0x0C, ...]`

| Message | Command | Format | Notes |
|---------|---------|--------|-------|
| Edit Buffer Request | `03 75` | `F0 00 01 0C 03 75 F7` | Request current edit buffer |
| Edit Buffer Dump | `03 74` | `F0 00 01 0C 03 74 ID [160 bytes] F7` | RAW 8-bit data |
| Patch Dump Request | `03 73` | `F0 00 01 0C 03 73 P1 P2 00 00 F7` | P1/P2 = encoded MIDI patch |
| Patch Dump (send) | `03 71` | `F0 00 01 0C 03 71 ID P1 P2 [160 bytes] F7` | Store to hardware |
| Patch Dump End | `03 72` | `F0 00 01 0C 03 72 F7` | Send after receiving dump |
| Store Success | `03 50` | `F0 00 01 0C 03 50 F7` | Acknowledgment |
| Store Failure | `03 51` | `F0 00 01 0C 03 51 F7` | Error response |
| Installed Packs Request | `03 7D` | `F0 00 01 0C 03 7D F7` | Query expansion packs |
| Installed Packs Response | `03 7C` | `F0 00 01 0C 03 7C ID P1 P2 F7` | P1/P2 = bitmap |

**P1/P2 Encoding**: After converting user patch to MIDI patch, encode as:
- `P1 = (midiPatch >> 7) & 0x7F` (upper 7 bits)
- `P2 = midiPatch & 0x7F` (lower 7 bits)

**ID Field**: Device ID (typically `0x05` for broadcast)

### Data Encoding

**⚠️ CRITICAL**: POD XT Pro sends **RAW 8-bit data** (NOT nibble-packed)!

The 160-byte patch data is transmitted directly as-is, verified in `mod-xt/src/handler.rs:552-579`.

## Bulk Import Implementation

### From pod-ui (mod-xt/src/handler.rs)

```rust
// Lines 184-193: Request all patches
Buffer::All => {
    // Request user patches 0-127
    for v in 0 .. ctx.config.program_num {
        self.queue_push(MidiMessage::XtPatchDumpRequest { patch: v as u16 });
    }
    // Request effects patches (0x0200-0x023F)
    for v in 0 .. 64 {
        self.queue_push(MidiMessage::XtPatchDumpRequest { patch: 0x0200 | v as u16 });
    }
    self.queue_send(ctx);
}
```

### Critical Quirk: Response Message Type

**POD XT Pro responds to Patch Dump Request (03 73) with Edit Buffer Dump (03 74), NOT Patch Dump (03 71)!**

From `mod-xt/src/handler.rs:302-316`:

```rust
// PODxt answers with a buffer dump to either edit buffer dump request or
// a patch dump request... We peek into the current queue to try and determine,
// which buffer comes. This is quite error-prone, since any one message missed
// may incorrectly place the data into the wrong dump ;(
let buffer = match self.queue_peek() {
    Some(MidiMessage::XtEditBufferDumpRequest) =>
        Buffer::EditBuffer,
    Some(MidiMessage::XtPatchDumpRequest { patch }) =>
        Buffer::Program(patch as usize),  // Received as 03 74, not 03 71!
    msg @ _ => {
        warn!("Can't determine incoming buffer designation, queue peek = {:?}", msg);
        Buffer::EditBuffer
    }
};
```

### Flutter Implementation Pattern

```dart
// Track which patch we're expecting during bulk import
int? _expectedPatchNumber;
bool _bulkImportInProgress = false;

// Request patch (silent, background - does NOT change current patch)
Future<void> importPatch(int patchNum) async {
  _expectedPatchNumber = patchNum;
  await _midi.sendSysex(PodXtSysex.requestPatch(patchNum));

  // Wait for edit buffer dump (03 74) response
  await _patchDumpCompleter.future;
}

// Handle edit buffer dump
void _handleEditBufferDump(SysexMessage message) {
  final patch = Patch.fromData(message.payload);

  // During bulk import, check if this is a patch dump response
  if (_expectedPatchNumber != null && _patchDumpCompleter != null) {
    // This 03 74 is actually a patch dump response!
    _patchLibrary.patches[_expectedPatchNumber!] = patch;
    _patchDumpCompleter!.complete();
    _expectedPatchNumber = null;
  } else if (_bulkImportInProgress) {
    // Ignore unexpected dumps (amp presets, user FX, etc.)
    return;
  } else {
    // Normal edit buffer update
    _editBuffer = patch;
  }
}
```

## Loading vs Importing Patches

### Load Patch (Audible - Changes POD State)

From `mod-xt/src/handler.rs:158-182`:

```rust
// Load for editing - uses Program Change
Buffer::Current => {
    if let Some(v) = num_program(&ctx.program()) {
        self.queue_push(MidiMessage::XtPatchDumpRequest { patch: v as u16 });
        self.queue_send(ctx);
    }
}
```

**Flutter Implementation**:
```dart
// This CHANGES the current patch on the POD (audible)
Future<void> selectProgram(int program) async {
  await _midi.sendProgramChange(program);
  _currentProgram = program;
  await _midi.requestEditBuffer();
}
```

### Import Patch (Silent - Background Query)

**Flutter Implementation**:
```dart
// This queries patch data WITHOUT changing current patch (silent)
Future<void> importPatch(int patchNum) async {
  _expectedPatchNumber = patchNum;
  await _midi.sendSysex(PodXtSysex.requestPatch(patchNum));
  // POD responds with patch data without switching patches
}
```

## Expansion Pack Detection

From `mod-xt/src/config.rs:24-29`:

```rust
bitflags! {
    pub struct XtPacks: u8 {
        const MS = 0x01;  // Metal Shop
        const CC = 0x02;  // Collector's Classic
        const FX = 0x04;  // FX Junkie
        const BX = 0x08;  // Bass Expansion
    }
}
```

**Flutter Implementation**:
```dart
// Request installed packs
await _midi.sendSysex(PodXtSysex.requestInstalledPacks());

// Parse response
void _handleInstalledPacks(SysexMessage message) {
  final packsValue = message.payload[0];
  _installedPacks = packsValue;

  // Check individual packs
  final hasMS = (packsValue & 0x01) != 0;  // Metal Shop
  final hasCC = (packsValue & 0x02) != 0;  // Collector's Classic
  final hasFX = (packsValue & 0x04) != 0;  // FX Junkie
  final hasBX = (packsValue & 0x08) != 0;  // Bass Expansion
}
```

## Store Patch to Hardware

From `mod-xt/src/handler.rs:248-261`:

```rust
MidiMessage::XtPatchDump {
    patch: patch as u16,
    id: ctx.config.member as u8,
    data: event.data.clone()
}
```

**Format**: `F0 00 01 0C 03 71 ID P1 P2 [160 bytes] F7`

**Flutter Implementation**:
```dart
Future<void> savePatchToHardware(int patchNumber) async {
  // Convert user patch to MIDI patch
  int midiPatch = (patchNumber >= 64)
    ? patchNumber + 128
    : patchNumber;

  // Encode as two 7-bit bytes
  final p1 = (midiPatch >> 7) & 0x7F;
  final p2 = midiPatch & 0x7F;
  final id = 0x05;

  final storeMsg = buildMessage(0x03, 0x71, [id, p1, p2, ...patchData]);
  await _midi.sendSysex(storeMsg);
  await _midi.sendSysex(PodXtSysex.requestPatchDumpEnd());

  // Wait for 03 50 (success) or 03 51 (failure)
}
```

## Testing Checklist

1. **Patch Mapping**:
   - ✅ Patch 0-63: Verify MIDI patch 0-63
   - ✅ Patch 64-127: Verify MIDI patch 192-255
   - ✅ Encoding: Verify (midiPatch >> 7, midiPatch & 0x7F)

2. **Bulk Import**:
   - ✅ Silent operation (no audible patch changes)
   - ✅ All 128 patches imported correctly
   - ✅ Ignores extra data (amp presets, user FX)
   - ✅ Handles 03 74 responses correctly

3. **Store Operation**:
   - ✅ Correct patch mapping
   - ✅ Receives 03 50/03 51 response
   - ✅ Sends 03 72 end marker

## Source Code References

- POD XT Pro Handler: `pod-ui-master/mod-xt/src/handler.rs`
- MIDI Protocol: `pod-ui-master/core/src/midi.rs`
- Utility Functions: `pod-ui-master/core/src/util.rs`
- Configuration: `pod-ui-master/mod-xt/src/config.rs`
- Patch Mapping: `core/src/midi.rs:47-97` (PodXtPatch struct)
- Encoding: `core/src/util.rs:54-62` (u16_to_2_u7, u16_from_2_u7)
