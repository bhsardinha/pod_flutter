# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Flutter mobile app to control the Line 6 POD XT Pro guitar processor via Bluetooth MIDI. Targets iOS and Android. Reference implementation: [pod-ui](https://github.com/arteme/pod-ui) (Rust/GTK desktop app with sysex protocol details).

## Build & Development Commands

```bash
flutter run              # Run app (requires device/emulator)
flutter test             # Run all tests
flutter test test/file.dart  # Run single test
flutter analyze          # Lint code
flutter pub get          # Get dependencies
flutter build apk        # Build Android release
flutter build ios        # Build iOS release
```

## Coding Standards

**IMPORTANT**

- **THE pod-ui is the only source of truth** always create or edit things ensuring the mimic the exact behaviour of the full working rust app!

**IMPORTANT - Deprecated APIs:**
- **NEVER use `withOpacity()`** - it's deprecated and causes precision loss
- **ALWAYS use `.withValues(alpha: value)`** instead

```dart
// ❌ WRONG - deprecated
Colors.white.withOpacity(0.95)

// ✅ CORRECT
Colors.white.withValues(alpha: 0.95)
```

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                           Flutter App                                │
├─────────────────────────────────────────────────────────────────────┤
│  PodController (lib/services/pod_controller.dart)                   │
│  - High-level API for controlling POD                               │
│  - Manages EditBuffer (current patch state)                         │
│  - Manages PatchLibrary (128 stored patches)                        │
│  - Exposes streams for state changes                                │
├─────────────────────────────────────────────────────────────────────┤
│  MidiService (lib/services/midi_service.dart)                       │
│  - Abstract interface for MIDI I/O                                  │
│  BleMidiService (lib/services/ble_midi_service.dart)                │
│  - Concrete BLE-MIDI implementation using flutter_midi_command      │
├─────────────────────────────────────────────────────────────────────┤
│  Protocol Layer (lib/protocol/)                                     │
│  - constants.dart: Sysex commands, device IDs, pack flags           │
│  - cc_map.dart: All 70+ CC parameter mappings                       │
│  - sysex.dart: Sysex message encoding/decoding                      │
├─────────────────────────────────────────────────────────────────────┤
│  Models (lib/models/)                                               │
│  - patch.dart: Patch/EditBuffer data structures (160 bytes)         │
│  - amp_models.dart: 105 amp models (stock + MS/CC/BX packs)         │
│  - cab_models.dart: 47 cabinet + 8 mic models                       │
│  - effect_models.dart: Stomp/Mod/Delay/Reverb/Wah models           │
└─────────────────────────────────────────────────────────────────────┘
          │
          │ BLE-MIDI
          ▼
┌─────────────────────┐     MIDI      ┌──────────────┐
│  BT-MIDI Adapter    │ ───────────► │  POD XT Pro  │
│  (CME WIDI, etc)    │               │              │
└─────────────────────┘               └──────────────┘
```

## Key Files

| File | Purpose |
|------|---------|
| `lib/protocol/cc_map.dart` | All 70+ CC parameters with addresses |
| `lib/protocol/sysex.dart` | Sysex encoding, edit buffer requests |
| `lib/services/pod_controller.dart` | Main controller with convenience APIs |
| `lib/models/patch.dart` | Patch data model (160 bytes per patch for POD XT Pro) |

## MIDI Protocol Summary

**Control Changes**: Parameters are controlled via MIDI CC. Each CCParam has:
- `cc`: MIDI CC number (0-127)
- `address`: Buffer address for patch storage (offset 32 + CC typically)

**Sysex Format**:
```
[0xF0] [0x00 0x01 0x0C] [command...] [data...] [0xF7]
        └─ Line6 ID ─┘
