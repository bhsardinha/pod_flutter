# Architecture Documentation

## Overview

POD Flutter is a mobile MIDI controller for the Line 6 POD XT Pro guitar processor. The app uses a layered architecture with clear separation between protocol, business logic, and presentation layers.

## System Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Flutter Application                          │
│                          (iOS/Android/macOS)                         │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                ┌─────────────────┼─────────────────┐
                │                 │                 │
                ▼                 ▼                 ▼
    ┌──────────────────┐  ┌──────────────┐  ┌────────────────┐
    │   UI Layer       │  │   Services   │  │    Models      │
    │   (44 files)     │  │   (3 files)  │  │   (6 files)    │
    └──────────────────┘  └──────────────┘  └────────────────┘
                                  │
                    ┌─────────────┴─────────────┐
                    │                           │
                    ▼                           ▼
          ┌──────────────────┐       ┌──────────────────┐
          │  PodController   │       │   MidiService    │
          │  (852 lines)     │◄──────│   (abstract)     │
          │                  │       │                  │
          │  - EditBuffer    │       │  ┌─────────────┐ │
          │  - PatchLibrary  │       │  │ BLE-MIDI    │ │
          │  - State Mgmt    │       │  │ Service     │ │
          └──────────────────┘       │  │ (390 lines) │ │
                    │                │  └─────────────┘ │
                    │                └──────────────────┘
                    │                           │
                    ▼                           ▼
          ┌──────────────────┐       ┌──────────────────┐
          │  Protocol Layer  │       │  flutter_midi_   │
          │   (5 files)      │       │    command       │
          │                  │       │   (package)      │
          │  - cc_map.dart   │       └──────────────────┘
          │  - sysex.dart    │                  │
          │  - constants.dart│                  │
          └──────────────────┘                  │
                                                 ▼
                                    ┌──────────────────────┐
                                    │   BLE/USB MIDI       │
                                    │   (OS Level)         │
                                    └──────────────────────┘
                                                 │
                                                 ▼
                                    ┌──────────────────────┐
                                    │  BT-MIDI Adapter     │
                                    │  (CME WIDI, etc)     │
                                    └──────────────────────┘
                                                 │
                                          MIDI DIN Cable
                                                 │
                                                 ▼
                                    ┌──────────────────────┐
                                    │   POD XT Pro         │
                                    │   Hardware           │
                                    └──────────────────────┘
```

## Layer Responsibilities

### 1. Protocol Layer (`lib/protocol/`)

**Purpose**: Low-level MIDI protocol implementation for POD XT Pro

**Files**:
- `constants.dart` (49 lines) - Sysex commands, device IDs, expansion packs
- `cc_map.dart` (216 lines) - All 70+ CC parameter definitions
- `sysex.dart` (250 lines) - Sysex message builders/parsers
- `effect_param_mappers.dart` (519 lines) - Effect-specific parameter mapping

**Key Abstractions**:
```dart
// Parameter definition with buffer mapping
class CCParam {
  final String name;
  final int cc;              // MIDI CC number
  final int? address;        // Buffer address for storage
  final int minValue;
  final int maxValue;
  final bool inverted;
}

// Sysex message wrapper
class SysexMessage {
  final List<int> command;   // e.g., [0x03, 0x74]
  final Uint8List payload;   // Raw data

  bool get isEditBufferDump;
  bool get isPatchDump;
  // ... type checkers
}
```

**Responsibilities**:
- Define all MIDI CC parameters with buffer addresses
- Build/parse sysex messages
- Handle POD XT Pro specific encoding (no nibble encoding)
- Map effect models to their dynamic parameters

**No Dependencies**: Pure Dart, no Flutter or business logic dependencies

---

### 2. Models Layer (`lib/models/`)

**Purpose**: Data structures representing POD XT Pro state

**Files**:
- `patch.dart` (150 lines) - Patch/EditBuffer/PatchLibrary
- `amp_models.dart` (180 lines) - 107 amp models
- `cab_models.dart` (120 lines) - 47 cab + 8 mic models
- `effect_models.dart` (796 lines) - All effect models (Stomp/Mod/Delay/Reverb/Wah)
- `app_settings.dart` (65 lines) - User preferences (amp display mode, grid items, tempo scrolling, warn on unsaved changes, disable A.I.R.)

**Key Abstractions**:
```dart
// Single patch (160 bytes)
class Patch {
  final Uint8List _data;     // Raw patch data
  bool modified;             // Dirty flag

