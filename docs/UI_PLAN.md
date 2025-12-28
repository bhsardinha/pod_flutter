# POD XT Pro Controller - UI Plan

## Layout Overview (Horizontal/Landscape)

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                   TOP ROW                                        │
│  ┌────────┐   ┌────────────────────────────────────────────────┐   ┌──────────┐│
│  │▓▓▓▓▓▓▓▓│   │              AMP MODEL SELECTOR                │   │   CAB    ││
│  │▓ GATE ▓│   │            « BRIT J-800 »                      │   │4x12 V30's││
│  │▓▓▓▓▓▓▓▓│   │                                                │   ├──────────┤│
│  │  1/5   │   │                    3/5                         │   │   MIC    ││
│  │ (lit)  │   │                                                │   │57 OnAxis ││
│  └────────┘   └────────────────────────────────────────────────┘   └──────────┘│
│                                                                        1/5      │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                  KNOBS ROW                                       │
│                                                                                  │
│    ┌─────┐    ┌─────┐    ┌─────┐    ┌─────┐    ┌─────┐    ┌─────┐             │
│    │DRIVE│    │BASS │    │ MID │    │TREBLE│   │PRES │    │ VOL │             │
│    │ (○) │    │ (○) │    │ (○) │    │ (○) │    │ (○) │    │ (○) │             │
│    │ 75  │    │ 50  │    │ 62  │    │ 58  │    │ 45  │    │ 80  │             │
│    └─────┘    └─────┘    └─────┘    └─────┘    └─────┘    └─────┘             │
│                                                                                  │
├─────────────────────────────────────────────────────────────────────────────────┤
│                              4-BAND EQ ROW                                       │
│                                                                                  │
│    Band 1          Band 2          Band 3          Band 4                       │
│    ┌───┐           ┌───┐           ┌───┐           ┌───┐         ┌──────────┐  │
│    │ ▓ │   ┌───┐   │ ▓ │   ┌───┐   │ ▓ │   ┌───┐   │ ▓ │  ┌───┐ │▓▓▓▓▓▓▓▓▓▓│  │
│    │ ▓ │   │FRQ│   │ ▓ │   │FRQ│   │ ▓ │   │FRQ│   │ ▓ │  │FRQ│ │▓▓  EQ  ▓▓│  │
│    │ ░ │   │(○)│   │ ▓ │   │(○)│   │ ░ │   │(○)│   │ ▓ │  │(○)│ │▓▓▓▓▓▓▓▓▓▓│  │
│    │ ░ │   └───┘   │ ░ │   └───┘   │ ░ │   └───┘   │ ░ │  └───┘ └──────────┘  │
│    └───┘           └───┘           └───┘           └───┘          (backlit)    │
│   Fader+Freq      Fader+Freq      Fader+Freq      Fader+Freq                   │
│                                                                                  │
├─────────────────────────────────────────────────────────────────────────────────┤
│                             EFFECTS ROW                                          │
│                                                                                  │
│    ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐            │
│    │▓▓ WAH ▓▓│  │░░STOMP░░│  │▓▓ MOD ▓▓│  │▓▓DELAY▓▓│  │▓▓REVERB▓│            │
│    │▓▓▓▓▓▓▓▓▓│  │░░░░░░░░░│  │▓▓▓▓▓▓▓▓▓│  │▓▓▓▓▓▓▓▓▓│  │▓▓▓▓▓▓▓▓▓│            │
│    │▓ Fassel▓│  │░Screamer│  │▓ Chorus▓│  │▓ Analog▓│  │▓  Hall ▓│            │
│    └─────────┘  └─────────┘  └─────────┘  └─────────┘  └─────────┘            │
│       LIT          GRAY         LIT          LIT          LIT                   │
│                                                                                  │
│    Click = Toggle ON/OFF (whole button lights up)                               │
│    Hold 600ms = Open Parameters Modal                                           │
│                                                                                  │
├─────────────────────────────────────────────────────────────────────────────────┤
│                             BOTTOM BAR                                           │
│  ┌──────────────────────────────────────────────────────────────────┐  ┌─────┐ │
│  │ [◄]  01A: "Clean Rhythm"  ──────────────────────────────  [►]   │  │  ●  │ │
│  │                         PATCH BROWSER (4/5)                      │  │ 1/5 │ │
│  └──────────────────────────────────────────────────────────────────┘  └─────┘ │
│                                                                      Connection │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## Interaction Patterns

