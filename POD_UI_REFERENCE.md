# POD-UI Reference Architecture

This document maps pod-ui (Rust) components to Flutter app implementation.

**⚠️ PATCH SIZE CLARIFICATION:**
After reviewing the actual pod-ui source code (`src/config.rs`), **BOTH POD XT and POD XT Pro use the SAME patch size:**
- **POD XT**: 160 bytes (`program_size: 72*2 + 16`)
- **POD XT Pro**: 160 bytes (inherits from POD XT config via `..podxt_config`)
- Structure: 16 bytes name + 144 bytes parameters = **160 bytes total**

**Device Differentiation** (from `src/config.rs`):
- POD XT: `family: 0x0003, member: 0x0002`
- POD XT Pro: `family: 0x0003, member: 0x0005` (adds `loop_enable` control)
- POD XT Live: `family: 0x0003, member: 0x000a` (adds `footswitch_mode` control)

All three models share the same protocol and patch size, differing only in member ID and available controls.

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
│  - Nibble packing/unpacking                                 │
├─────────────────────────────────────────────────────────────┤
│                   Transport Layer                           │
│  midi_io.rs → MidiService (abstract)                        │
│              → BleMidiService (concrete)                    │
│  - UDI handshake (autodetect)                               │
│  - Channel detection                                        │
│  - BLE-MIDI framing                                         │
└─────────────────────────────────────────────────────────────┘
```

## File Mapping

### 1. sysex.dart ← core/src/midi.rs

**Purpose**: Stateless Line6 protocol encoding/decoding

**Key Functions**:
```rust
// Rust
enum MidiMessage {
    UniversalDeviceInquiry { channel },
    UniversalDeviceInquiryResponse { channel, family, member, ver },
    ControlChange { channel, controller, value },
    ProgramChange { channel, program },
    XtEditBufferDumpRequest,
    XtBufferDump { id, data },
    XtPatchDumpRequest { patch },
    XtPatchDump { patch, data },
    XtInstalledPacks { packs },
    // ... etc
}
impl MidiMessage {
    fn to_bytes(&self) -> Vec<u8>;
    fn from_bytes(bytes: &[u8]) -> Result<Self>;
}
```

**Flutter Port**:
```dart
// Stateless helper functions
List<int> encodeUDI(int channel);
List<int> decodeUDIResponse(List<int> bytes);
List<int> encodeControlChange(int channel, int cc, int value);
List<int> encodeProgramChange(int channel, int program);
List<int> encodeEditBufferDumpRequest();
Patch? decodeEditBufferDump(List<int> bytes);
List<int> encodePatchDumpRequest(int patchNum);
Patch? decodePatchDump(List<int> bytes);
List<int> encodeInstalledPacksRequest();
int? decodeInstalledPacks(List<int> bytes);

// Helpers
List<int> packNibbles(List<int> data);
List<int> unpackNibbles(List<int> packed);
```

**Critical Details** (POD XT/XT Pro):
- Line6 Sysex: `[0xF0, 0x00, 0x01, 0x0C, ...command..., 0xF7]`
- UDI Request: `[0xF0, 0x7E, channel, 0x06, 0x01, 0xF7]`
- UDI Response: `[0xF0, 0x7E, channel, 0x06, 0x02, 0x00, 0x01, 0x0C, family, family, member, member, ver..., 0xF7]`
- Edit Buffer Request: `[0xF0, 0x00, 0x01, 0x0C, 0x03, 0x75, 0xF7]`
- Edit Buffer Dump: `[0xF0, 0x00, 0x01, 0x0C, 0x03, 0x74, id, ...160 bytes RAW data..., 0xF7]`
- Patch Request: `[0xF0, 0x00, 0x01, 0x0C, 0x03, 0x73, pp, pp, 0x00, 0x00, 0xF7]` (pp = patch num bytes)
- Patch Dump: `[0xF0, 0x00, 0x01, 0x0C, 0x03, 0x71, pp, pp, id, ...160 bytes RAW data..., 0xF7]`
- Patch Dump End: `[0xF0, 0x00, 0x01, 0x0C, 0x03, 0x72, 0xF7]` (must send after receiving patch dump)
- Store Success: `[0xF0, 0x00, 0x01, 0x0C, 0x03, 0x50, 0xF7]`
- Store Failure: `[0xF0, 0x00, 0x01, 0x0C, 0x03, 0x51, 0xF7]`
- Installed Packs Request: `[0xF0, 0x00, 0x01, 0x0C, 0x03, 0x7D, 0xF7]`
- Installed Packs Response: `[0xF0, 0x00, 0x01, 0x0C, 0x03, 0x7C, id, pp, pp, 0xF7]` (pp = packs bitmap)

**⚠️ CRITICAL - POD XT/XT Pro Data Encoding:**
POD XT and POD XT Pro send **RAW 8-bit data**, NOT nibble-packed data! The 160 bytes are sent directly as-is.
This is verified in handler.rs:552-579 where `control_value_to_buffer` writes raw MIDI values directly to the buffer.

**Nibble Packing** (from midi.rs:42-60):
```rust
// Pack 8-bit data into 7-bit nibbles
// [0xAB, 0xCD] → [0x0A, 0x0B, 0x0C, 0x0D]
fn pack_nibbles(data: &[u8]) -> Vec<u8> {
    data.iter().flat_map(|&b| vec![(b >> 4) & 0x0f, b & 0x0f]).collect()
}