  String get/set name;
  int getValue(CCParam);
  void setValue(CCParam, value);
  int getValue16(msb, lsb);  // 14-bit values
  bool getSwitch(CCParam);   // Boolean parameters
}

// Current working patch
class EditBuffer {
  Patch patch;
  int? sourceProgram;        // Where it came from
  bool modified;             // Edited since load?
}

// All 128 hardware patches
class PatchLibrary {
  final List<Patch> patches; // 128 patches
  bool get hasModifications;
}
```

**Responsibilities**:
- Represent POD XT Pro data structures (160-byte patches)
- Handle parameter encoding/decoding
- Track modification state
- Support 14-bit parameters (tempo, delay time, mod speed)

**Dependencies**: Protocol layer only (for CCParam definitions)

---

### 3. Services Layer (`lib/services/`)

**Purpose**: Business logic and MIDI communication

#### 3.1 MidiService (Abstract)

**File**: `midi_service.dart` (232 lines)

**Purpose**: Defines MIDI communication interface

```dart
abstract class MidiService {
  // Connection management
  Future<List<MidiDevice>> scanDevices();
  Future<void> connect(MidiDevice device);
  Future<void> disconnect();

  // Message sending
  Future<void> sendControlChange(int channel, int cc, int value);
  Future<void> sendProgramChange(int channel, int program);
  Future<void> sendSysex(List<int> data);

  // Event streams
  Stream<MidiMessage> get onMessage;
  Stream<ControlChangeMessage> get onControlChange;
  Stream<ProgramChangeMessage> get onProgramChange;
  Stream<SysexMessage> get onSysex;
  Stream<bool> get onConnectionChanged;
  Stream<List<MidiDevice>> get onDevicesChanged;
}
```

**Key Features**:
- Abstract interface (dependency injection)
- Stream-based reactive architecture
- Message parsing and routing
- Device management

#### 3.2 BleMidiService (Concrete)

**File**: `ble_midi_service.dart` (390 lines)

**Purpose**: BLE/USB MIDI implementation using `flutter_midi_command`

**Key Features**:
- Multi-packet sysex buffering (BLE-MIDI packets are limited to 20 bytes)
- Auto-reconnection handling
- Device hot-plug detection
- USB MIDI support (in addition to BLE)

**Implementation Details**:
```dart
class BleMidiService extends MidiService {
  final MidiCommand _midiCommand = MidiCommand();

  // Multi-packet sysex buffering
  List<int>? _sysexBuffer;
  bool _receivingSysex = false;

  // Connection state
  MidiDevice? _connectedDevice;

  // Stream controllers
  final _messageController = StreamController<MidiMessage>.broadcast();
  final _sysexController = StreamController<SysexMessage>.broadcast();
  // ...
}
```

**Sysex Buffering Logic**:
1. Detect sysex start (0xF0)
2. Buffer all subsequent bytes
3. Detect sysex end (0xF7)
4. Parse complete message and emit

#### 3.3 PodController (Main Controller)

**File**: `pod_controller.dart` (852 lines)

**Purpose**: High-level API for controlling POD XT Pro

**Architecture**:
```dart
class PodController {
  // Dependencies
  final MidiService _midi;

  // State
  EditBuffer _editBuffer;
  PatchLibrary _patchLibrary;
  int? _currentProgram;
  int _installedPacks = 0;
  bool _patchesSynced = false;

  // Bulk import state
  int? _expectedPatchNumber;
  bool _bulkImportInProgress = false;