### Effect Buttons (WAH, STOMP, MOD, DELAY, REVERB, GATE, EQ)

| Action | Result |
|--------|--------|
| **Click** | Toggle ON/OFF. Whole button changes: Grayed = OFF, Lit/Colored = ON |
| **Hold 600ms** | Opens parameter modal for that effect |

### Knobs

| Action | Result |
|--------|--------|
| **Drag vertical** | Adjust value (up = increase, down = decrease) |
| **Drag circular** | Adjust value following rotation |

### Model Selectors (Amp, Cab, Mic)

| Action | Result |
|--------|--------|
| **Click** | Opens full model list modal |
| **Swipe left/right** | Previous/next model |

### Modals

- **Padding**: Generous spacing around modal content
- **No close button**: Click/tap outside modal to dismiss
- **Overlay**: Semi-transparent dark background

## Widget Specifications

### 1. EffectButton (Backlit Style)

```
OFF State:                      ON State:
┌───────────────┐               ┌───────────────┐
│░░░░░░░░░░░░░░░│               │▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│
│░░░  WAH   ░░░░│               │▓▓▓  WAH   ▓▓▓▓│  ← Glowing
│░░░░░░░░░░░░░░░│               │▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│
│░░ "Fassel" ░░░│               │▓▓ "Fassel" ▓▓▓│
│░░░░░░░░░░░░░░░│               │▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│
└───────────────┘               └───────────────┘
   Grayed/Dim                    Lit/Colored

Visual Concept:
- Translucent button surface
- Light source underneath
- OFF: No light, button appears gray/dark
- ON: Light on, button glows with color (green, orange, etc.)
- Soft glow/bloom effect around edges when ON

States:
- OFF: Dark gray translucent, no glow, dimmed text
- ON: Colored translucent (green/amber), soft glow, bright text

Behavior:
- GestureDetector with onTap (toggle) and onLongPress (open modal)
- 600ms threshold for long press
```

### 2. RotaryKnob

```
       ╭─────────╮
     ╱     ●       ╲     ← Indicator dot (shows position)
    │               │
    │       ○       │     ← Center cap
    │               │
     ╲             ╱
       ╰─────────╯
         LABEL            ← Parameter name
          127             ← Current value

- Value range: 0-127 (or custom)
- Visual rotation: ~270° arc
- Tick marks around edge (optional)
- Metallic gradient appearance
```

### 3. VerticalFader (for EQ - Bipolar/Center-Zero)

```
    +12dB
    ┌───┐
    │ ▓ │  ← Positive fill (above center)
    │ ▓ │
    │███│  ← Handle at +6dB
    │ ░ │
  ──│───│──  ← CENTER LINE (0dB)
    │ ░ │
    │ ░ │
    │ ░ │
    │ ░ │
    └───┘
    -12dB

Examples:

  Boosted (+6dB)      Flat (0dB)        Cut (-6dB)
    ┌───┐              ┌───┐              ┌───┐
    │ ░ │              │ ░ │              │ ░ │
    │ ▓ │              │ ░ │              │ ░ │
    │███│ ← handle     │ ░ │              │ ░ │
    │ ▓ │              │███│ ← handle   ──│───│── center
  ──│───│── center   ──│───│── center     │ ▓ │
    │ ░ │              │ ░ │              │███│ ← handle
    │ ░ │              │ ░ │              │ ▓ │
    └───┘              └───┘              └───┘

- Zero/center is the middle of the fader
- Drag up = boost (+dB), drag down = cut (-dB)
- Fill goes FROM center TO handle position
- Range: -12dB to +12dB (or as per POD spec)
- Center detent feel (optional haptic/snap)
```