```

**Key Commands**:
- `[0x03, 0x75]` - Request edit buffer dump
- `[0x03, 0x74]` - Edit buffer dump response
- `[0x03, 0x73]` - Request patch dump
- `[0x03, 0x71]` - Patch dump response

## Expansion Packs

| Flag | Name |
|------|------|
| MS (0x01) | Metal Shop Amp Expansion |
| CC (0x02) | Collector's Classic Amp Expansion |
| FX (0x04) | FX Junkie Effects Expansion |
| BX (0x08) | Bass Expansion |

## POD XT Pro Specifics

**CRITICAL:** This app is for **POD XT Pro** specifically. POD XT and POD XT Pro have differences:

### Patch Size (CRITICAL DIFFERENCE!)
- **POD XT Pro**: **160 bytes per patch** (verified from hardware)
- POD XT (non-Pro): 152 bytes (per pod-ui reference)
- POD XT Live: Different
- POD X3: Different again

**IMPORTANT:** The pod-ui reference documentation describes POD XT (152 bytes), but POD XT Pro uses a different, larger patch size (160 bytes). This was verified by commit 9effcbf where changing from 152→160 made the app work with actual POD XT Pro hardware.

**Structure** (POD XT Pro):
- Bytes 0-15: Patch name (16 bytes, space-padded)
- Bytes 16-159: Parameter data (144 bytes)
- Total: 160 bytes

### Sysex Message Format (POD XT Pro)

**Edit Buffer Dump Response** (`0x03 0x74`):
```
F0 00 01 0C 03 74 [ID] [160 bytes raw data] F7
- ID: 1 byte device ID
- Data: 160 bytes (NOT nibble-encoded!)
```

**Patch Dump Response** (`0x03 0x71`):
```
F0 00 01 0C 03 71 [P_LSB] [P_MSB] [ID] [160 bytes raw data] F7
- P_LSB, P_MSB: Patch number as 2 bytes (LSB, MSB)
- ID: 1 byte device ID (usually 0x05)
- Data: 160 bytes (NOT nibble-encoded!)
```

**Store Patch** (same as Patch Dump):
```
F0 00 01 0C 03 71 [P_LSB] [P_MSB] [ID] [160 bytes raw data] F7
F0 00 01 0C 03 72 F7  # Patch dump end marker (REQUIRED)
- Must send end marker after store
- Response: 03 50 (success) or 03 51 (failure)
```

**CRITICAL**: POD XT Pro does NOT use nibble encoding for patch data (unlike other Line 6 devices). Data is sent raw.

### Critical Quirk: Patch Dump Responses

**POD XT/XT Pro responds to patch dump requests with edit buffer dumps!**

When you request a patch dump (`03 73`), the POD responds with `03 74` (edit buffer dump), **NOT** `03 71` (patch dump).

**Solution**: Track which patch you requested and treat `03 74` responses as patch dumps during bulk import:

```dart
int? _expectedPatchNumber;

// Request patch
_expectedPatchNumber = 42;
await sendSysex(requestPatch(42));

// In edit buffer dump handler:
if (_expectedPatchNumber != null) {
  // This is a patch dump response, not edit buffer!
  _patchLibrary[_expectedPatchNumber] = patch;
  _expectedPatchNumber = null;
} else {
  _editBuffer = patch;
}
```

This matches pod-ui behavior (handler.rs:292-316).

### Bulk Import
POD XT Pro does NOT support bulk dump commands. Must request patches individually:
```dart
bool _bulkImportInProgress = true;

for (int i = 0; i < 128; i++) {
  _expectedPatchNumber = i;
  await sendSysex(requestPatch(i));
  await waitForResponse();  // Waits for 03 74 edit buffer dump!
  // POD sends 03 72 after EACH patch - do NOT treat as completion!
}

_bulkImportInProgress = false;
```

**CRITICAL**: Must wait for each patch response before requesting next. Simple delays are not sufficient - use Completers or similar to wait for actual responses.

### Critical: Patch Dump End (03 72) Behavior

**POD XT Pro sends `03 72` after EACH individual patch, NOT just at the end of bulk operations!**

This is different from other POD models:
- **Other POD models**: Support AllProgramsDump, send `03 72` once at the very end
- **POD XT Pro**: No AllProgramsDump support, sends `03 72` after every single patch response

**Message flow per patch:**
1. Send `03 73` (Patch Dump Request)
2. Receive `03 74` (Edit Buffer Dump - contains patch data)
3. Receive `03 72` (Patch Dump End - just acknowledges this ONE patch)

**Implementation:**
```dart
void _handlePatchDumpEnd(SysexMessage message) {
  // During POD XT Pro bulk import, ignore individual 03 72 markers
  if (_bulkImportInProgress) {
    return;  // This is NOT the end of the bulk operation!
  }

  // Only treat as completion for other POD models
  _patchesSynced = true;
}
```

The actual completion is determined by the import loop finishing all 128 patches, NOT by receiving `03 72`.

## Usage Pattern

```dart
// Create services
final midi = BleMidiService();
final pod = PodController(midi);

// Connect
final devices = await pod.scanDevices();
await pod.connect(devices.first);

// Control parameters
await pod.setDrive(100);
await pod.setAmpModel(22); // Brit J-800
await pod.setDelayEnabled(true);

// Listen for changes from device
pod.onParameterChanged.listen((change) {
  print('${change.param.name} = ${change.value}');
});

// Listen for store results
pod.onStoreResult.listen((result) {
  if (result.success) {
    print('Patch saved!');
  } else {
    print('Save failed: ${result.error}');
  }
});
```
