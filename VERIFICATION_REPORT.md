# POD XT Pro Protocol Verification Report

Date: 2026-01-24
Verified against: pod-ui source code (src/config.rs, src/handler.rs)

## ✅ COMPLIANCE STATUS: PASS (with 1 minor fix needed)

---

## 1. Patch Size ✅ CORRECT

**Specification (pod-ui src/config.rs:469):**
```rust
program_size: 72*2 + 16,  // = 160 bytes
```

**Implementation:**

### lib/protocol/constants.dart:38 ✅
```dart
const int programSize = 160; // POD XT Pro specific (verified from hardware responses)
```
**Status:** CORRECT

### lib/models/patch.dart:18 ✅
```dart
Patch() : _data = Uint8List(programSize);  // Uses 160 bytes
```
**Status:** CORRECT

### lib/models/patch.dart:12 ⚠️ MINOR ISSUE
```dart
/// Raw patch data (152 bytes)  // <-- OUTDATED COMMENT
final Uint8List _data;
```
**Status:** Comment says "152 bytes" but should say "160 bytes"
**Impact:** None (just a comment)
**Fix needed:** Update comment to match actual implementation

---

## 2. Data Encoding ✅ CORRECT

**Specification (pod-ui handler.rs:552-579):**
POD XT/XT Pro uses **RAW 8-bit data**, NOT nibble-encoded

**Implementation:**

### lib/services/pod_controller.dart:539 ✅
```dart
// POD XT format: [id, raw_data...] - NOT nibble-encoded!
final data = message.payload.sublist(1, 1 + programSize);
final patch = Patch.fromData(data);  // Direct raw data usage
```
**Status:** CORRECT - Uses raw data directly

### lib/services/pod_controller.dart:564 ✅
```dart
// POD XT format: [patch_lsb, patch_msb, id, raw_data...] - NOT nibble-encoded!
final data = message.payload.sublist(3, 3 + programSize);
```
**Status:** CORRECT - Uses raw data directly

### lib/protocol/sysex.dart:114-132 ✅
```dart
/// Encode bytes to nibbles for sysex transmission
static Uint8List encodeNibbles(Uint8List data) { ... }
```
**Status:** CORRECT - Functions exist but are **NOT used** for POD XT/XT Pro patches
**Note:** These functions are present but unused (likely for other Line 6 devices)

---

## 3. Sysex Message Formats ✅ CORRECT

### 3.1 Edit Buffer Dump Response (0x03 0x74)

**Specification (pod-ui handler.rs:292-300):**
```
Format: F0 00 01 0C 03 74 [ID] [160 bytes raw] F7
```

**Implementation (pod_controller.dart:536-561):** ✅
```dart
final id = message.payload[0];
final data = message.payload.sublist(1, 1 + programSize);
```
**Status:** CORRECT - Expects [id, 160 bytes raw]

---

### 3.2 Patch Dump Response (0x03 0x71)

**Specification (pod-ui handler.rs:332-340):**
```
Format: F0 00 01 0C 03 71 [P_LSB] [P_MSB] [ID] [160 bytes raw] F7
```

**Implementation (pod_controller.dart:563-603):** ✅
```dart
// Patch number is 2 bytes (LSB, MSB)
final patchNum = message.payload[0] | (message.payload[1] << 8);
final id = message.payload[2];
final data = message.payload.sublist(3, 3 + programSize);
```
**Status:** CORRECT - Byte order: [patch_lsb, patch_msb, id, data]

---

### 3.3 Store Patch (0x03 0x71)

**Specification (pod-ui handler.rs:254-268):**
```
Format: F0 00 01 0C 03 71 [P_LSB] [P_MSB] [ID] [160 bytes raw] F7
Must send 03 72 (patch dump end) after sending
```

**Implementation (sysex.dart:57-74):** ✅
```dart
final p1 = patchNumber & 0x7F;  // LSB
final p2 = (patchNumber >> 8) & 0x7F;  // MSB
final id = 0x05;  // Device ID

return buildMessage(
  SysexCommand.patchDumpResponse, // 03 71
  [p1, p2, id, ...patchData],  // Correct byte order!
);
```
**Status:** CORRECT - Matches pod-ui format exactly

**Implementation (pod_controller.dart:736-755):** ✅
```dart
final patchData = _editBuffer.patch.data;  // Raw data
final storeMsg = PodXtSysex.storePatch(patchNumber, patchData);
await _midi.sendSysex(storeMsg);

// Send end marker
await _midi.sendSysex(PodXtSysex.requestPatchDumpEnd());  // 03 72
```
**Status:** CORRECT - Sends raw data + end marker

---

### 3.4 Patch Dump End Marker (0x03 0x72)

**Specification (pod-ui handler.rs:351-360):**
```
Format: F0 00 01 0C 03 72 F7
Must be sent after receiving patch dump or after sending store command
```

