# POD Flutter

A mobile MIDI controller for the Line 6 POD XT Pro guitar processor.

Control all parameters, manage patches, and sync with your POD XT Pro hardware via Bluetooth MIDI.

---

## Features

- **Complete Parameter Control**: All 70+ parameters (amp, cab, effects, EQ, etc.)
- **Patch Management**: Browse, load, edit, and save all 128 patches
- **Bulk Import**: Sync entire patch library from hardware
- **Real-Time Sync**: Bi-directional parameter updates
- **POD Hardware UI**: Authentic POD appearance with rotary knobs, LCD display, LED indicators
- **BLE & USB MIDI**: Connect via Bluetooth or USB MIDI adapter
- **Expansion Pack Support**: MS, CC, FX, BX expansion models

---

## Screenshots

*(Screenshots would go here)*

---

## Requirements

### Hardware

- **Line 6 POD XT Pro** (this app is specifically for POD XT Pro, NOT other POD models)
- **BT-MIDI Adapter** (e.g., CME WIDI Master, Yamaha MD-BT01) OR
- **USB MIDI Connection** (iOS/macOS via Camera Connection Kit, Android via USB OTG)

### Software

- **iOS**: 12.0 or later
- **Android**: 5.0 (API 21) or later
- **macOS**: 10.14 or later

---

## Installation

### iOS (via TestFlight)

*(TestFlight link would go here when available)*

### Android (APK)