  // Stream controllers (7 broadcast streams)
  final _connectionStateController = StreamController<bool>.broadcast();
  final _editBufferController = StreamController<EditBuffer>.broadcast();
  final _programChangedController = StreamController<int>.broadcast();
  final _parameterChangedController = StreamController<ParameterChange>.broadcast();
  final _syncProgressController = StreamController<SyncProgress>.broadcast();
  final _storeResultController = StreamController<StoreResult>.broadcast();
  final _tunerDataController = StreamController<TunerData>.broadcast();
}
```

**Key Responsibilities**:

1. **Connection Management**:
   - Device scanning/connection
   - Initial state synchronization
   - Device hot-plug handling

2. **Parameter Control**:
   - Read/write any CC parameter
   - Convenience accessors for all 70+ parameters
   - 14-bit parameter support
   - Boolean switch handling

3. **Patch Management**:
   - Edit buffer synchronization
   - Program selection (with program change)
   - Patch library management (128 patches)
   - Bulk import from hardware
   - Save to hardware

4. **State Synchronization**:
   - Listen for parameter changes from hardware
   - Emit events for UI updates
   - Track edit buffer modifications

5. **Tuner Control**:
   - Enable/disable tuner mode (CC 69)
   - Request tuner data (note and offset)
   - Parse tuner sysex responses
   - Emit tuner data events

6. **POD XT Pro Quirks**:
   - Handle 03 74 as patch dump response
   - Ignore individual 03 72 markers during bulk import
   - Non-contiguous patch mapping (64-127 → 192-255)
   - Inverted amp enable parameter

**Event Streams**:
```dart
// Connection state (true = connected)
Stream<bool> get onConnectionStateChanged;

// Edit buffer updates (after load/modify)
Stream<EditBuffer> get onEditBufferChanged;

// Program number changes
Stream<int> get onProgramChanged;

// Individual parameter changes (from hardware)
Stream<ParameterChange> get onParameterChanged;

// Bulk import progress
Stream<SyncProgress> get onSyncProgress;

// Store operation results
Stream<StoreResult> get onStoreResult;

// Tuner data updates (note, cents, frequency)
Stream<TunerData> get onTunerData;
```

**Critical Bulk Import Logic**:
```dart
Future<void> importAllPatchesFromHardware() async {
  _bulkImportInProgress = true;

  for (int i = 0; i < 128; i++) {
    // Track expected patch
    _expectedPatchNumber = i;

    // Request patch (POD responds with 03 74 edit buffer dump!)
    await _midi.sendSysex(requestPatch(i));

    // Wait for response (using Completer)
    await _waitForPatch(i);

    // POD sends 03 72 after each patch - ignore it!
  }

  _bulkImportInProgress = false;
  _patchesSynced = true;
}

// Edit buffer dump handler
void _handleEditBufferDump(SysexMessage message) {
  final patch = Patch.fromData(message.payload.sublist(1)); // Skip device ID

  if (_expectedPatchNumber != null) {
    // This is a patch dump response!
    _patchLibrary[_expectedPatchNumber] = patch;
    _expectedPatchNumber = null;
  } else {
    // This is an actual edit buffer update
    _editBuffer.patch = patch;
    _editBufferController.add(_editBuffer);
  }
}
```

---

### 4. UI Layer (`lib/ui/`)

**Purpose**: User interface components

#### Structure

```
lib/ui/
├── screens/              # Main screens
│   ├── main_screen.dart         (708 lines) - Primary controller UI
│   └── settings_screen.dart     - User preferences
├── tabs/                 # Tab views
│   ├── local_library_tab.dart   - Local patch library storage
│   └── pod_presets_tab.dart     - POD hardware presets
├── sections/             # UI sections (modular components)
│   ├── amp_selector_section.dart
│   ├── tone_controls_section.dart
│   ├── eq_section.dart
│   ├── effects_columns_section.dart
│   └── control_bar_section.dart
├── modals/              # Modal dialogs
│   ├── connection_modal.dart
│   ├── patch_list_modal.dart        - Tabbed (Local Library / POD Presets)
│   ├── amp_modal.dart
│   ├── cab_modal.dart
│   ├── mic_modal.dart
│   ├── gate_modal.dart
│   ├── comp_modal.dart
│   ├── effect_modal.dart
│   ├── tuner_modal.dart             - 3-segment tuner display
│   ├── unsaved_changes_modal.dart   - Save/discard/cancel dialog
│   └── pod_model_selector_modal.dart
├── widgets/             # Reusable widgets
│   ├── rotary_knob.dart
│   ├── vertical_fader.dart
│   ├── eq_knob.dart
│   ├── effect_button.dart
│   ├── tap_button.dart
│   ├── dot_matrix_lcd.dart
│   └── ... (9 more)
├── theme/
│   └── pod_theme.dart
└── utils/
    ├── value_formatters.dart
    ├── eq_frequency_mapper.dart
    └── color_extensions.dart