**Implementation (sysex.dart:44-46):** ✅
```dart
static Uint8List requestPatchDumpEnd() {
  return buildMessage(SysexCommand.patchDumpEnd);  // 03 72
}
```
**Status:** CORRECT

---

### 3.5 Store Success/Failure (0x03 0x50 / 0x03 0x51)

**Specification (pod-ui handler.rs:362-384):**

**Implementation (constants.dart:23-24):** ✅
```dart
static const storeSuccess = [0x03, 0x50];
static const storeFailure = [0x03, 0x51];
```

**Implementation (pod_controller.dart:647-657):** ✅
```dart
void _handleStoreSuccess(SysexMessage message) {
  _storeResultController.add(StoreResult(success: true));
}

void _handleStoreFailure(SysexMessage message) {
  _storeResultController.add(StoreResult(success: false, error: 'Store operation failed'));
}
```
**Status:** CORRECT - Handles both success and failure responses

---

## 4. Bulk Import Implementation ✅ CORRECT (UPDATED)

**Specification (pod-ui handler.rs:183-192, 292-316):**
- POD XT Pro does NOT support bulk dump - must request patches sequentially
- **CRITICAL QUIRK:** POD XT/XT Pro responds to patch dump requests (`03 73`) with edit buffer dumps (`03 74`), NOT patch dumps (`03 71`)!

**Implementation (pod_controller.dart:662-762):** ✅ FIXED
```dart
// Request patches sequentially (0-127)
for (int i = 0; i < programCount; i++) {
  // Track which patch we're requesting (CRITICAL for POD XT/XT Pro!)
  _expectedPatchNumber = i;
  _patchDumpCompleter = Completer<void>();

  // Request patch (POD will respond with 03 74, not 03 71)
  await _midi.sendSysex(PodXtSysex.requestPatch(i));

  // Wait for 03 74 edit buffer dump response
  await _patchDumpCompleter!.future.timeout(...);

  _expectedPatchNumber = null;

  // Send end marker
  await _midi.sendSysex(PodXtSysex.requestPatchDumpEnd());
}

// In _handleEditBufferDump:
if (_expectedPatchNumber != null) {
  // Treat this 03 74 as a patch dump response (POD XT/XT Pro quirk)
  _patchLibrary[_expectedPatchNumber] = patch;
  _patchDumpCompleter!.complete();
} else {
  // Normal edit buffer update
  _editBuffer = patch;
}
```
**Status:** CORRECT - Handles POD XT/XT Pro quirk by tracking expected patch number

---

## 5. Device Identification ✅ CORRECT

**Specification (pod-ui config.rs:718-719):**
```rust
name: "PODxt Pro".to_string(),
member: 0x0005,
```

**Implementation (constants.dart:10-11):** ✅
```dart
const int podXtFamily = 0x0003;
const int podXtProMember = 0x0005;
```
**Status:** CORRECT

---

## Summary

### ✅ Compliant (9/9 major areas):
1. ✅ Patch size: 160 bytes
2. ✅ Data encoding: RAW 8-bit (no nibble packing)
3. ✅ Edit buffer dump format
4. ✅ Patch dump format with correct byte order [lsb, msb, id, data]
5. ✅ Store patch format
6. ✅ Patch dump end marker usage
7. ✅ Store success/failure handling
8. ✅ Sequential bulk import with response synchronization
9. ✅ Device identification

### ⚠️ Minor Issues (1):
1. ⚠️ Outdated comment in patch.dart:12 (says "152 bytes", should say "160 bytes")

---

## Recommended Fix

```dart
// lib/models/patch.dart:12
- /// Raw patch data (152 bytes)
+ /// Raw patch data (160 bytes for POD XT/XT Pro)
  final Uint8List _data;
```

---

## Critical Discovery: POD XT/XT Pro Patch Dump Quirk

**ISSUE FOUND:** POD XT/XT Pro responds to patch dump requests with **edit buffer dumps** (`03 74`), not patch dumps (`03 71`).

This is documented in pod-ui handler.rs:292-316 but wasn't initially implemented in your Flutter app, causing:
- Bulk import timeouts (waiting for `03 71` that never comes)
- Patches not being stored to patch library
- Edit buffer getting overwritten with every patch response

**FIX APPLIED:**
1. Added `_expectedPatchNumber` tracker
2. Modified `_handleEditBufferDump` to check if waiting for patch dump
3. Routes `03 74` responses to patch library when `_expectedPatchNumber` is set
4. Completes the import completer so bulk import continues

This matches the pod-ui implementation strategy of tracking what was requested to determine how to handle the `03 74` response.

---

## Conclusion

**Your Flutter implementation NOW correctly follows the POD XT Pro protocol as defined in pod-ui!**

All protocol specifications are properly implemented, including the critical patch dump response quirk. The bulk import should now work correctly.