### 4. ModelSelector (LCD Display style)

```
┌─────────────────────────────────────┐
│▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│
│       « MODEL NAME »                │  ← Centered text
│▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│
└─────────────────────────────────────┘

- LCD green/amber glow effect
- Tap to open picker modal
- Swipe for prev/next
```

### 5. ConnectionIndicator

```
┌─────┐
│  ●  │  ← Green = connected, Red = disconnected
└─────┘

- Simple dot indicator
- Tap to open connection screen/modal
```

### 6. PatchBrowser

```
┌──────────────────────────────────────────────────────────────┐
│  [◄]    01A: "Clean Rhythm"                           [►]   │
└──────────────────────────────────────────────────────────────┘

- Left/right arrows for navigation
- Tap center to open patch list modal
- Shows bank + number + name
```

## Modal Designs

### Effect Parameter Modal (Example: Delay)

```
                    ┌─────────────────────────────────────────┐
                    │                                         │
                    │           DELAY PARAMETERS              │
                    │                                         │
                    │   ┌─────────────────────────────────┐   │
                    │   │    « ANALOG DELAY W/MOD »       │   │
                    │   └─────────────────────────────────┘   │
                    │                                         │
                    │   ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐     │
                    │   │TIME │ │FDBK │ │SPEED│ │DEPTH│     │
                    │   │ (○) │ │ (○) │ │ (○) │ │ (○) │     │
                    │   │420ms│ │ 45  │ │ 30  │ │ 50  │     │
                    │   └─────┘ └─────┘ └─────┘ └─────┘     │
                    │                                         │
                    │   ┌─────┐                               │
                    │   │ MIX │    Position: [PRE] [POST●]   │
                    │   │ (○) │                               │
                    │   │ 35  │    Note Sync: [OFF] [1/4●]   │
                    │   └─────┘                               │
                    │                                         │
                    └─────────────────────────────────────────┘

- Tap outside to close (no X button)
- Modal has padding/margin from screen edges
- Semi-transparent overlay behind
```

### Model Picker Modal

```
                    ┌─────────────────────────────────────────┐
                    │                                         │
                    │           SELECT AMP MODEL              │
                    │                                         │
                    │   ┌─────────────────────────────────┐   │
                    │   │  🔍 Search...                   │   │
                    │   └─────────────────────────────────┘   │
                    │                                         │
                    │   ── Stock ──────────────────────────   │
                    │   ○ No Amp                              │
                    │   ○ Tube Preamp                         │
                    │   ○ Line 6 Clean                        │
                    │   ● Brit J-800            ← Selected    │
                    │   ○ Plexi Lead 100                      │
                    │   ...                                   │
                    │                                         │
                    │   ── Metal Shop ─────────────────────   │
                    │   ○ Bomber Uber                         │
                    │   ...                                   │
                    │                                         │
                    └─────────────────────────────────────────┘

- Grouped by pack (Stock, MS, CC, BX)
- Tap to select and close
- Optional search filter
```

## Color Palette

