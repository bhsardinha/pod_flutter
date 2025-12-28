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
│  - patch.dart: Patch/EditBuffer data structures (152 bytes)         │
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
| `lib/models/patch.dart` | Patch data model (152 bytes per patch) |

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
```
