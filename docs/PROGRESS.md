# POD XT Pro Controller - Progress Notes

## Current State (2025-12-28)

The app successfully builds and mounts with the new skeuomorphic UI layout.

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
- `lib/services/ble_midi_service.dart` - BLE MIDI implementation using flutter_midi_command
- `lib/services/pod_controller.dart` - High-level POD control API with convenience accessors

### UI Theme
- `lib/ui/theme/pod_theme.dart` - PodColors, PodTextStyles, PodTheme (Material3 dark theme)

### UI Widgets
- `lib/ui/widgets/rotary_knob.dart` - Metallic rotary knob with CustomPainter, ~270° rotation
- `lib/ui/widgets/effect_button.dart` - Backlit toggle button (click=toggle, hold=modal)
- `lib/ui/widgets/vertical_fader.dart` - Bipolar center-zero EQ fader
- `lib/ui/widgets/model_selector.dart` - LCD-style green display with chevrons
- `lib/ui/widgets/pod_modal.dart` - Modal wrapper + showPodModal() function
- `lib/ui/widgets/connection_indicator.dart` - Green/red connection dot
- `lib/ui/widgets/patch_browser.dart` - Bottom patch navigation bar
- `lib/ui/widgets/widgets.dart` - Barrel export file

### UI Screens
- `lib/ui/screens/main_screen.dart` - Main horizontal layout with all sections
- `lib/ui/screens/midi_test_screen.dart` - MIDI connectivity test screen

### Documentation
- `CLAUDE.md` - Project context for Claude
- `docs/UI_PLAN.md` - Comprehensive UI specification with ASCII diagrams

---

## TODO / Lacking

### High Priority
1. **Effect Parameter Modals** - Currently show placeholder text
   - `stomp_modal.dart` - Stomp box parameters (varies by model)
   - `mod_modal.dart` - Modulation parameters
   - `delay_modal.dart` - Delay parameters (time, feedback, mix, etc.)
   - `reverb_modal.dart` - Reverb parameters
   - `wah_modal.dart` - Wah parameters
   - `gate_modal.dart` - Noise gate threshold/decay

2. **Picker Modals** - Currently show placeholder text
   - `amp_picker_modal.dart` - Scrollable amp list grouped by pack
   - `cab_picker_modal.dart` - Cabinet selection
   - `mic_picker_modal.dart` - Microphone selection
   - `patch_list_modal.dart` - Full 128-patch browser

3. **Wire up PodController** - Connect UI state to actual MIDI
   - Integrate BleMidiService with MainScreen
   - Send CC messages when knobs/faders change
   - Receive and parse edit buffer dumps
   - Update UI when MIDI data received

### Medium Priority
4. **Patch Navigation** - Implement prev/next patch buttons
5. **Amp/Model Navigation** - Implement prev/next model swipe
6. **Connection Screen** - Device scanning and connection UI
7. **State Management** - Consider Provider/Riverpod for cleaner state

### Low Priority / Polish
8. **Haptic Feedback** - Add vibration on knob changes, button holds
9. **Animations** - Smooth transitions for button states, modal open/close
10. **Sound Preview** - Play test tone through POD when connected
11. **Preset Save/Load** - Save edited patches back to POD
12. **USB MIDI Support** - For desktop testing (currently BLE only works)

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
    │   ├── main_screen.dart      # Main UI
    │   └── midi_test_screen.dart # Debug screen
    ├── theme/
    │   └── pod_theme.dart
    └── widgets/
        ├── connection_indicator.dart
        ├── effect_button.dart
        ├── model_selector.dart
        ├── patch_browser.dart
        ├── pod_modal.dart
        ├── rotary_knob.dart
        ├── vertical_fader.dart
        └── widgets.dart          # Barrel file
```

---

## Notes

- App forces landscape orientation in MainScreen
- All effect buttons: click = toggle on/off, hold 600ms = open modal
- Modals close by tapping outside (no X button)
- EQ faders are bipolar: center = 0dB, up = boost, down = cut
- LCD selector uses green glow effect like real POD hardware
- Knobs support both vertical drag and circular gesture