```

#### Main Screen Layout

```
┌─────────────────────────────────────────────────────────────┐
│  Connection Status                                Settings  │
├─────────────────────────────────────────────────────────────┤
│  [Amp Selector]  [Gate] [Amp Enable]                       │
│   Cabinet    Mic                                            │
├─────────────────────────────────────────────────────────────┤
│  [Drive] [Bass] [Mid] [Treble] [Presence] [Vol] [Reverb]  │
│   Tone Controls (7 rotary knobs)                           │
├─────────────────────────────────────────────────────────────┤
│  [Stomp] [EQ] [Comp]  │  [EQ Band 1] [Band 2] [Band 3]    │
│  [Mod] [Delay] [Rev]  │  [Band 4] (8 EQ knobs)            │
│   Effect Buttons      │   4-band Parametric EQ            │
├─────────────────────────────────────────────────────────────┤
│  [Wah] [Loop]              [Patch: 01A User Patch]  [Tap] │
│   Control Bar                                              │
└─────────────────────────────────────────────────────────────┘
```

#### Key UI Components

**RotaryKnob** (13,790 lines - most complex widget):
- Drag-based rotation
- Value display
- Min/max indicators
- Custom graphics (POD-style appearance)
- Supports custom formatters

**EffectButton**:
- Effect enable/disable toggle
- LED indicator (on/off/bypassed)
- Opens effect modal on tap
- Displays effect name

**DotMatrixLCD**:
- POD-style LCD display
- Renders text with dot-matrix font
- Supports scrolling for long text

**EffectModal** (Generic):
- Dynamically shows parameters based on selected effect model
- Uses `EffectParamMapper` to get model-specific params
- Supports tempo sync for Mod/Delay
- 14-bit parameter handling (Speed, Time)

#### Stream-Based UI Updates

All UI components listen to `PodController` streams:

```dart
class _MainScreenState extends State<MainScreen> {
  late final StreamSubscription<EditBuffer> _editBufferSub;
  late final StreamSubscription<ParameterChange> _paramChangeSub;
  late final StreamSubscription<int> _programSub;

  @override
  void initState() {
    super.initState();

    // Listen for edit buffer changes
    _editBufferSub = widget.pod.onEditBufferChanged.listen((buffer) {
      setState(() {
        // Update all UI state from buffer
      });
    });

    // Listen for parameter changes from hardware
    _paramChangeSub = widget.pod.onParameterChanged.listen((change) {
      setState(() {
        // Update specific parameter
      });
    });

    // Listen for program changes
    _programSub = widget.pod.onProgramChanged.listen((program) {
      setState(() {
        _currentProgram = program;
      });
    });
  }
}
```

---

## Data Flow

### Parameter Change Flow (User → Hardware)

```
User Drags Knob
       │
       ▼
RotaryKnob Widget
  onChanged callback
       │
       ▼
