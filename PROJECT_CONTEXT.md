# POD Flutter - Project Context

## Overview

A Flutter mobile-first application to control the **Line 6 POD XT Pro** guitar processor via Bluetooth MIDI. This is a spinoff inspired by [pod-ui](https://github.com/arteme/pod-ui), focusing on a modern touch-friendly UI for mobile devices.

## Goals

- **Mobile-first**: Primarily targets iOS and Android
- **Bluetooth MIDI**: Direct connection to POD XT Pro via BLE-MIDI adapter (no computer required)
- **Better UI**: Modern, touch-optimized interface (pod-ui uses GTK which is dated)
- **Focused scope**: POD XT Pro only (simplifies protocol implementation)

## Architecture

```
┌──────────────┐      BLE-MIDI       ┌─────────────────┐      MIDI      ┌──────────────┐
│  Phone App   │  ────────────────►  │  BT-MIDI Adapter │  ──────────►  │  POD XT Pro  │
│  (Flutter)   │                     │  (CME WIDI, etc) │               │              │
└──────────────┘                     └─────────────────┘               └──────────────┘
```

## Reference Project

**pod-ui**: https://github.com/arteme/pod-ui
- Rust + GTK desktop app
- Supports PODxt series (including PODxt Pro)
- Contains sysex message structures and parameter mappings
- Supports .l6t and .lib patch files

### Key things to extract from pod-ui:
1. Sysex message format for PODxt Pro
2. Parameter IDs (amp models, drive, EQ, effects, etc.)
3. Patch data structure
4. .l6t file format (if we want import/export)

## Technical Stack

| Component | Technology |
|-----------|------------|
| Framework | Flutter 3.x |
| MIDI | `flutter_midi_command` package |
| Connection | Bluetooth MIDI (BLE-MIDI) |
| State Management | TBD (Provider, Riverpod, or Bloc) |
| Target Platforms | iOS, Android (macOS as bonus) |

## Recommended BLE-MIDI Adapters

- CME WIDI Jack / WIDI Master
- Yamaha MD-BT01
- Quicco Sound mi.1

## Next Steps

1. **Add dependencies**: `flutter_midi_command` for Bluetooth MIDI
2. **Explore pod-ui**: Extract protocol details from the Rust source
3. **Project structure**: Set up folders for models, services, UI
4. **MIDI service**: Implement BLE-MIDI connection and basic communication
5. **Protocol layer**: Implement PODxt Pro sysex commands
6. **UI**: Build parameter controls and patch management

## Suggested Project Structure

```
lib/
├── main.dart
├── models/
│   ├── patch.dart           # Patch data model
│   ├── parameter.dart       # Parameter definitions
│   └── device.dart          # POD device model
├── services/
│   ├── midi_service.dart    # BLE-MIDI connection & communication
│   ├── sysex_service.dart   # PODxt Pro sysex protocol
│   └── patch_service.dart   # Patch management
├── ui/
│   ├── screens/
│   │   ├── home_screen.dart
│   │   ├── connection_screen.dart
│   │   └── patch_editor_screen.dart
│   └── widgets/
│       ├── knob.dart        # Rotary knob control
│       ├── amp_selector.dart
│       └── effect_block.dart
└── utils/
    └── constants.dart       # MIDI constants, parameter IDs
```

## PODxt Pro Key Features to Implement

- [ ] Bluetooth MIDI connection
- [ ] Program Change (patch selection)
- [ ] Real-time parameter editing
- [ ] Amp model selection
- [ ] Stomp/Mod/Delay/Reverb effects control
- [ ] Patch upload/download
- [ ] Patch library management
- [ ] .l6t file import/export (optional)

## Resources

- [flutter_midi_command](https://pub.dev/packages/flutter_midi_command) - Flutter MIDI package
- [pod-ui source](https://github.com/arteme/pod-ui) - Protocol reference
- [Line 6 MIDI documentation](https://line6.com/support/page/kb/) - Official specs (if available)
- [BLE-MIDI spec](https://www.midi.org/specifications/midi-transports-specifications/specification-for-midi-over-bluetooth-low-energy-ble-midi) - Bluetooth MIDI standard