1. Download the latest APK from [Releases](https://github.com/yourusername/pod_flutter/releases)
2. Enable "Install from Unknown Sources" in Android settings
3. Install the APK

### Build from Source

```bash
# Clone repository
git clone https://github.com/yourusername/pod_flutter.git
cd pod_flutter

# Install dependencies
flutter pub get

# Run on connected device
flutter run

# Or build release
flutter build apk        # Android
flutter build ios        # iOS
flutter build macos      # macOS
```

---

## Quick Start

1. **Connect Hardware**:
   - Power on your POD XT Pro
   - Connect BT-MIDI adapter to POD MIDI port (or use USB MIDI)
   - Ensure adapter is discoverable (check adapter manual)

2. **Launch App**:
   - Open POD Flutter
   - Tap connection icon (top-left)
   - Select your MIDI device from the list
   - Tap "Connect"

3. **Load Patches** (Optional):
   - Tap "Import All Patches" to sync entire patch library (~6 seconds)
   - Or just use edit buffer (current patch loads automatically)

4. **Start Playing**:
   - Turn knobs to adjust parameters
   - Tap effect buttons to enable/disable effects
   - Use patch browser to load different patches
   - Save changes to hardware via patch list modal

---

## Usage

### Main Screen

```
┌─────────────────────────────────────────────┐
│  [Connection Status]          [Settings]    │
├─────────────────────────────────────────────┤
│  [Amp: Brit J-800]  [Gate] [Amp Enable]    │
│   Cabinet    Mic                            │
├─────────────────────────────────────────────┤
│  [Drive] [Bass] [Mid] [Treble] [Pres] ...  │
│   Tone Controls                             │
├─────────────────────────────────────────────┤
│  [Stomp] [EQ] [Comp]  │  [EQ Bands 1-4]    │
│  [Mod] [Delay] [Rev]  │                     │
├─────────────────────────────────────────────┤
│  [Wah] [Loop]    [Patch: 01A]    [Tap]     │
└─────────────────────────────────────────────┘
```

### Controls

- **Rotary Knobs**: Drag vertically to adjust value
- **Effect Buttons**: Tap to toggle on/off, long-press/tap to edit parameters
- **Patch Browser**: Tap patch name to open 128-patch browser
- **Tap Tempo**: Tap button to set tempo
- **Settings**: Amp name display mode, UI preferences

### Amp Selection

Tap the amp name to open amp selector:
- **List View** or **Grid View** (toggle in top-right)
- **Filter by Pack**: All, Stock, MS, CC, BX
- **Display Modes**: Factory names, Real amp names, or Both
- **Load Options**: Load with defaults or preserve current settings

### Effects

Tap any effect button to open effect editor:
- **Model Selection**: Choose from available models
- **Dynamic Parameters**: Knobs change based on selected model
- **Tempo Sync**: Enable tempo sync for Mod/Delay (note divisions)
- **Enable/Bypass**: Toggle effect on/off

### Patch Management

Tap patch name to open patch browser:
- **Browse**: All 128 patches organized by bank (A/B/C/D)
- **Load**: Tap patch to load to edit buffer
- **Save**: Long-press patch to save current edit buffer
- **Modified Indicator**: Shows which patches have been edited

---

## Documentation

Comprehensive documentation is available in the `/docs/` folder:

- **[ARCHITECTURE.md](docs/ARCHITECTURE.md)** - System design, layers, data flow
- **[PROTOCOL.md](docs/PROTOCOL.md)** - MIDI protocol reference
- **[FEATURES.md](docs/FEATURES.md)** - Feature list, limitations, roadmap
- **[POD_XT_PRO_DIFFERENCES.md](docs/POD_XT_PRO_DIFFERENCES.md)** - POD XT Pro specifics
- **[CLAUDE.md](CLAUDE.md)** - Developer guide (for Claude Code)

---

## Known Limitations

### Hardware Limitations

- **Bulk Import Speed**: Takes ~6.4 seconds to import all 128 patches (hardware limitation)
- **No Bulk Dump**: POD XT Pro doesn't support bulk dump; must request patches individually
- **Response Delays**: Hardware requires 50ms delay between patch requests

### Software Limitations

- **No Patch Caching**: Patches must be re-imported on each app launch
- **Single Device**: Can only connect to one POD at a time
- **No Undo/Redo**: Parameter changes can't be undone (planned feature)
- **Landscape Only**: Portrait mode not supported (planned feature)

See [FEATURES.md](docs/FEATURES.md) for complete list.

---

## Roadmap

### Short-Term
- Patch caching (avoid re-import on launch)
- Tuner display
- Error recovery improvements

### Medium-Term
- Patch export/import (.syx files)
- Undo/redo
- A/B comparison mode

### Long-Term
- Tags/favorites
- MIDI learn
- Portrait mode support
- Effect visualizations

See [FEATURES.md](docs/FEATURES.md) for full roadmap.

---

## Troubleshooting

### Can't Connect

1. Verify Bluetooth is enabled
2. Check POD is powered on
3. Verify BT-MIDI adapter is connected to POD MIDI port
4. Check adapter is discoverable (refer to adapter manual)
5. Try restarting the app

### Parameters Not Updating

1. Check connection status (top-left icon should be green)
2. Verify MIDI messages are being sent (check POD display for changes)
3. Try disconnecting and reconnecting

### Wrong Patches Loading

1. **CRITICAL**: Verify you're using POD XT Pro (NOT POD XT or other model)
2. This app is specifically for POD XT Pro and won't work correctly with other models

### Corrupted Patches After Import

1. **CRITICAL**: Verify device is POD XT Pro (160-byte patches)
2. POD XT (non-Pro) uses 152-byte patches and is NOT compatible

See [PROTOCOL.md](docs/PROTOCOL.md) for more troubleshooting.

---

## Contributing

Contributions are welcome! Please read the documentation first:

1. Read [ARCHITECTURE.md](docs/ARCHITECTURE.md) for code structure
2. Read [POD_XT_PRO_DIFFERENCES.md](docs/POD_XT_PRO_DIFFERENCES.md) for critical quirks
3. Test on real POD XT Pro hardware (not just emulator)
4. Follow existing code style
5. Don't break critical sysex handling

See [CLAUDE.md](CLAUDE.md) for detailed developer guide.

---

## Technical Details

### Architecture

- **Platform**: Flutter (Dart)
- **MIDI Library**: flutter_midi_command
- **Architecture**: Layered (Protocol → Services → UI)
- **State Management**: Stream-based reactive architecture
- **Patch Size**: 160 bytes (POD XT Pro specific)
- **Protocol**: Line 6 sysex + standard MIDI CC

### Key Components

- **PodController**: High-level POD API (852 lines)
- **BleMidiService**: BLE/USB MIDI implementation (390 lines)
- **Protocol Layer**: CC map, sysex builders/parsers (5 files)
- **Models**: Patch, EditBuffer, PatchLibrary, Amp/Cab/Effect models
- **UI**: 35 widgets/screens/modals

See [ARCHITECTURE.md](docs/ARCHITECTURE.md) for complete details.

---

## Credits

### Reference Implementation

This app's protocol implementation is based on [pod-ui](https://github.com/arteme/pod-ui) by [arteme](https://github.com/arteme), a Rust/GTK desktop application for POD XT/XT Pro. pod-ui was essential for understanding POD XT Pro's MIDI protocol quirks.

### Dependencies

- [flutter_midi_command](https://pub.dev/packages/flutter_midi_command) - BLE/USB MIDI support
- [shared_preferences](https://pub.dev/packages/shared_preferences) - Settings persistence

### Fonts

- **Doto** - LCD displays
- **OPTICopperplate** - UI labels

---

## License

*(License would go here - e.g., MIT, GPL, etc.)*

---

## Disclaimer

This software is not affiliated with, endorsed by, or sponsored by Line 6 or Yamaha Corporation. Line 6 and POD are registered trademarks of Yamaha Corporation.

This is an independent, reverse-engineered implementation based on publicly available information and the open-source pod-ui reference implementation.

Use at your own risk. The authors are not responsible for any damage to hardware or data.

---

## Contact

- **Issues**: [GitHub Issues](https://github.com/yourusername/pod_flutter/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/pod_flutter/discussions)

---

## Acknowledgments

Special thanks to:
- **[arteme](https://github.com/arteme)** for the pod-ui reference implementation
- The **Flutter community** for excellent libraries and support
- **Line 6** for creating the POD XT Pro (even if they never released full sysex docs!)