// Unpack 7-bit nibbles back to 8-bit data
fn unpack_nibbles(packed: &[u8]) -> Vec<u8> {
    packed.chunks(2).map(|chunk| (chunk[0] << 4) | chunk[1]).collect()
}
```

**⚠️ NOTE:** Nibble packing functions exist in the codebase but **are NOT used for POD XT/XT Pro patch data**.
POD XT/XT Pro sends the 160-byte patch buffer as raw 8-bit values. See handler.rs:552-579 for verification.

### 2. BleMidiService ← midi_io.rs + usb layer

**Purpose**: BLE-MIDI transport, UDI handshake, packet assembly

**Key Responsibilities**:
1. **Device Scanning**: List BLE-MIDI devices
2. **Connection**: Connect/disconnect to device
3. **UDI Handshake** (from midi_io.rs:314-393):
   ```rust
   async fn autodetect() -> AutodetectResult {
       // 1. Send UDI to device
       send(encode_udi(channel));

       // 2. Listen for 1 second
       let response = await_response(timeout: 1s);

       // 3. Parse UDI response
       let (family, member, version) = decode_udi_response(response);

       // 4. Verify device (POD XT Pro: family=0x0002, member=0x0005)
       if (family != 0x0002 || member != 0x0005) return Error;

       // 5. Return connected device
       return Success { channel, family, member };
   }
   ```
4. **Packet Assembly**: Reassemble fragmented sysex messages
5. **Framing**: BLE-MIDI timestamp handling (not needed per BLE-MIDI spec)
6. **Raw Send/Receive**: Forward to abstract MidiService interface

**Flutter Port**:
```dart
class BleMidiService extends MidiService {
  final FlutterMidiCommand _midiCommand = FlutterMidiCommand();

  // UDI Handshake
  Future<void> performHandshake() async {
    // Send UDI
    final udiBytes = encodeUDI(0x7F); // "all" channel
    await sendRaw(udiBytes);

    // Wait for response (1 second timeout)
    final response = await _waitForUDIResponse(Duration(seconds: 1));

    // Verify POD XT Pro
    final (family, member, version) = decodeUDIResponse(response);
    if (family != 0x0002 || member != 0x0005) {
      throw Exception('Not a POD XT Pro');
    }
  }

  // Packet reassembly for fragmented sysex
  final List<int> _sysexBuffer = [];
  void _handleIncoming(List<int> bytes) {
    for (int byte in bytes) {
      if (byte == 0xF0) _sysexBuffer.clear();
      _sysexBuffer.add(byte);
      if (byte == 0xF7) {
        onMessageReceived.add(List.from(_sysexBuffer));
        _sysexBuffer.clear();
      }
    }
  }
}
```

### 3. MidiService (Abstract) ← MidiIn/MidiOut traits

**Purpose**: Abstract MIDI I/O contract (no UDI, no handshake)

**Interface**:
```dart
abstract class MidiService {
  // Device lifecycle
  Future<List<String>> scanDevices();
  Future<void> connect(String deviceId);
  Future<void> disconnect();
  bool get isConnected;

