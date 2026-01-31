# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## Project Overview

**POD Flutter** is a mobile MIDI controller for the Line 6 POD XT Pro guitar processor. Control all parameters, manage patches, and sync with hardware via Bluetooth MIDI.

- **Platform**: Flutter (iOS, Android, macOS)
- **Target Device**: Line 6 POD XT Pro (NOT POD XT, POD XT Live, or other models)
- **Communication**: BLE-MIDI and USB MIDI
- **Reference**: [pod-ui](https://github.com/arteme/pod-ui) (Rust desktop app)

**IMPORTANT**: pod-ui is the authoritative reference for POD XT Pro protocol behavior. When in doubt, check pod-ui implementation.

---

## Quick Reference

### Documentation

**Comprehensive docs** are in `/docs/`:
- **`ARCHITECTURE.md`** - System design, layers, data flow, architecture decisions
- **`PROTOCOL.md`** - Complete MIDI protocol reference (CC map, sysex commands, patch structure)
- **`FEATURES.md`** - What's implemented, what's missing, roadmap
- **`POD_XT_PRO_DIFFERENCES.md`** - Critical differences from other POD models

**Read these first** before making significant changes!

### Key Files

| File | Purpose | Lines |
|------|---------|-------|
| `lib/services/pod_controller.dart` | High-level POD API, state management | 852 |
| `lib/services/ble_midi_service.dart` | BLE/USB MIDI implementation | 390 |
| `lib/protocol/cc_map.dart` | 70+ CC parameter definitions | 216 |
| `lib/protocol/sysex.dart` | Sysex message builders/parsers | 250 |
| `lib/protocol/effect_param_mappers.dart` | Effect-specific parameter mapping | 701 |
| `lib/models/patch.dart` | Patch data model (160 bytes) | 150 |
| `lib/ui/screens/main_screen.dart` | Primary UI | 708 |

---

## Build & Development

```bash
# Run app (requires device/emulator)
flutter run

# Run tests
flutter test
flutter test test/file.dart  # Single test

# Code quality
flutter analyze
flutter pub get

# Build release
flutter build apk        # Android
flutter build ios        # iOS
flutter build macos      # macOS
```

---

## Coding Standards

### CRITICAL - Deprecated APIs

**NEVER use `withOpacity()`** - it's deprecated and causes precision loss

```dart
// ❌ WRONG - deprecated
Colors.white.withOpacity(0.95)

// ✅ CORRECT
Colors.white.withValues(alpha: 0.95)
```

### pod-ui Reference

**THE pod-ui is the only source of truth** for protocol behavior. Always verify against pod-ui when implementing protocol features.

**pod-ui location**: `/pod-ui-master/` in project root

**Key pod-ui files**:
- `mod-xt/src/config.rs` - POD XT Pro configuration (patch size, parameters)
- `mod-xt/src/handler.rs` - Message handling (quirks, state machine)
- `core/src/midi.rs` - MIDI protocol implementation

---

## Architecture Overview

```
Flutter App (iOS/Android/macOS)
       │
       ├─── UI Layer (35 files)
       │    └─ Screens, Modals, Widgets, Theme
       │
       ├─── Services (3 files)
       │    ├─ PodController (main controller, 852 lines)
       │    ├─ MidiService (abstract interface)
       │    └─ BleMidiService (BLE/USB implementation)
       │
       ├─── Models (6 files)
       │    ├─ Patch (160-byte data structure)
       │    ├─ EditBuffer (current patch)
       │    ├─ PatchLibrary (128 patches)
       │    └─ Amp/Cab/Effect models
       │
       └─── Protocol (5 files)
            ├─ CC Map (70+ parameters)
            ├─ Sysex (message builders/parsers)
            ├─ Constants (commands, device IDs)
            └─ Effect Param Mappers

       ↓ BLE/USB MIDI

BT-MIDI Adapter → POD XT Pro Hardware
```

**See `docs/ARCHITECTURE.md` for complete details.**

---

## POD XT Pro Specifics ⚠️

### CRITICAL DIFFERENCES FROM OTHER POD MODELS

**1. Patch Size**: **160 bytes** (NOT 152 like POD XT)
   - Bytes 0-15: Patch name
   - Bytes 16-159: Parameter data (144 bytes)
   - **Code**: `lib/protocol/constants.dart:38`

**2. Sysex Quirk**: POD responds with `03 74` (edit buffer) for patch requests (`03 73`), NOT `03 71` (patch dump)
   - Must track `_expectedPatchNumber` to determine destination
   - **Code**: `lib/services/pod_controller.dart:_handleEditBufferDump()`

**3. Patch Dump End**: POD sends `03 72` after EACH patch, not just at end of bulk
   - Must ignore `03 72` during bulk import
   - **Code**: `lib/services/pod_controller.dart:_handlePatchDumpEnd()`

**4. Non-Contiguous Mapping**: Patches 64-127 map to MIDI 192-255 (not 64-127)
   - **Code**: `lib/protocol/sysex.dart:encodePatchNumber()`

**5. Inverted Amp Enable**: CC 111 uses inverted logic (0=on, 127=off)
   - **Code**: `lib/protocol/cc_map.dart:ampEnable`

**6. No Manual Mode via MIDI**: Manual mode (PC 0) is **NOT available** on POD XT Pro via MIDI
   - Manual mode is controlled exclusively via **FBV shortboard** (proprietary RJ-45 protocol)
   - FBV shortboard activates manual mode by holding A/B/C/D buttons (no MIDI messages sent)
   - PC 0 does not trigger manual mode on POD XT Pro (only works on POD 2.0 and Bass XT)
   - **Reference**: `pod-ui-master/mod-xt/src/config.rs:473` shows `pc_manual_mode: None`
   - **Conclusion**: Manual mode cannot be triggered via BLE-MIDI/USB-MIDI connection

**See `docs/POD_XT_PRO_DIFFERENCES.md` for complete details.**

---

## MIDI Protocol Quick Reference

### Control Changes (CC)

70+ parameters controlled via MIDI CC:

**Key Parameters**:
- Amp Select (CC 12): 0-106 (107 models)
- Drive, Bass, Mid, Treble, Presence (CC 13-16, 21)
- Cab Select (CC 71): 0-46 (47 models)
- Effect Enables (CC 22, 25, 26, 28, 36, 43, 50, 63)
- EQ (CC 114-121): 4-band parametric
- Tempo (CC 89+90): 14-bit, 30.0-240.0 BPM

**Complete list**: `docs/PROTOCOL.md` or `lib/protocol/cc_map.dart`

### Sysex Commands

**Line 6 Sysex**: `F0 00 01 0C [command...] [data...] F7`

**Key Commands**:
- `03 75` - Request edit buffer dump
- `03 74` - Edit buffer dump response (also used for patch dumps!)
- `03 73` - Request patch dump
- `03 71` - Store patch (send format)
- `03 72` - Patch dump end marker
- `03 50` - Store success
- `03 51` - Store failure
- `03 0E` - Request/response installed packs

**Complete protocol**: `docs/PROTOCOL.md`

---

## Usage Examples

### Connect and Load Edit Buffer

```dart
final midi = BleMidiService();
final pod = PodController(midi);

final devices = await pod.scanDevices();
await pod.connect(devices.first);

// Edit buffer is automatically requested on connection
pod.onEditBufferChanged.listen((buffer) {
  print('Loaded: ${buffer.patch.name}');
});
```

### Change Parameters

```dart
// Direct parameter access
await pod.setParameter(CCParams.drive, 95);

// Convenience setters
await pod.setDrive(95);
await pod.setAmpModel(22);  // Brit J-800
await pod.setDelayEnabled(true);
```

### Program Change

```dart
// Select program 5 (Bank A, patch 6)
await pod.selectProgram(5);

// Listen for program changes
pod.onProgramChanged.listen((program) {
  print('Program: $program');
});
```

### Save Patch

```dart
// Save current edit buffer to slot 10
await pod.savePatchToHardware(10);

// Listen for result
pod.onStoreResult.listen((result) {
  if (result.success) {
    print('Saved to ${result.patchNumber}');
  } else {
    print('Failed: ${result.error}');
  }
});
```

### Bulk Import

```dart
// Import all 128 patches from hardware
await pod.importAllPatchesFromHardware();

// Listen for progress
pod.onSyncProgress.listen((progress) {
  print('${progress.current}/${progress.total}: ${progress.message}');
});

// Takes ~6.4 seconds (50ms × 128 patches)
```

---

## Common Tasks

### Adding a New Parameter

1. **Add to CC map** (`lib/protocol/cc_map.dart`):
   ```dart
   static const myParam = CCParam(
     cc: 99,
     name: 'My Parameter',
     minValue: 0,
     maxValue: 127,
   );
   ```

2. **Add convenience getter/setter** (`lib/services/pod_controller.dart`):
   ```dart
   int get myParam => getParameter(CCParams.myParam);
   Future<void> setMyParam(int value) => setParameter(CCParams.myParam, value);
   ```

3. **Add UI control** (e.g., `lib/ui/screens/main_screen.dart`):
   ```dart
   RotaryKnob(
     label: 'My Param',
     value: _myParam,
     minValue: 0,
     maxValue: 127,
     onChanged: (value) => widget.pod.setMyParam(value.round()),
   )
   ```

### Adding a New Effect Model

1. **Add to effect models** (`lib/models/effect_models.dart`):
   ```dart
   static const myEffect = EffectModel(
     id: 99,
     name: 'My Effect',
     params: [
       EffectParam(name: 'Param 1', maxValue: 127),
       EffectParam(name: 'Param 2', maxValue: 100),
     ],
     pack: 'FX',  // or null for stock
     basedOn: 'Real Effect Name',
   );
   ```

2. **Add to mapper** (`lib/protocol/effect_param_mappers.dart`):
   ```dart
   // In appropriate mapper (StompParamMapper, ModParamMapper, etc.)
   @override
   List<EffectModel> get models => [
     // ... existing models
     EffectModels.myEffect,
   ];
   ```

3. **Test** by selecting the effect in the UI

### Special Effect Implementations

#### Rotary Effects (2-Position Speed Switch)

**Rotary Drum + Horn** and **Rotary Drum** modulation effects use a simplified 2-position speed control instead of the full range (0.1-15.0 Hz):

- **SLOW**: 990 MIDI value (~1.0 Hz)
- **FAST**: 8684 MIDI value (~8.0 Hz)

**Implementation** (`lib/protocol/effect_param_mappers.dart`):
```dart
// MsbLsbParamMapping with position-based support
MsbLsbParamMapping(
  label: 'SPEED',
  msbParam: PodXtCC.modNoteSelect,
  lsbParam: PodXtCC.modSpeedLsb,
  formatter: (v) => v < 2200 ? 'SLOW' : 'FAST',
  minValue: 0,      // UI position: 0 = SLOW, 1 = FAST
  maxValue: 1,
  positionLabels: ['SLOW', 'FAST'],       // Display labels
  positionValues: [990, 8684],            // MIDI values
  isNoteSelectBased: false,
)
```

**UI Handling** (`lib/ui/widgets/lcd_knob_array.dart`):
- 2-position switches (range ≤ 1) use **direction-based** movement
- No thresholds or accumulation - just up/down detection
- Drag up → FAST, Drag down → SLOW

**Reference**: `src/config.rs` lines 131-132 show `.skip()` for speed parameter, indicating simplified control

### Debugging MIDI Issues

1. **Enable verbose logging**:
   ```dart
   // In ble_midi_service.dart
   print('MIDI RX: ${data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
   ```

2. **Check connection state**:
   ```dart
   pod.onConnectionStateChanged.listen((connected) {
     print('Connected: $connected');
   });
   ```

3. **Monitor parameter changes**:
   ```dart
   pod.onParameterChanged.listen((change) {
     print('${change.param.name} = ${change.value}');
   });
   ```

4. **Verify sysex responses**:
   ```dart
   _midi.onSysex.listen((message) {
     print('Sysex: ${message.command.map((b) => b.toRadixString(16)).join(' ')}');
   });
   ```

---

## Known Issues & Limitations

### Hardware Limitations

- **No bulk dump**: Must request patches individually (~6.4s for 128 patches)
- **Slow response**: Requires 50ms delay between patch requests
- **Ambiguous responses**: Same sysex (03 74) for edit buffer and patch dumps
- **No patch rename sysex**: Must save entire patch to update name

### Software Limitations

- **No patch caching**: Re-imports on every app launch
- **Limited error recovery**: No retry logic for failed sysex
- **Single device**: Can only connect to one POD at a time
- **No undo/redo**: Parameter changes can't be undone

**See `docs/FEATURES.md` for complete list and roadmap.**

---

## Testing

### Current Coverage

- ⚠️ Only basic widget_test.dart exists
- ⚠️ No unit tests for protocol layer
- ⚠️ No integration tests for PodController
- ⚠️ No mock MIDI service

### Testing Locally

```bash
# Run existing tests
flutter test

# Test on device
flutter run

# Test bulk import
# (In app: Connect → Open connection modal → Tap "Import All Patches")

# Test parameter changes
# (Change knobs in app, verify on hardware)
```

### Manual Testing Checklist

- [ ] Connect via BLE MIDI
- [ ] Edit buffer loads on connection
- [ ] Change amp model (verify on hardware)
- [ ] Change effect parameters (verify on hardware)
- [ ] Select different program (verify loads correctly)
- [ ] Bulk import all 128 patches (progress updates correctly)
- [ ] Save patch to hardware (success/failure feedback)
- [ ] Hardware parameter changes update UI
- [ ] Disconnect and reconnect (state preserved)

---

## Troubleshooting

### "Can't connect to POD"

1. Check Bluetooth is enabled
2. Verify POD is powered on
3. Check BT-MIDI adapter is connected to POD MIDI port
4. Verify adapter is discoverable (check adapter manual)
5. Try restarting app

### "Bulk import stalls"

1. Verify POD is responding (check hardware)
2. Check connection (LED on adapter)
3. Try again (sometimes hardware is slow)
4. Check logs for sysex errors

### "Wrong patch loads"

1. Verify POD XT Pro (NOT POD XT or other model)
2. Check patch mapping code (`encodePatchNumber`)
3. Verify `_expectedPatchNumber` tracking

### "Patches corrupted after import"

1. **CRITICAL**: Verify you're using POD XT Pro (160 bytes), not POD XT (152 bytes)
2. Check `programSize` constant
3. Verify hardware device ID (0x0005 for POD XT Pro)

### "Amp enable button backwards"

1. Check `inverted` flag on `ampEnable` parameter
2. Verify inversion logic in `Patch.getSwitch()` and `Patch.setSwitch()`

**See `docs/PROTOCOL.md` for more troubleshooting.**

---

## Contributing

### Before Making Changes

1. **Read the docs**: Start with `docs/ARCHITECTURE.md` and `docs/PROTOCOL.md`
2. **Understand the quirks**: Read `docs/POD_XT_PRO_DIFFERENCES.md`
3. **Check pod-ui**: Verify behavior against reference implementation
4. **Test on hardware**: Always test with actual POD XT Pro

### Making Changes

1. **Keep layer separation**: Don't mix protocol/service/UI logic
2. **Maintain pod-ui compatibility**: Match reference behavior exactly
3. **Handle quirks correctly**: Don't break critical sysex handling
4. **Test thoroughly**: Verify on real hardware, not just emulator

### Pull Request Checklist

- [ ] Code follows existing style
- [ ] All POD XT Pro quirks still handled correctly
- [ ] Tested on real POD XT Pro hardware
- [ ] No regressions in existing features
- [ ] Documentation updated if needed
- [ ] No deprecated APIs used (e.g., `withOpacity`)

---

## Additional Resources

### Documentation

- `docs/ARCHITECTURE.md` - Complete architecture documentation
- `docs/PROTOCOL.md` - Full MIDI protocol reference
- `docs/FEATURES.md` - Feature list and roadmap
- `docs/POD_XT_PRO_DIFFERENCES.md` - POD XT Pro specific differences

### Reference Implementation

- pod-ui (Rust/GTK): `/pod-ui-master/`
  - `mod-xt/src/config.rs` - Configuration
  - `mod-xt/src/handler.rs` - Message handling
  - `core/src/midi.rs` - MIDI protocol

### Line 6 Resources

- POD XT Pro Manual (MIDI Implementation Chart)
- Line 6 MIDI specification (not publicly available, reverse-engineered)

---

## Summary

**POD Flutter** is a production-ready mobile controller for POD XT Pro. The codebase is well-structured with clear layer separation and comprehensive POD XT Pro quirk handling.

**Key points**:
- ✅ Complete parameter control (70+ CC parameters)
- ✅ Full patch management (128 patches)
- ✅ All POD XT Pro quirks correctly handled
- ✅ Stream-based reactive architecture
- ✅ Production-quality UI with POD hardware appearance
- ⚠️ Requires POD XT Pro specifically (NOT other models)
- ⚠️ Limited test coverage (needs improvement)

**Before implementing new features**, read the comprehensive documentation in `/docs/` and verify against pod-ui reference implementation.
