# POD XT Pro Controller - Progress Notes

## Current State (2025-12-28)

**MIDI COMMUNICATION WORKING!** The app successfully connects to POD XT Pro via USB MIDI and provides bidirectional control - changes on app reflect on device and vice versa.

---

## Completed

### Protocol Layer
- `lib/protocol/constants.dart` - Sysex commands, device IDs, expansion pack flags
- `lib/protocol/cc_map.dart` - 70+ CC parameter mappings with addresses
- `lib/protocol/sysex.dart` - Sysex message encoding/decoding with nibble conversion

### Data Models
- `lib/models/amp_models.dart` - 105 amp models (Stock + MS/CC/FX/BX expansions)
- `lib/models/cab_models.dart` - 47 cabinets, 8 microphones
- `lib/models/effect_models.dart` - Stomp/Mod/Delay/Reverb/Wah effects with parameters
- `lib/models/patch.dart` - 152-byte patch structure (Patch + EditBuffer classes)

### Services
- `lib/services/midi_service.dart` - Abstract MIDI interface
- `lib/services/ble_midi_service.dart` - BLE/USB MIDI implementation using flutter_midi_command
- `lib/services/pod_controller.dart` - High-level POD control API with convenience accessors

### UI Theme
- `lib/ui/theme/pod_theme.dart` - PodColors, PodTextStyles, PodTheme (Material3 dark theme)

### UI Widgets (Minimalist Design)
- `lib/ui/widgets/rotary_knob.dart` - Clean geometric knob with line indicator, 270° rotation (7:30 to 4:30)
- `lib/ui/widgets/effect_button.dart` - Solid toggle button (click=toggle, right-click/long-press=modal)
- `lib/ui/widgets/vertical_fader.dart` - Compact bipolar center-zero EQ fader (100px height)
- `lib/ui/widgets/pod_modal.dart` - Modal wrapper + showPodModal() function
- `lib/ui/widgets/connection_indicator.dart` - Green/red connection dot
- `lib/ui/widgets/patch_browser.dart` - Bottom patch navigation bar
- `lib/ui/widgets/widgets.dart` - Barrel export file

### UI Screens
- `lib/ui/screens/main_screen.dart` - Main horizontal layout with MIDI integration

### MIDI Integration
- **Bidirectional Communication** - App sends CC to POD, POD sends CC to app
- **Connected Parameters:**
  - All 6 main knobs (Drive, Bass, Mid, Treble, Presence, Volume)
  - All effect enable buttons (Gate, Amp, Wah, Stomp, Mod, Delay, Reverb, EQ)
  - Patch navigation (previous/next program change)
- **Device Connection Panel** - Scan, connect, disconnect, sync from POD
- **Edit Buffer Sync** - Request current state from POD on connect
- **Full Patch Sync** - Request all 128 patches on connect, stored in PatchLibrary
- **Sync Progress** - SyncProgress stream tracks patch sync progress

### UI Features
- **Minimalist Design** - No glow effects, solid geometric shapes
- **Real Value Display** - Knobs show 0.0-10.0 scale, EQ shows actual Hz values
- **AMP Bypass Button** - Toggle amp on/off
- **Custom Amp Selector** - Arrows at extremes, compact design
- **Dropdown Selectors** - CAB and MIC as compact dropdowns
- **Right-click Support** - Desktop: right-click = long-press action
- **EQ Section Tile** - EQ bands grouped in a container
- **Patch Selection Modal** - Full 128-patch browser grouped by bank (32 banks x 4 slots)
- **Modified Indicator** - Orange dot in patch browser when edit buffer differs from stored patch
- **Sync Progress Display** - Shows syncing progress when opening patch browser during sync

### Documentation
- `CLAUDE.md` - Project context for Claude
- `docs/UI_PLAN.md` - Comprehensive UI specification with ASCII diagrams
- `docs/PROGRESS.md` - This file

---

## TODO / Remaining Work

### High Priority
1. **Effect Parameter Modals** - Currently show placeholder text
   - Gate modal (threshold/decay)
   - Wah/Stomp/Mod/Delay/Reverb modals with full parameters

2. **Picker Modals** - Currently show placeholder text
   - Amp picker (scrollable list grouped by pack)
   - Cab picker
   - Mic picker

### Medium Priority
3. **Amp Navigation** - Implement prev/next amp arrows functionality
4. **EQ Parameter Send** - Wire up EQ faders and frequency knobs to MIDI
5. **State Persistence** - Remember last connected device
6. **Error Handling** - Better feedback on connection failures

### Low Priority / Polish
7. **Haptic Feedback** - Add vibration on mobile
8. **Animations** - Smooth transitions
9. **Preset Save/Load** - Save patches back to POD
10. **Remove Debug Prints** - Clean up console output for production

---

## File Structure

```
lib/
├── main.dart                    # App entry, uses PodTheme + MainScreen
├── models/
│   ├── amp_models.dart
│   ├── cab_models.dart
│   ├── effect_models.dart
│   └── patch.dart
├── protocol/
│   ├── cc_map.dart
│   ├── constants.dart
│   └── sysex.dart
├── services/
│   ├── ble_midi_service.dart
│   ├── midi_service.dart
│   └── pod_controller.dart
└── ui/
    ├── screens/
    │   ├── main_screen.dart      # Main UI with MIDI integration
    │   └── midi_test_screen.dart # Debug screen
    ├── theme/
    │   └── pod_theme.dart
    └── widgets/
        ├── connection_indicator.dart
        ├── effect_button.dart
        ├── model_selector.dart   # (unused, replaced by inline selector)
        ├── patch_browser.dart
        ├── pod_modal.dart
        ├── rotary_knob.dart
        ├── vertical_fader.dart
        └── widgets.dart          # Barrel file
```

---

## Notes

- App forces landscape orientation in MainScreen
- All effect buttons: click = toggle, right-click (desktop) or long-press (mobile) = open modal
- Modals close by tapping outside
- EQ faders are bipolar: center = 0dB, up = boost, down = cut
- Knobs display real values (0-10 scale or Hz for EQ frequencies)
- Knobs support both vertical drag and circular gesture
- Amp enable CC is inverted: 127 = bypass (off), 0 = amp on