  // MIDI I/O
  Future<void> sendControlChange(int cc, int value);
  Future<void> sendProgramChange(int program);
  Future<void> sendSysex(List<int> data);

  // Streams (no UDI methods exposed)
  Stream<List<int>> get onMessageReceived;
  Stream<MidiCCMessage> get onControlChange;
  Stream<int> get onProgramChange;
  Stream<List<int>> get onSysex;
}

class MidiCCMessage {
  final int controller;
  final int value;
}
```

**Key Point**: NO UDI methods in abstract interface - handshake is BleMidiService implementation detail.

### 4. PodController ← mod-xt/handler.rs

**Purpose**: Business logic, patch management, queue coordination (NO handshake)

**Key Responsibilities** (from handler.rs):

1. **Message Queue** (lines 59-88):
   ```rust
   // Queue sequential sysex requests
   struct Handler {
       queue: VecDeque<MidiMessage>,
       waiting: Option<WaitingFor>,
   }

   enum WaitingFor {
       EditBufferDump,
       PatchDump(u8),
       InstalledPacks,
   }

   fn queue_request(&mut self, msg: MidiMessage) {
       self.queue.push_back(msg);
       self.process_queue();
   }

   fn process_queue(&mut self) {
       if self.waiting.is_some() { return; } // Already waiting
       if let Some(msg) = self.queue.pop_front() {
           send_midi(msg.to_bytes());
           self.waiting = Some(determine_waiting_state(&msg));
       }
   }

   fn on_response(&mut self, response: MidiMessage) {
       self.waiting = None; // Clear waiting state
       self.process_queue(); // Process next in queue
   }
   ```

2. **Expansion Pack Detection** (lines 133-142):
   ```rust
   fn detect_packs(&mut self) {
       self.queue_request(XtInstalledPacksRequest);
   }

   fn on_installed_packs(&mut self, packs: u8) {
       self.packs = XtPacks::from_bits(packs);
       // MS=0x01, CC=0x02, FX=0x04, BX=0x08
   }
   ```

3. **Patch Loading** (lines 200-250):
   ```rust
   fn load_patch(&mut self, patch_num: u8) {
       // POD XT Pro quirk: use PC + edit buffer request
       self.queue_request(ProgramChange { channel, program: patch_num });
       self.queue_request(XtEditBufferDumpRequest);
   }

   fn on_buffer_dump(&mut self, data: Vec<u8>) {
       let patch = Patch::from_bytes(&data);
       self.edit_buffer = patch;
       self.notify_ui();
   }
   ```

4. **Parameter Changes** (lines 300-320):
   ```rust
   fn set_parameter(&mut self, cc: u8, value: u8) {
       // Update edit buffer
       self.edit_buffer.set_cc(cc, value);

       // Send MIDI CC
       send_midi(ControlChange { channel, controller: cc, value });
   }

   fn on_cc_from_device(&mut self, cc: u8, value: u8) {
       // Update edit buffer
       self.edit_buffer.set_cc(cc, value);

       // Notify UI
       self.notify_parameter_change(cc, value);
   }
   ```

**Flutter Port**:
```dart
class PodController {
  final MidiService _midi;
  final PatchStorageService _storage;

  // State
  Patch? _editBuffer;
  int? _installedPacks;

  // Request queue
  final Queue<_PendingRequest> _requestQueue = Queue();
  _PendingRequest? _currentRequest;

  // NO handshake methods

  // Patch operations
  Future<void> loadPatch(int patchNum) async {
    await _midi.sendProgramChange(patchNum);
    _enqueueRequest(_PendingRequest(
      type: RequestType.editBufferDump,
      send: () => _midi.sendSysex(encodeEditBufferDumpRequest()),
    ));
  }

  Future<void> savePatch(int patchNum) async {
    // Implementation
  }

  // Parameter control
  Future<void> setParameter(CCParam param, int value) async {
    _editBuffer?.setCC(param.cc, value);
    await _midi.sendControlChange(param.cc, value);
  }

  // Expansion packs
  Future<void> detectInstalledPacks() async {
    _enqueueRequest(_PendingRequest(
      type: RequestType.installedPacks,
      send: () => _midi.sendSysex(encodeInstalledPacksRequest()),
    ));
  }