PodController.setParameter(CCParam, value)
       │
       ├─> Update EditBuffer
       │     │
       │     └─> Emit onEditBufferChanged
       │           │
       │           └─> UI updates (setState)
       │
       └─> MidiService.sendControlChange(cc, value)
             │
             └─> flutter_midi_command
                   │
                   └─> BLE/USB MIDI
                         │
                         └─> POD XT Pro Hardware
```

### Parameter Change Flow (Hardware → User)

```
POD XT Pro Hardware
  (user turns knob)
       │
       ▼
BLE/USB MIDI
       │
       ▼
flutter_midi_command
       │
       ▼
BleMidiService
  onMidiSetupChanged stream
       │
       ▼
MidiService.onControlChange
       │
       ▼
PodController
  listens to onControlChange
       │
       ├─> Update EditBuffer
       │
       └─> Emit onParameterChanged
             │
             └─> UI listens to stream
                   │
                   └─> setState() updates knob position
```

### Bulk Import Flow

```
User Taps "Import All Patches"
       │
       ▼
PodController.importAllPatchesFromHardware()
       │
       └─> Loop 0-127:
             │
             ├─> Set _expectedPatchNumber = i
             │
             ├─> Send sysex: requestPatch(i)
             │     │
             │     └─> MidiService.sendSysex([F0 00 01 0C 03 73 ...])
             │           │
             │           └─> POD receives patch request
             │                 │
             │                 └─> POD responds with 03 74 (Edit Buffer Dump!)
             │                       │
             │                       └─> BleMidiService receives sysex
             │                             │
             │                             └─> PodController._handleEditBufferDump()
             │                                   │
             │                                   ├─> Check _expectedPatchNumber
             │                                   │     │
             │                                   │     └─> Store to _patchLibrary[i]
             │                                   │
             │                                   └─> Emit onSyncProgress
             │                                         │
             │                                         └─> UI updates progress bar
             │
             ├─> Wait for patch via Completer
             │
             ├─> POD sends 03 72 (Patch Dump End)
             │     │
             │     └─> Ignored during bulk import!
             │
             └─> Next patch...

After all 128 patches:
  └─> Set _bulkImportInProgress = false
      └─> Set _patchesSynced = true
          └─> Emit final onSyncProgress (complete)
```

---

## Critical Design Decisions

### 1. Dependency Injection

`PodController` accepts `MidiService` interface, not concrete implementation:

```dart
final midi = BleMidiService();
final pod = PodController(midi);
```

**Benefits**:
- Easy to swap MIDI implementations
- Testable (can inject mock MIDI service)
- Decoupled architecture

### 2. Stream-Based Reactive Architecture

All state changes emit via streams, not callbacks:

```dart
// Good (stream-based)
pod.onEditBufferChanged.listen((buffer) { ... });

// Bad (callback-based)
pod.setEditBufferCallback((buffer) { ... });
```

**Benefits**:
- Multiple listeners per event
- Built-in backpressure handling
- Composable with StreamBuilder widgets
- Async-friendly

### 3. Immutable Models with Copy-on-Write

Patches are value objects:

```dart
Patch copy() {
  return Patch.fromData(Uint8List.fromList(_data));
}
```

**Benefits**:
- Predictable state management
- Easy undo/redo (if implemented)
- Safe sharing across isolates

### 4. Protocol Layer Independence

Protocol layer has zero Flutter dependencies:

```dart
// Pure Dart classes
class CCParam { ... }
class SysexMessage { ... }
```

**Benefits**:
- Can be unit tested without Flutter
- Can be extracted to separate package
- Reusable in other projects (CLI tools, etc.)

### 5. Effect Parameter Mapping via Strategy Pattern

Each effect type has a mapper:

```dart
abstract class EffectParamMapper {
  List<EffectParamMapping> mapModelParams(int modelId);
}

