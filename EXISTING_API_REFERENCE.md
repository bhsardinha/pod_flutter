# Existing Flutter App API Reference

This document maps the **existing UI expectations** with the **pod-ui Rust implementation** to ensure 1:1 compatibility.

## Service Initialization (main.dart)

```dart
// Expected constructor
final midiService = BleMidiService();
final podController = PodController(midiService);

// Current (broken) constructor - needs fixing
_podController = PodController(
  midi: BleMidiService(),
  storage: PatchStorageService(),
);
```

## PodController Required API

### Properties (Getters)

```dart
// Connection & State
PodConnectionState get connectionState;
EditBuffer get editBuffer;
PatchLibrary get patchLibrary;
int get currentProgram;
bool get patchesSynced;
int get patchesSyncedCount;
bool get editBufferModified;

// Amp/Cab
AmpModel? get ampModel;
CabModel? get cabModel;
int get room;

// Preamp
int get drive;
int get bass;
int get mid;
int get treble;
int get presence;
int get channelVolume;

// Effects
bool get stompEnabled;
StompModel? get stompModel;
bool get modEnabled;
ModModel? get modModel;
int get modSpeed;
int get modMix;
bool get delayEnabled;
DelayModel? get delayModel;
int get delayTime;
int get delayMix;
bool get reverbEnabled;
ReverbModel? get reverbModel;
int get reverbDecay;
int get reverbLevel;

// Gate/Comp/Wah/EQ
bool get noiseGateEnabled;
int get gateThreshold;
bool get compressorEnabled;
bool get wahEnabled;
bool get eqEnabled;
bool get loopEnabled;

// Tempo
int get tempo;
bool get isDelayTempoSynced;
int get currentTempoBpm;
```

### Methods - Connection

```dart
Future<List<MidiDeviceInfo>> scanDevices();
Future<void> connect(MidiDeviceInfo device);
Future<void> disconnect();
```

### Methods - Parameters (Generic)

```dart
int getParameter(CCParam param);
int getParameter16(CCParam msbParam, CCParam lsbParam);
bool getSwitch(CCParam param);
String getPatchName(int program);
bool hasExpansionPack(int packFlag);

Future<void> setParameter(CCParam param, int value);
Future<void> setParameter16(CCParam msbParam, CCParam lsbParam, int value);
Future<void> setSwitch(CCParam param, bool enabled);
```

### Methods - Amp/Cab/Mic

```dart
Future<void> setAmpModel(int id);
Future<void> setAmpModelNoDefaults(int id);
Future<void> setCabModel(int id);
Future<void> setMicModel(int position);
Future<void> setRoom(int value);
```

### Methods - Preamp

```dart
Future<void> setDrive(int value);
Future<void> setBass(int value);
Future<void> setMid(int value);
Future<void> setTreble(int value);
Future<void> setPresence(int value);
Future<void> setChannelVolume(int value);
```

### Methods - Effects

```dart
Future<void> setStompEnabled(bool v);
Future<void> setStompModel(int id);
Future<void> setModEnabled(bool v);
Future<void> setModModel(int id);
Future<void> setModSpeed(int value);
Future<void> setModMix(int value);
Future<void> setDelayEnabled(bool v);
Future<void> setDelayModel(int id);
Future<void> setDelayTime(int value);
Future<void> setDelayMix(int value);
Future<void> setReverbEnabled(bool v);
Future<void> setReverbModel(int id);
Future<void> setReverbDecay(int value);
Future<void> setReverbLevel(int value);
Future<void> setReverbTone(int value);
Future<void> setCompressorEnabled(bool v);
Future<void> setWahEnabled(bool v);
Future<void> setEqEnabled(bool v);
Future<void> setLoopEnabled(bool v);
Future<void> setGateThreshold(int value);
```

### Methods - Tempo

```dart
Future<void> setTempo(int bpm);
Future<void> sendTapTempo();
```

### Methods - Patch Management

```dart
Future<void> selectProgram(int program);
Future<void> refreshEditBuffer();
Future<void> previewOnDevice(Patch patch);
void setPatchName(String name);
Future<bool> saveToCurrentSlot();
Future<bool> saveToDevice(int slot);
Future<void> importAllFromDevice();
```

### Streams

```dart
Stream<PodConnectionState> get onConnectionStateChanged;
Stream<EditBuffer> get onEditBufferChanged;
Stream<int> get onProgramChanged;
Stream<ParameterChange> get onParameterChanged;
Stream<SyncProgress> get onSyncProgress;
Stream<List<MidiDeviceInfo>> get onDevicesChanged;
```