  // Queue management
  void _enqueueRequest(_PendingRequest req) {
    _requestQueue.add(req);
    _processQueue();
  }

  void _processQueue() {
    if (_currentRequest != null) return; // Waiting for response
    if (_requestQueue.isEmpty) return;

    _currentRequest = _requestQueue.removeFirst();
    _currentRequest!.send();
  }

  void _onSysexReceived(List<int> data) {
    if (_currentRequest == null) return;

    // Decode response based on expected type
    switch (_currentRequest!.type) {
      case RequestType.editBufferDump:
        _editBuffer = decodeEditBufferDump(data);
        break;
      case RequestType.patchDump:
        final patch = decodePatchDump(data);
        _storage.storePatch(_currentRequest!.patchNum!, patch);
        break;
      case RequestType.installedPacks:
        _installedPacks = decodeInstalledPacks(data);
        break;
    }

    _currentRequest = null; // Clear waiting state
    _processQueue(); // Process next request
  }
}

enum RequestType {
  editBufferDump,
  patchDump,
  installedPacks,
}

class _PendingRequest {
  final RequestType type;
  final Future<void> Function() send;
  final int? patchNum;
}
```

### 5. PatchStorageService ← edit.rs + dump.rs

**Purpose**: Manage EditBuffer + PatchLibrary (128 patches)

**From edit.rs**:
```rust
struct EditBuffer {
    controller: Controller,  // Parameter values
    raw: Vec<u8>,           // 160 bytes (POD XT/XT Pro)
    modified: bool,
}

impl EditBuffer {
    fn load_from_raw(&mut self, data: &[u8]) {
        self.raw = data.to_vec();
        // Deserialize parameters from raw buffer
        for (name, control) in &self.controller.controls {
            let value = control_value_from_buffer(control, &self.raw);
            self.controller.set(name, value);
        }
    }

    fn name(&self) -> String {
        decode_patch_name(&self.raw[122..138])
    }
}
```

**From dump.rs**:
```rust
struct ProgramsDump {
    data: Vec<Vec<u8>>,      // 128 patches x 160 bytes (POD XT/XT Pro)
    modified: Vec<bool>,     // Track which patches changed
    names: Vec<String>,
}

impl ProgramsDump {
    fn data(&self, index: usize) -> &[u8] {
        &self.data[index]
    }

    fn update_name_from_data(&mut self, index: usize) {
        self.names[index] = decode_patch_name(&self.data[index][122..138]);
    }
}
```

**Flutter Port**:
```dart
class PatchStorageService {
  // Edit buffer (current patch)
  Patch? _editBuffer;
  bool _editBufferModified = false;

  // Patch library (128 stored patches)
  final List<Patch?> _patches = List.filled(128, null);
  final List<bool> _patchesModified = List.filled(128, false);

  // Edit buffer operations
  Patch? get editBuffer => _editBuffer;

  void loadEditBuffer(Patch patch) {
    _editBuffer = patch;
    _editBufferModified = false;
  }

  void updateEditBufferParameter(int cc, int value) {
    _editBuffer?.setCC(cc, value);
    _editBufferModified = true;
  }

  // Patch library operations
  Patch? getPatch(int index) => _patches[index];

  void storePatch(int index, Patch patch) {
    _patches[index] = patch;
    _patchesModified[index] = false;
  }

