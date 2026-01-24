# Patch Management Implementation Plan

**Status**: Real-time CC control is PERFECT - DO NOT TOUCH
**Goal**: Add Import/Export/Save/Bulk Download functionality matching Line 6 Edit and pod-ui

---

## Current State Analysis

### ✅ Working Perfectly (DO NOT MODIFY)
- Real-time CC parameter control
- Edit buffer loading (`F0 00 01 0C 03 75 F7`)
- Program change handling
- Sysex packet reassembly
- Parameter change streams

### ✅ Infrastructure Ready (Just needs wiring)
- Patch dump handler (`_handlePatchDump`)
- Store success/failure detection (`isStoreSuccess`, `isStoreFailure`)
- Sync progress tracking (`SyncProgress`)
- Patch library storage (`_patchLibrary`)

### ❌ Missing Implementation
1. **Bulk Import** - Download all 128 patches from hardware
2. **Save to Hardware** - Store current edit buffer to a slot
3. **Export** - Save patch library to local file
4. **Import** - Load patch library from local file

---

## Protocol Reference (Line 6 Edit + pod-ui)

### 1. Request Single Patch

**Request Format**:
```
F0 00 01 0C 03 73 00 XX 00 00 F7
└─┬─┘ └──┬──┘ └┬─┘ └───┬───┘ └┬┘
START  Line6   CMD   Patch    END
        ID   Request  Number
                      + padding
```

**Key Points**:
- Command: `03 73` (patch dump request)
- `XX` = patch number (0x00 to 0x7F for patches 0-127)
- **TWO `0x00` padding bytes** (NOT bank/program split!)
- Example: Patch 5 → `F0 00 01 0C 03 73 00 05 00 00 F7`

**Current Implementation (WRONG)**:
```dart
// lib/protocol/sysex.dart lines 29-33
static Uint8List requestPatch(int patchNumber) {
  final bank = patchNumber ~/ 128;  // ❌ WRONG
  final program = patchNumber % 128; // ❌ WRONG
  return buildMessage(SysexCommand.patchDumpRequest, [bank, program]);
}
```

**Correct Implementation**:
```dart
static Uint8List requestPatch(int patchNumber) {
  return buildMessage(
    SysexCommand.patchDumpRequest,
    [0x00, patchNumber & 0x7F, 0x00, 0x00],
  );
}
```

### 2. Patch Dump Response

**Response Format**:
```
F0 00 01 0C 03 74 05 PP PP ...160 bytes... F7
└─┬─┘ └──┬──┘ └┬─┘ └┬┘ └┬─┘ └────┬────┘
START  Line6   DUMP ID  Patch#  Patch Data
        ID    Resp         (2 bytes)
```

**Decoding Patch Number**:
```dart
// Current implementation in pod_controller.dart:562 (CORRECT)
final patchNum = message.payload[0] | (message.payload[1] << 8);
```

**After Each Response, Send End Marker**:
```
F0 00 01 0C 03 72 F7
```

### 3. Store Patch to Hardware

**Store Command Format**:
```
F0 00 01 0C 03 71 05 P1 P2 ...160 bytes... F7
└─┬─┘ └──┬──┘ └┬─┘ └┬┘ └─┬──┘ └────┬────┘
START  Line6  STORE ID  Patch#  Patch Data
        ID    Cmd          (7-bit encoded)
```

**Encoding Patch Number** (from pod-ui backup):
```dart
static Uint8List storePatch(int patchNumber, Uint8List patchData) {
  assert(patchData.length == 160, 'Patch data must be 160 bytes');
  assert(patchNumber >= 0 && patchNumber < 128, 'Patch number 0-127');

  final p1 = patchNumber & 0x7F;        // LSB (bits 0-6)
  final p2 = (patchNumber >> 7) & 0x7F; // MSB (bits 7-13)

  return buildMessage(
    SysexCommand.patchDumpResponse, // 03 71
    [0x05, p1, p2, ...patchData],
  );
}
```

**After Sending Store, Send End Marker**:
```
F0 00 01 0C 03 72 F7
```

**Wait for Response**:
```
Success: F0 00 01 0C 03 50 F7
Failure: F0 00 01 0C 03 51 F7
```

---

## Implementation Steps

### Step 1: Fix `requestPatch()` in sysex.dart

**File**: `lib/protocol/sysex.dart`

**Current (lines 28-34)**:
```dart
/// Request a specific patch dump
static Uint8List requestPatch(int patchNumber) {
  // Patch number is sent as 2 bytes (bank, program)
  final bank = patchNumber ~/ 128;
  final program = patchNumber % 128;
  return buildMessage(SysexCommand.patchDumpRequest, [bank, program]);
}
```

