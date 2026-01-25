# POD XT Pro Differences

## Overview

This document describes the critical differences between POD XT Pro and other POD models (POD XT, POD XT Live, etc.). These differences are essential for correct implementation and were verified through hardware testing and comparison with the pod-ui reference implementation.

**IMPORTANT**: This app is specifically designed for **POD XT Pro**. It will NOT work correctly with other POD models without modifications.

---

## Critical Differences

### 1. Patch Size ⚠️ CRITICAL

**POD XT Pro**: **160 bytes per patch**

**Other POD Models**:
- POD XT (non-Pro): 152 bytes
- POD XT Live: Different (unknown)
- POD X3: Different protocol entirely

**Structure**:
```
Offset   Length   Description
------   ------   -----------
0-15     16       Patch name (ASCII, space-padded)
16-159   144      Parameter data (72 parameters)
Total:   160      Full patch size
```

**Verification**:
- Confirmed via hardware testing (commit 9effcbf: changing from 152→160 made the app work)
- pod-ui config.rs line 469: `program_size: 72*2 + 16 = 160`

**Code Location**:
```dart
// lib/protocol/constants.dart
const programSize = 160;  // POD XT Pro specific
```

**Impact**: Using wrong patch size causes:
- Corrupted patches (data misalignment)
- Incorrect parameter values
- Potential hardware confusion

---

### 2. Sysex Response Behavior ⚠️ CRITICAL

#### Patch Dump Request → Edit Buffer Dump Response

**POD XT Pro Behavior**:
- You request a patch dump: `F0 00 01 0C 03 73 [patch] F7`
- POD responds with **edit buffer dump**: `F0 00 01 0C 03 74 [data] F7`
- **NOT** a patch dump response (03 71)

**Other POD Models**:
- Some respond with proper patch dump (03 71)
- Some support AllProgramsDump command

**Verification**:
pod-ui handler.rs:292-316:
```rust
// PODxt answers with a buffer dump to either edit buffer dump request or
// a patch dump request... We peek into the current queue to try and determine,
// which buffer comes.
```

**Implementation**:
```dart
// Track which patch we requested
int? _expectedPatchNumber;

// Before request
_expectedPatchNumber = 42;
await _midi.sendSysex(requestPatch(42));

// In edit buffer dump handler
void _handleEditBufferDump(SysexMessage message) {
  if (_expectedPatchNumber != null) {
    // This is actually a patch dump response!
    _patchLibrary[_expectedPatchNumber] = patch;
    _expectedPatchNumber = null;
  } else {
    // This is a real edit buffer update
    _editBuffer.patch = patch;
  }
}
```

**Impact**: Without tracking expected patch number:
- Patches stored in wrong slots
- Edit buffer overwritten during bulk import
- Desynchronized state

---

### 3. Patch Dump End Marker (03 72) ⚠️ CRITICAL

#### Individual vs Bulk End Markers

**POD XT Pro Behavior**:
- Sends `03 72` after **EVERY SINGLE PATCH**
- Even for individual patch requests
- NOT just at the end of bulk operations

**Other POD Models**:
- Support AllProgramsDump command
- Send `03 72` once at the very end of bulk dump

**Message Flow** (POD XT Pro):
```
Request Patch 0: F0 00 01 0C 03 73 [0] F7
  → Response:    F0 00 01 0C 03 74 [data] F7
  → End Marker:  F0 00 01 0C 03 72 F7

Request Patch 1: F0 00 01 0C 03 73 [1] F7
  → Response:    F0 00 01 0C 03 74 [data] F7
  → End Marker:  F0 00 01 0C 03 72 F7

... (128 times total)
```

**Implementation**:
```dart
void _handlePatchDumpEnd(SysexMessage message) {
  // During POD XT Pro bulk import, ignore individual markers
  if (_bulkImportInProgress) {
    return;  // NOT the end of bulk operation!
  }

  // Only treat as completion for other POD models
  _patchesSynced = true;
}
```

**Impact**: Without proper handling:
- Bulk import terminates after first patch
- False completion signal
- Only 1 of 128 patches imported

---

### 4. Non-Contiguous Patch Mapping

#### MIDI Program Number Mapping

**POD XT Pro Mapping**:
```
Patch   MIDI Program
-----   ------------
0-63    0-63         (direct mapping)
64      192          (gap!)
65      193
...
127     255
```

**Other POD Models**:
- Some use contiguous mapping (0-127)
- Some use different ranges

**Encoding**:
```dart
int encodePatchNumber(int patch) {
  int midiProgram;

  if (patch < 64) {
    midiProgram = patch;        // 0-63 maps directly
  } else {
    midiProgram = patch + 128;  // 64-127 → 192-255
  }

  return midiProgram;
}
```