## MidiService Required API

```dart
abstract class MidiService {
  // Streams
  Stream<bool> get onConnectionChanged;
  Stream<List<MidiDeviceInfo>> get onDevicesChanged;

  // Properties
  bool get isConnected;

  // Methods - Connection
  Future<List<MidiDeviceInfo>> scanDevices();
  Future<void> connect(MidiDeviceInfo device);
  Future<void> disconnect();

  // Methods - Sending (SIMPLIFIED - only these 3)
  Future<void> sendCC(int cc, int value);
  Future<void> sendProgramChange(int program);
  Future<void> sendSysex(Uint8List data);

  void dispose();
}

class MidiDeviceInfo {
  final String id;
  final String name;
  final bool isBleMidi;

  MidiDeviceInfo({required this.id, required this.name, this.isBleMidi = false});
}
```

## PatchStorageService Required API

```dart
class PatchStorageService {
  // Single Patch Operations
  Future<String> savePatch(Patch patch, {String? customName});
  Future<Patch> loadPatch(String filename);
  Future<List<SavedPatchInfo>> listPatches();
  Future<void> deletePatch(String filename);

  // Library Operations
  Future<String> saveLibrary(PatchLibrary library, String name);
  Future<PatchLibrary> loadLibrary(String filename);
  Future<List<SavedLibraryInfo>> listLibraries();
  Future<void> deleteLibrary(String filename);

  // SysEx Import/Export
  Future<void> exportPatchSyx(Patch patch, String filepath);
  Future<void> exportLibrarySyx(PatchLibrary library, String filepath);
  Future<Patch> importPatchSyx(String filepath);
  Future<List<Patch>> importLibrarySyx(String filepath);

  // Device Cache
  Future<void> cacheDeviceLibrary(PatchLibrary library);
  Future<PatchLibrary?> loadDeviceCache();
}

class SavedPatchInfo {
  final String filename;
  final String name;
  final DateTime created;
}
```

## Supporting Types

```dart
enum PodConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
  error
}

class ParameterChange {
  final CCParam param;
  final int value;

  ParameterChange({required this.param, required this.value});
}

class SyncProgress {
  final int current;
  final int total;
  final String message;

  double get progress => current / total;
  bool get isComplete => current >= total;
}
```

## Pod-UI Rust 1:1 Mapping

### Core Architecture (from pod-ui)

```
pod-ui Rust                  →  Flutter Dart
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
core/src/midi.rs             →  protocol/sysex.dart
  - MidiMessage enum         →  Encoding/decoding functions
  - to_bytes()               →  encodeXxx() functions
  - from_bytes()             →  decodeXxx() functions

core/src/midi_io.rs          →  services/ble_midi_service.dart
  - MidiIn/MidiOut traits    →  MidiService abstract class
  - autodetect()             →  UDI handshake in connect()

mod-xt/src/handler.rs        →  services/pod_controller.dart
  - PodXtHandler             →  PodController class
  - Queue management         →  _requestQueue
  - Message handlers         →  _handleXxx() methods

core/src/controller.rs       →  Integrated into PodController
  - Parameter values         →  Convenience getters/setters

core/src/edit.rs             →  models/patch.dart (EditBuffer)
  - EditBuffer struct        →  EditBuffer class

core/src/dump.rs             →  models/patch.dart (PatchLibrary)
  - ProgramsDump             →  PatchLibrary class
```

### Critical Implementation Details

1. **NO Bulk Dump**: POD XT Pro doesn't support AllProgramsDump - must loop 0-127
2. **Program Change + Edit Buffer**: For patch switching, send PC then request edit buffer
3. **UDI Handshake**: Must verify device is POD XT Pro (family=0x0002, member=0x0005)
4. **Nibble Packing**: All sysex data uses 7-bit nibbles
5. **Request Queue**: Sequential sysex requests with timeout handling
6. **Buffer Address**: Default = 32 + CC (some params have explicit addresses)

## Constants to Use

```dart
// From protocol/constants.dart
const int programCount = 128;
const int programSize = 160; // POD XT/XT Pro (verified from pod-ui src/config.rs:469)
const int programNameLength = 16;

// Expansion packs
const int kPackMS = 0x01;
const int kPackCC = 0x02;
const int kPackFX = 0x04;
const int kPackBX = 0x08;
```

**Note:** POD XT, POD XT Pro, and POD XT Live all use the same 160-byte patch size.
They differ only in member ID and available controls (see pod-ui src/config.rs).