**Replace with**:
```dart
/// Request a specific patch dump
///
/// Format: F0 00 01 0C 03 73 00 XX 00 00 F7
/// where XX = patch number (0-127)
static Uint8List requestPatch(int patchNumber) {
  assert(patchNumber >= 0 && patchNumber < programCount);
  return buildMessage(
    SysexCommand.patchDumpRequest,
    [0x00, patchNumber & 0x7F, 0x00, 0x00],
  );
}
```

### Step 2: Add `storePatch()` and `requestPatchDumpEnd()` to sysex.dart

**Add after `requestPatch()` method**:
```dart
/// Request patch dump end marker
///
/// Must be sent after receiving a patch dump response
/// Format: F0 00 01 0C 03 72 F7
static Uint8List requestPatchDumpEnd() {
  return buildMessage(SysexCommand.patchDumpEnd);
}

/// Store patch to hardware slot
///
/// Format: F0 00 01 0C 03 71 05 P1 P2 ...160 bytes... F7
/// After sending, must send patchDumpEnd marker
///
/// Returns the complete store message
static Uint8List storePatch(int patchNumber, Uint8List patchData) {
  assert(patchNumber >= 0 && patchNumber < programCount,
    'Patch number must be 0-127');
  assert(patchData.length == programSize,
    'Patch data must be $programSize bytes');

  // Encode patch number as two 7-bit values
  final p1 = patchNumber & 0x7F;        // LSB (bits 0-6)
  final p2 = (patchNumber >> 7) & 0x7F; // MSB (bits 7-13)

  return buildMessage(
    SysexCommand.patchDumpResponse, // Same command as dump (03 71)
    [0x05, p1, p2, ...patchData],  // 05 = device ID (broadcast)
  );
}
```

### Step 3: Add Bulk Import to pod_controller.dart

**Add after existing methods** (~line 640):

```dart
// ═══════════════════════════════════════════════════════════════════════════
// BULK OPERATIONS - Import/Export
// ═══════════════════════════════════════════════════════════════════════════

/// Import all 128 patches from hardware (sequential, not parallel)
///
/// Matches Line 6 Edit behavior: request each patch individually,
/// send end marker after each response
Future<void> importAllPatchesFromHardware() async {
  if (!isConnected) {
    throw StateError('Not connected to device');
  }

  print('POD: Starting bulk import of all 128 patches...');

  // Reset sync state
  _patchesSynced = false;
  _patchesSyncedCount = 0;
  _syncProgressController.add(
    SyncProgress(0, programCount, 'Starting import...'),
  );

  // Request patches sequentially (0-127)
  for (int i = 0; i < programCount; i++) {
    try {
      print('POD: Requesting patch $i...');

      // Request patch
      await _midi.sendSysex(PodXtSysex.requestPatch(i));

      // Wait for response (patch dump handler will update progress)
      // Give hardware time to respond
      await Future.delayed(const Duration(milliseconds: 100));

      // Send end marker after receiving response
      await _midi.sendSysex(PodXtSysex.requestPatchDumpEnd());

      // Brief delay before next request
      await Future.delayed(const Duration(milliseconds: 50));

    } catch (e) {
      print('POD: Error importing patch $i: $e');
      // Continue with next patch
    }
  }

  print('POD: Bulk import complete! Imported $_patchesSyncedCount patches');
  _patchesSynced = true;
  _syncProgressController.add(
    SyncProgress(programCount, programCount, 'Import complete!'),
  );
}

/// Save current edit buffer to a hardware slot
///
/// Sends store command, end marker, then waits for success/failure response
Future<void> savePatchToHardware(int patchNumber) async {
  if (!isConnected) {
    throw StateError('Not connected to device');
  }

  if (_editBuffer == null || _editBuffer!.patch == null) {
    throw StateError('No edit buffer to save');
  }

  if (patchNumber < 0 || patchNumber >= programCount) {
    throw ArgumentError('Patch number must be 0-${programCount - 1}');
  }

  print('POD: Saving to hardware slot $patchNumber...');

  // Get patch data
  final patchData = _editBuffer!.patch!.toData();

  // Build and send store command
  final storeMsg = PodXtSysex.storePatch(patchNumber, patchData);
  await _midi.sendSysex(storeMsg);

  // Send end marker
  await _midi.sendSysex(PodXtSysex.requestPatchDumpEnd());

  // Wait for success/failure response (handled in _handleSysex)
  // The response will be 03 50 (success) or 03 51 (failure)
  print('POD: Store command sent, waiting for confirmation...');
}
```

### Step 4: Add Store Response Handling to _handleSysex()

**Update `_handleSysex()` method** (around line 504):