**Decoding**:
```dart
int decodePatchNumber(int midiProgram) {
  if (midiProgram < 64) {
    return midiProgram;         // 0-63 maps directly
  } else if (midiProgram >= 192 && midiProgram < 256) {
    return midiProgram - 128;   // 192-255 → 64-127
  } else {
    throw ArgumentError('Invalid MIDI program: $midiProgram');
  }
}
```

**Impact**: Using wrong mapping causes:
- Program changes select wrong patches
- Bank C/D inaccessible
- Confusion between user patches and presets

---

### 5. No AllProgramsDump Support

#### Sequential vs Bulk Dump

**POD XT Pro**:
- Does NOT support AllProgramsDump command (`F0 00 01 0C 01 00 02 F7`)
- Must request all 128 patches individually
- Takes ~6.4 seconds (50ms × 128 patches)

**Other POD Models**:
- Many support AllProgramsDump
- Single command retrieves all patches
- Much faster

**Implementation**:
```dart
Future<void> importAllPatchesFromHardware() async {
  _bulkImportInProgress = true;

  // Must request each patch individually
  for (int i = 0; i < 128; i++) {
    _expectedPatchNumber = i;
    await _midi.sendSysex(requestPatch(i));

    // Wait for response (via Completer)
    await _patchCompleters[i]!.future;

    // Small delay to avoid overwhelming hardware
    await Future.delayed(Duration(milliseconds: 50));

    // Emit progress
    _syncProgressController.add(SyncProgress(
      current: i + 1,
      total: 128,
      message: 'Loading patch ${i + 1}/128...',
    ));
  }

  _bulkImportInProgress = false;
  _patchesSynced = true;
}
```

**Impact**:
- Slower bulk import
- More complex state management
- Requires careful synchronization

---

### 6. Inverted Amp Enable Parameter

#### Inverted Logic

**POD XT Pro**: Amp Enable (CC 111) uses **inverted** logic
- `0` = Amp ON
- `127` = Amp OFF

**Other Parameters**: Normal logic
- `0` = OFF
- `127` = ON

**Other POD Models**:
- Some may use normal logic (unverified)

**Implementation**:
```dart
// In cc_map.dart
static const ampEnable = CCParam(
  cc: 111,
  name: 'Amp Enable',
  inverted: true,  // ← Critical flag
);

// In patch.dart
bool getSwitch(CCParam param) {
  int value = getValue(param);

  if (param.inverted) {
    return value < 64;  // Inverted: < 64 = ON
  } else {
    return value >= 64; // Normal: >= 64 = ON
  }
}

void setSwitch(CCParam param, bool enabled) {
  int value = enabled ? 127 : 0;

  if (param.inverted) {
    value = enabled ? 0 : 127;  // Inverted: ON = 0
  }

  setValue(param, value);
}
```

**Impact**: Without inversion handling:
- Amp enable button shows wrong state
- Amp turns off when button shows "on"
- Confusing user experience

---

### 7. Data Encoding

#### Raw vs Nibble Encoding

**POD XT Pro**: Patch data is **NOT nibble-encoded**
- Data is sent raw (160 bytes)
- Each byte uses full 7-bit range (0-127)

**Other Line 6 Devices**:
- Many use nibble encoding (4-bit nibbles)
- Converts 8-bit bytes to two 7-bit nibbles
- Data size doubles

**Example** (nibble encoding - NOT used by POD XT Pro):
```dart
// POD 2.0 uses this, POD XT Pro does NOT
List<int> encodeNibbles(List<int> data) {
  List<int> nibbles = [];
  for (int byte in data) {
    nibbles.add((byte >> 4) & 0x0F);  // Upper nibble
    nibbles.add(byte & 0x0F);          // Lower nibble
  }
  return nibbles;
}
```

**POD XT Pro** (raw data):
```dart
// Just send/receive raw bytes
Uint8List patchData = Uint8List(160);
// ... fill with patch data ...
await _midi.sendSysex([0xF0, 0x00, 0x01, 0x0C, 0x03, 0x71, ...patchData, 0xF7]);
```

**Impact**: Using nibble encoding on POD XT Pro:
- Data corruption
- Incorrect patch values
- Hardware confusion

---

## Device Identification

### Sysex Device ID

**POD XT Pro**:
```dart
family = 0x0003   // POD XT family
member = 0x0005   // POD XT Pro
```

**Other Models**:
| Model | Family | Member |
|-------|--------|--------|
| POD XT | 0x0003 | 0x0002 |
| POD XT Pro | 0x0003 | 0x0005 |
| POD XT Live | 0x0003 | 0x000A |
| Bass POD XT Pro | 0x0003 | 0x0007 |
| POD X3 | Different | Different |

**Detection**:
```dart
bool isPodXtPro(int family, int member) {
  return family == 0x0003 && member == 0x0005;
}
```

---

## Expansion Packs