class StompParamMapper extends EffectParamMapper { ... }
class ModParamMapper extends EffectParamMapper { ... }
```

**Benefits**:
- Centralized effect parameter logic
- Easy to add new effect types
- Reusable across UI components

---

## Performance Considerations

### 1. Stream Broadcasting

All controllers use broadcast streams:

```dart
final _controller = StreamController<T>.broadcast();
```

**Reason**: Multiple UI widgets listen to same events

### 2. Sysex Buffering

BLE-MIDI packets are limited to 20 bytes, but POD XT Pro patches are 160 bytes:

```dart
if (byte == 0xF0) {
  _receivingSysex = true;
  _sysexBuffer = [0xF0];
} else if (_receivingSysex) {
  _sysexBuffer!.add(byte);
  if (byte == 0xF7) {
    _emitSysex(_sysexBuffer!);
    _receivingSysex = false;
  }
}
```

**Impact**: Sysex messages may arrive over multiple packets (handled transparently)

### 3. Bulk Import Throttling

50ms delay between patch requests:

```dart
await Future.delayed(Duration(milliseconds: 50));
```

**Reason**: POD XT Pro can't handle rapid-fire requests

**Total time**: 50ms × 128 = 6.4 seconds

### 4. UI Rebuild Optimization

Use `const` constructors where possible:

```dart
const Text('Static Label')  // Won't rebuild
```

**Note**: Many widgets could benefit from further optimization (currently rebuild on every parameter change)

---

## Testing Strategy (Proposed)

### Unit Tests
- Protocol layer (sysex parsing, CC mapping)
- Models (patch encoding/decoding)
- Value formatters

### Integration Tests
- PodController with mock MidiService
- Parameter read/write flow
- Bulk import logic

### Widget Tests
- RotaryKnob interaction
- Effect button states
- Modal dialogs

### End-to-End Tests
- Connect to hardware
- Read edit buffer
- Change parameters
- Save patch

---

## Build & Deployment

### Supported Platforms
- ✅ iOS (BLE + USB MIDI via CoreMIDI)
- ✅ Android (BLE + USB MIDI via android.media.midi)
- ✅ macOS (USB MIDI via CoreMIDI)
- ⚠️ Linux (limited MIDI support)
- ⚠️ Windows (limited MIDI support)
- ❌ Web (no MIDI support)

### Dependencies
- `flutter_midi_command: ^0.5.0` - BLE/USB MIDI
- `shared_preferences: ^2.5.4` - Settings persistence

### Build Commands
```bash
flutter build apk           # Android release
flutter build ios           # iOS release
flutter build macos         # macOS release
```

---

## Future Architecture Enhancements

### 1. State Management Migration

Consider migrating to `riverpod` or `bloc` for more structured state management:

```dart
// Current: Manual StreamController management
final _controller = StreamController<T>.broadcast();

// Proposed: Riverpod
final editBufferProvider = StreamProvider<EditBuffer>(...);
```

**Benefits**: Automatic disposal, better testing, less boilerplate

### 2. Repository Pattern

Extract patch persistence to separate layer:

```dart
abstract class PatchRepository {
  Future<PatchLibrary> loadPatches();
  Future<void> savePatches(PatchLibrary library);
}

class HardwarePatchRepository implements PatchRepository { ... }
class FilePatchRepository implements PatchRepository { ... }
```

**Benefits**: Offline mode, backup/restore, file import/export

### 3. Command Pattern for Undo/Redo

Wrap parameter changes in commands:

```dart
abstract class Command {
  void execute();
  void undo();
}

class SetParameterCommand extends Command {
  final CCParam param;
  final int oldValue;
  final int newValue;

  @override
  void execute() => pod.setParameter(param, newValue);

  @override
  void undo() => pod.setParameter(param, oldValue);
}
```

### 4. Service Locator / DI Framework

Use `get_it` for dependency injection:

```dart
// Setup
getIt.registerSingleton<MidiService>(BleMidiService());
getIt.registerFactory<PodController>(() => PodController(getIt<MidiService>()));

// Usage
final pod = getIt<PodController>();
```

**Benefits**: Cleaner initialization, better testing, easier mocking