```dart
void _handleSysex(SysexMessage message) {
  // Debug: print received sysex
  print('POD Sysex received: $message');

  if (message.isEditBufferDump) {
    print('  -> Edit buffer dump!');
    _handleEditBufferDump(message);
  } else if (message.isPatchDump) {
    print('  -> Patch dump');
    _handlePatchDump(message);
  } else if (message.isPatchDumpEnd) {
    print('  -> Patch dump end');
    _handlePatchDumpEnd(message);
  } else if (message.isInstalledPacks) {
    print('  -> Installed packs');
    _handleInstalledPacks(message);
  } else if (message.isProgramState) {
    print('  -> Program state');
    _handleProgramState(message);
  } else if (message.isStoreSuccess) {  // ADD THIS
    print('  -> Store SUCCESS!');
    _handleStoreSuccess(message);
  } else if (message.isStoreFailure) {  // ADD THIS
    print('  -> Store FAILURE!');
    _handleStoreFailure(message);
  }
}

/// Handle store success response (03 50)
void _handleStoreSuccess(SysexMessage message) {
  print('POD: Patch stored successfully!');
  // Could emit event to UI here if needed
  // _storeResultController.add(StoreResult.success);
}

/// Handle store failure response (03 51)
void _handleStoreFailure(SysexMessage message) {
  print('POD: ERROR - Patch store failed!');
  // Could emit event to UI here if needed
  // _storeResultController.add(StoreResult.failure);
}
```

### Step 5: Update _requestInitialState() to Enable Bulk Import

**Replace TODO at line 464** with:

```dart
Future<void> _requestInitialState() async {
  // Wait a moment for the connection to stabilize
  await Future.delayed(const Duration(milliseconds: 500));

  print('POD: Requesting initial state...');

  // Reset sync state
  _patchesSynced = false;
  _patchesSyncedCount = 0;

  // Request expansion packs info
  await _midi.requestInstalledPacks();
  await Future.delayed(const Duration(milliseconds: 100));

  // Request current program state (to get correct program number)
  print('POD: Requesting program state...');
  await _midi.requestProgramState();
  await Future.delayed(const Duration(milliseconds: 400));

  // Request current edit buffer
  print('POD: Requesting edit buffer...');
  await _midi.requestEditBuffer();

  // Don't auto-import all patches on connect
  // User must explicitly call importAllPatchesFromHardware()
  _syncProgressController.add(
    SyncProgress(0, programCount, 'Ready (call import to download patches)'),
  );
}
```

### Step 6: Export/Import to Local Files

**The `PatchStorageService` likely already exists**. Verify it has:

```dart
class PatchStorageService {
  /// Export patch library to .podlib file
  Future<void> exportLibrary(PatchLibrary library, String path);

  /// Import patch library from .podlib file
  Future<PatchLibrary> importLibrary(String path);

  /// Export single patch to .podpatch file
  Future<void> exportPatch(Patch patch, String path);

  /// Import single patch from .podpatch file
  Future<Patch> importPatch(String path);
}
```

---

## Testing Checklist

### 1. Fix Request Patch Format
- [ ] Update `requestPatch()` in sysex.dart
- [ ] Test requesting patch 0: Should send `F0 00 01 0C 03 73 00 00 00 00 F7`
- [ ] Test requesting patch 127: Should send `F0 00 01 0C 03 73 00 7F 00 00 F7`

### 2. Bulk Import
- [ ] Add `importAllPatchesFromHardware()` method
- [ ] Test importing all 128 patches sequentially
- [ ] Verify progress updates work
- [ ] Verify all patches stored in `_patchLibrary`
- [ ] Verify patch names display correctly

### 3. Save to Hardware
- [ ] Add `storePatch()` to sysex.dart
- [ ] Add `savePatchToHardware()` to pod_controller.dart
- [ ] Test storing current edit buffer to slot 0
- [ ] Verify store success message received
- [ ] Load patch from hardware and verify it matches

### 4. Export/Import Files
- [ ] Verify PatchStorageService exists and works
- [ ] Test exporting patch library to file
- [ ] Test importing patch library from file
- [ ] Verify data integrity (checksums if available)

---

## Summary

**What Changes**:
1. Fix `requestPatch()` format (wrong padding bytes)
2. Add `storePatch()` and `requestPatchDumpEnd()` to sysex.dart
3. Add `importAllPatchesFromHardware()` to pod_controller.dart
4. Add `savePatchToHardware()` to pod_controller.dart
5. Add store success/failure handlers to `_handleSysex()`

**What Stays the Same** (DO NOT MODIFY):
- Real-time CC control ✅
- Edit buffer handling ✅
- Connection management ✅
- Sysex packet reassembly ✅

**Key Protocol Details**:
- Patch requests use `[0x00, patchNum, 0x00, 0x00]` format
- Must send `03 72` end marker after each patch response
- Store uses 7-bit encoding: `[p1, p2]` where `p1 = num & 0x7F, p2 = (num >> 7) & 0x7F`
- All operations are SEQUENTIAL, never parallel

This matches Line 6 Edit and pod-ui exactly! 🎸