### Pack Flags (Same Across POD XT Family)

| Flag | Name |
|------|------|
| 0x01 | MS - Metal Shop Amp Expansion |
| 0x02 | CC - Collector's Classic Amp Expansion |
| 0x04 | FX - FX Junkie Effects Expansion |
| 0x08 | BX - Bass Expansion |

**Sysex Request**: `F0 00 01 0C 03 0E F7`

**Sysex Response**: `F0 00 01 0C 03 0E [flags] F7`

**Example**:
```
0x0F = All packs (MS + CC + FX + BX)
0x03 = MS + CC only
0x01 = MS only
```

**Note**: This is consistent across POD XT family (XT, XT Pro, XT Live)

---

## Testing Compatibility

### How to Test with Other POD Models

If you want to adapt this app for other POD models:

1. **Change patch size** (`lib/protocol/constants.dart`):
   ```dart
   const programSize = 152;  // For POD XT (non-Pro)
   ```

2. **Test sysex response behavior**:
   - Request patch dump (03 73)
   - Check if response is 03 71 (patch dump) or 03 74 (edit buffer)
   - Adjust `_handleEditBufferDump` logic accordingly

3. **Test 03 72 behavior**:
   - Request single patch
   - Count how many 03 72 markers you receive
   - Adjust bulk import logic if needed

4. **Test patch mapping**:
   - Send program changes for patches 64-127
   - Verify which patches actually load
   - Adjust `encodePatchNumber` if needed

5. **Test data encoding**:
   - Request edit buffer dump
   - Check if data is raw or nibble-encoded
   - Add `decodeNibbles` if needed

6. **Test amp enable**:
   - Toggle amp enable via CC 111
   - Verify if logic is normal or inverted
   - Adjust `inverted` flag if needed

---

## Known Issues

### POD XT Pro Quirks

1. **Slow Response**:
   - Hardware responds slowly to rapid requests
   - Requires 50ms delay between patch requests
   - Can't be sped up significantly

2. **Ambiguous Responses**:
   - Same sysex command (03 74) for edit buffer and patch dumps
   - Requires tracking request context
   - Prone to desync if messages missed

3. **No Bulk Dump**:
   - Must request patches individually
   - Takes ~6.4 seconds for full import
   - No workaround

### Compatibility Warnings

**DO NOT USE THIS APP WITH**:
- ❌ POD XT (non-Pro) - Wrong patch size, will corrupt data
- ❌ POD XT Live - Different protocol, untested
- ❌ POD X3 - Completely different protocol
- ❌ POD HD - Different protocol
- ❌ POD 2.0 - Uses nibble encoding

**ONLY USE WITH**:
- ✅ POD XT Pro (tested and verified)

---

## Reference

### POD-UI Verification

All differences documented here were verified against pod-ui reference implementation:

**Key Files**:
- `/pod-ui-master/mod-xt/src/config.rs` - Device configuration (line 469: patch size)
- `/pod-ui-master/mod-xt/src/handler.rs` - Message handling (lines 292-316: 03 74 quirk)
- `/pod-ui-master/core/src/midi.rs` - MIDI protocol

**pod-ui Comments**:
```rust
// handler.rs:292
// PODxt answers with a buffer dump to either edit buffer dump request or
// a patch dump request... We peek into the current queue to try and determine,
// which buffer comes. This is quite error-prone, since any one message missed
// may incorrectly place the data into the wrong dump ;(
```

This confirms the ambiguous sysex behavior is a known POD XT quirk.

---

## Migration Guide (Other POD Models)

If you want to port this app to other POD models:

### POD XT (non-Pro)

1. Change `programSize` to 152
2. Test sysex behavior (likely same quirks as XT Pro)
3. Test patch mapping (likely same as XT Pro)
4. Test amp enable (likely same as XT Pro)

**Estimated Effort**: 1-2 days

### POD XT Live

1. Change `programSize` (unknown, must test)
2. Test sysex behavior (unknown)
3. Test patch mapping (unknown)
4. Add support for different controls (footswitches, expression pedals)

**Estimated Effort**: 1-2 weeks

### POD X3 / POD HD

1. **Complete protocol rewrite required**
2. Different sysex commands
3. Different patch structure
4. Different parameter mappings

**Estimated Effort**: 1-3 months (essentially a new app)

---

## Summary

POD XT Pro has **5 critical differences** that must be handled correctly:

1. ✅ **160-byte patches** (not 152)
2. ✅ **03 74 response to patch requests** (not 03 71)
3. ✅ **Individual 03 72 markers** (not just at end)
4. ✅ **Non-contiguous patch mapping** (64-127 → 192-255)
5. ✅ **Inverted amp enable** (0 = on, 127 = off)

All five are correctly implemented in this app and verified against pod-ui reference implementation and POD XT Pro hardware.