  List<String> getPatchNames() {
    return _patches.map((p) => p?.name ?? 'Empty').toList();
  }
}
```

## Critical Implementation Notes

### 0. Patch Size Calculation (from src/config.rs:469)

**POD XT and POD XT Pro both use 160 bytes:**
```rust
program_size: 72*2 + 16,  // = 144 + 16 = 160 bytes
```

**Breakdown:**
- 16 bytes: Patch name (space-padded ASCII)
- 144 bytes: Parameter data (72 parameters × 2 bytes avg storage)
- **Total: 160 bytes**

**POD XT Pro Config** (src/config.rs:700-726):
```rust
pub static PODXT_PRO_CONFIG: Lazy<Config> = Lazy::new(|| {
    let podxt_config = PODXT_CONFIG.clone();  // Inherits POD XT config

    Config {
        name: "PODxt Pro".to_string(),
        member: 0x0005,  // Only difference: member ID
        ..podxt_config   // Inherits program_size: 160 bytes
    }
});
```

**Verification** (handler.rs:296-300, 336-340):
```rust
if data.len() != ctx.config.program_size {
    error!("Program size mismatch: expected {}, got {}",
           ctx.config.program_size, data.len());
    return;
}
```

### 1. POD XT/XT Pro Critical Quirk: Patch Dump Response (handler.rs:292-316)

**CRITICAL:** POD XT and POD XT Pro respond to patch dump requests (`03 73`) with **edit buffer dump messages** (`03 74`), NOT patch dump messages (`03 71`)!

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

**Implementation Strategy:**
1. Track which patch number you requested
2. When receiving `03 74` (edit buffer dump), check if you're waiting for a patch dump
3. If yes, treat the `03 74` response as the patch dump for that patch number
4. Store the data to the appropriate patch slot, not the edit buffer

**Flutter Example:**
```dart
// Track expected patch during bulk import
int? _expectedPatchNumber;

// Request patch
_expectedPatchNumber = 42;
await sendSysex(requestPatch(42));

// Handle response
void _handleEditBufferDump(SysexMessage message) {
  if (_expectedPatchNumber != null) {
    // This is actually a patch dump response!
    _patchLibrary[_expectedPatchNumber] = Patch.fromData(data);
    _expectedPatchNumber = null;
  } else {
    // Normal edit buffer update
    _editBuffer = Patch.fromData(data);
  }
}
```

### 2. POD XT Pro Program Change Quirks (from mod-xt/handler.rs)

**Patch Loading** (lines 215-225):
```rust
// POD XT Pro doesn't support direct patch dump requests
// Must use Program Change + Edit Buffer Dump Request
fn load_patch(patch_num: u8) {
    send(ProgramChange { channel, program: patch_num });
    send(XtEditBufferDumpRequest);
}
```

**NO Bulk Dump** (from comments):
```rust
// POD XT Pro does NOT support AllProgramsDump
// Must request patches individually 0-127
```

### 2. Expansion Pack Bitmap (from mod-xt/config.rs:24-29)

```rust
bitflags! {
    struct XtPacks: u8 {
        const MS = 0x01;  // Metal Shop
        const CC = 0x02;  // Collector's Classic
        const FX = 0x04;  // FX Junkie
        const BX = 0x08;  // Bass Expansion
    }
}
```

### 3. Message Flow Example

**User loads patch 42:**
1. `PodController.loadPatch(42)`
2. Queue: `[ProgramChange(42), EditBufferDumpRequest]`
3. Process queue: Send `PC(42)`, wait for nothing (PC doesn't respond)
4. Process queue: Send `EditBufferDumpRequest`, wait for `EditBufferDump`
5. Receive `EditBufferDump` with 160 bytes (POD XT/XT Pro)
6. Decode using `decodeEditBufferDump()`
7. Store in `_editBuffer`
8. Notify UI via stream
9. Queue empty, done

## Testing Strategy

1. **sysex.dart**: Unit tests for encoding/decoding
   - Encode UDI → verify bytes match spec
   - Decode UDI response → verify family/member extraction
   - Encode/decode edit buffer dump
   - Encode/decode patch dump
   - Nibble packing/unpacking

2. **BleMidiService**: Integration tests with mock device
   - UDI handshake flow
   - Packet reassembly for fragmented sysex
   - Connection lifecycle

3. **PodController**: Unit tests with mock MidiService
   - Request queue ordering
   - Parameter updates
   - Patch loading sequence (PC + edit buffer request)

4. **PatchStorageService**: Unit tests
   - Edit buffer state management
   - Patch library CRUD
   - Name extraction

## References

- POD XT Pro MIDI Spec: `pod-ui-master/core/src/midi.rs`
- UDI Handshake: `pod-ui-master/core/src/midi_io.rs:314-393`
- POD XT Handler: `pod-ui-master/mod-xt/src/handler.rs`
- Message Queue: `pod-ui-master/mod-xt/src/handler.rs:59-88`
- Patch Loading: `pod-ui-master/mod-xt/src/handler.rs:200-250`