```dart
class PodColors {
  // Backgrounds
  static const background = Color(0xFF0D0D0D);      // Near black
  static const surface = Color(0xFF1A1A1A);         // Dark charcoal
  static const surfaceLight = Color(0xFF2A2A2A);    // Elevated surfaces

  // Accents
  static const accent = Color(0xFFFF6B00);          // Line6 orange
  static const accentDim = Color(0xFF803600);       // Dimmed orange

  // Backlit Buttons
  static const buttonOff = Color(0xFF2A2A2A);       // Grayed out / no light
  static const buttonOffText = Color(0xFF606060);   // Dimmed text when off
  static const buttonOnGreen = Color(0xFF00CC00);   // Lit green
  static const buttonOnAmber = Color(0xFFFFAA00);   // Lit amber/orange
  static const buttonGlow = Color(0xFF00FF00);      // Glow effect (green)
  static const buttonGlowAmber = Color(0xFFFFCC00); // Glow effect (amber)

  // LCD Display
  static const lcdBackground = Color(0xFF1A2A1A);   // Dark green tint
  static const lcdText = Color(0xFF88FF88);         // Green LCD text
  static const lcdGlow = Color(0xFF00FF00);         // Glow effect

  // Knobs/Metal
  static const knobBase = Color(0xFF3A3A3A);        // Knob body
  static const knobHighlight = Color(0xFF5A5A5A);   // Knob highlight
  static const knobShadow = Color(0xFF1A1A1A);      // Knob shadow
  static const knobIndicator = Color(0xFFFFFFFF);   // Position indicator

  // Text
  static const textPrimary = Color(0xFFE0E0E0);     // Main text
  static const textSecondary = Color(0xFF808080);   // Dimmed text
  static const textLabel = Color(0xFFB0B0B0);       // Labels

  // Overlay
  static const modalOverlay = Color(0xCC000000);    // 80% black
}
```

## File Structure

```
lib/
├── ui/
│   ├── theme/
│   │   └── pod_theme.dart           # Colors, text styles, theme data
│   │
│   ├── widgets/
│   │   ├── rotary_knob.dart         # Knob widget
│   │   ├── vertical_fader.dart      # EQ fader widget
│   │   ├── effect_button.dart       # Effect toggle + hold button
│   │   ├── model_selector.dart      # LCD-style model display
│   │   ├── connection_indicator.dart # Red/green dot
│   │   ├── patch_browser.dart       # Bottom patch navigation
│   │   └── pod_modal.dart           # Base modal wrapper
│   │
│   ├── modals/
│   │   ├── amp_picker_modal.dart    # Amp model selection
│   │   ├── cab_picker_modal.dart    # Cabinet selection
│   │   ├── stomp_modal.dart         # Stomp parameters
│   │   ├── mod_modal.dart           # Modulation parameters
│   │   ├── delay_modal.dart         # Delay parameters
│   │   ├── reverb_modal.dart        # Reverb parameters
│   │   ├── wah_modal.dart           # Wah parameters
│   │   ├── gate_modal.dart          # Noise gate parameters
│   │   └── patch_list_modal.dart    # Full patch browser
│   │
│   └── screens/
│       ├── main_screen.dart         # Main horizontal layout
│       ├── connection_screen.dart   # Device connection (modal or screen)
│       └── midi_test_screen.dart    # (existing) Debug screen
│
└── ...
```

## Implementation Order

1. **Phase 1: Theme & Base Widgets**
   - [ ] pod_theme.dart
   - [ ] rotary_knob.dart
   - [ ] effect_button.dart
   - [ ] pod_modal.dart (base modal with outside-tap-to-close)

2. **Phase 2: Main Layout**
   - [ ] main_screen.dart (scaffold with all rows)
   - [ ] model_selector.dart
   - [ ] connection_indicator.dart
   - [ ] patch_browser.dart

3. **Phase 3: EQ Section**
   - [ ] vertical_fader.dart
   - [ ] EQ row integration

4. **Phase 4: Effect Modals**
   - [ ] stomp_modal.dart
   - [ ] mod_modal.dart
   - [ ] delay_modal.dart
   - [ ] reverb_modal.dart
   - [ ] wah_modal.dart
   - [ ] gate_modal.dart

5. **Phase 5: Pickers & Polish**
   - [ ] amp_picker_modal.dart
   - [ ] cab_picker_modal.dart
   - [ ] patch_list_modal.dart
   - [ ] Animations & transitions
   - [ ] Final polish

## Notes

- All effect buttons follow same pattern: click=toggle, hold=modal
- No close buttons on modals - tap outside to dismiss
- Horizontal/landscape orientation enforced
- Generous padding around modal content
- Skeuomorphic metallic appearance without image assets
- Real-time parameter updates via PodController
