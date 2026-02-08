# Features Documentation

## POD Flutter v1.0.0

This document provides a comprehensive overview of all features implemented in the v1.0.0 release, known limitations, and possible future enhancements.

POD Flutter is a **production-ready, cross-platform MIDI controller** for the Line 6 POD XT Pro guitar processor with complete parameter control, patch management, and local library support.

---

## Features ✅

### Connection & Device Management

- ✅ **BLE MIDI Device Discovery**
  - Scan for Bluetooth MIDI devices
  - Filter by device name/type
  - Display device list with connection status

- ✅ **USB MIDI Support**
  - Connect via USB MIDI (iOS/macOS CoreMIDI, Android android.media.midi)
  - Same API as BLE MIDI (transparent)

- ✅ **Connection Management**
  - Connect/disconnect with status feedback
  - Connection state monitoring
  - Auto-reconnection on unexpected disconnection
  - Device hot-plug detection

- ✅ **Initial State Synchronization**
  - Request edit buffer on connection
  - Request current program number
  - Request installed expansion packs

### Parameter Control (70+ CC Parameters)

#### Preamp & Tone

- ✅ **Amp Model Selection** (107 models)
  - 37 stock models
  - 18 Metal Shop (MS) models
  - 18 Collector's Classic (CC) models
  - 28 Bass Expansion (BX) models
  - 6 additional stock models

- ✅ **Amp Enable/Bypass**
  - Toggle amp on/off
  - Handles inverted parameter (CC 111)

- ✅ **Tone Controls**
  - Drive (0-127)
  - Bass (0-127)
  - Mid (0-127)
  - Treble (0-127)
  - Presence (0-127)
  - Channel Volume (0-127)
  - Bypass Volume (0-127)

#### Cabinet & Microphone

- ✅ **Cabinet Selection** (47 models)
  - 25 guitar cabinets
  - 22 bass cabinets (BX pack)
  - Automatic filtering based on amp type

- ✅ **Microphone Selection** (8 models)
  - 4 guitar mics (57 on/off axis, 421, 67)
  - 4 bass mics (Tube 47 close/far, 112, 20)
  - Context-aware (changes based on cabinet type)

- ✅ **Room Parameter**
  - Ambience/room size control (0-127)

#### Effects

**Noise Gate**:
- ✅ Enable/disable
- ✅ Threshold (-96dB to 0dB)
- ✅ Decay (0-127)

**Compressor**:
- ✅ Enable/disable
- ✅ Threshold (0-127)
- ✅ Gain (0-127)

**Stomp Box** (31 models):
- ✅ Enable/disable
- ✅ Model selection (9 stock + 17 FX + 4 BX + 1 BX2)
- ✅ Dynamic parameters (up to 6 per model)
- ✅ Model-specific parameter mapping with skip() offset handling
- ✅ Special parameter types:
  - Wave parameters (8-step discrete: Wave 1-8 for synth effects)
  - Octave parameters (9-step discrete: -1 oct to +1 oct for Synth Harmony)
  - Heel/Toe parameters (-24 to +24 semitones for Bender)
- ✅ Hardware knob layout support (displayOrder for reordered parameters)

**Modulation** (24 models):
- ✅ Enable/disable
- ✅ Model selection (11 stock + 13 FX)
- ✅ Dynamic parameters (up to 3 per model)
- ✅ Speed control (14-bit MSB/LSB)
- ✅ Tempo sync (note divisions)
- ✅ 2-position speed switch for Rotary effects (SLOW/FAST)
- ✅ Mix control

**Delay** (14 models):
- ✅ Enable/disable
- ✅ Model selection (9 stock + 5 FX)
- ✅ Dynamic parameters (up to 3 per model)
- ✅ Time control (14-bit MSB/LSB)
- ✅ Tempo sync (note divisions)
- ✅ Special parameters:
  - Heads parameter (9-step discrete: multi-head delay patterns)
  - Bits parameter (9-step discrete: bit-depth reduction for Low Rez)
- ✅ Mix control

**Reverb** (15 models):
- ✅ Enable/disable
- ✅ Model selection (3 spring + 12 algorithmic)
- ✅ Dynamic parameters (spring: dwell+tone, others: pre-delay+decay+tone)
- ✅ Level control

**Wah** (8 models):
- ✅ Enable/disable
- ✅ Model selection (Vetta, Fassel, Weeper, Chrome, etc.)
- ✅ Position control (0-127)

**EQ** (4-Band Parametric):
- ✅ Enable/disable
- ✅ 4 frequency controls with logarithmic scaling
- ✅ 4 gain controls (±15dB)
- ✅ Band-specific frequency ranges

#### Utility

- ✅ **Loop Enable/Disable**
  - FX loop in/out

- ✅ **Volume Pedal**
  - Enable/disable
  - Level control (CC 7)
  - Minimum level setting

- ✅ **Tempo Control**
  - BPM setting (30.0-240.0 BPM)
  - 14-bit precision (300-2400 internal units)
  - Tap tempo button
  - Vertical drag to adjust BPM
  - Hold/right-click for BPM number entry dialog
  - Tempo-synced effects (Delay/Mod)

- ✅ **Tuner**
  - Enable/disable via CC 69
  - Real-time pitch detection via MIDI sysex
  - 3-segment visual display (flat/in-tune/sharp)
  - Note name and octave display
  - Frequency display (Hz)
  - ±2 cent tolerance for "in tune" indication
  - Red arrows for out-of-tune (>±2 cents)
  - Green circle for in-tune range (±2 cents)
  - POD-specific note numbering and frequency calculation

### Patch Management

- ✅ **128-Patch Library**
  - All 128 hardware patches stored locally
  - Per-patch name display
  - Modification tracking

- ✅ **Program Change**
  - Select any of 128 programs
  - Non-contiguous MIDI mapping (0-63, 192-255)
  - Edit buffer synchronization after change

- ✅ **Edit Buffer**
  - Current working patch
  - Real-time synchronization with hardware
  - Modified indicator (differs from stored patch)
  - Source program tracking

- ✅ **Bulk Import from Hardware**
  - Sequential import of all 128 patches
  - Progress tracking (current/total)
  - Status messages
  - Completer-based synchronization (waits for actual responses)
  - Handles POD XT Pro quirk (03 74 responses to patch requests)
  - Ignores individual 03 72 markers

- ✅ **Save Patch to Hardware**
  - Save current edit buffer to any of 128 slots
  - Sysex store command (03 71)
  - Automatic end marker (03 72)
  - Success/failure feedback (03 50/03 51)
  - 5-second timeout

- ✅ **Patch Browser**
  - Tabbed interface (Local Library / POD Presets)
  - Local library with persistent storage (file-based)
  - List view with all 128 patches
  - Bank organization (A/B/C/D, 1-32 per bank)
  - Current patch highlighting
  - Modified patches indicator
  - Clickable modified indicator (*) with save/discard dialog

- ✅ **Patch Rename**
  - UI text input field with inline editing
  - Changes name in edit buffer and hardware
  - Forces hardware to reload patch after rename
  - Updates UI immediately
  - Properly handles currently loaded patch renaming

- ✅ **Patch Import/Export**
  - **Proprietary file formats**:
    - `.podpatch` - Single patch format (JSON metadata + base64 binary data)
    - `.podlibrary` - Multi-patch library format (JSON metadata + base64 binary data)
  - **Single Patch Operations**:
    - Import single patch from .podpatch file to local library
    - Export single patch to .podpatch file from local library
  - **Bulk Operations**:
    - Export all 128 hardware patches to .podlibrary file
    - Export entire local library to .podlibrary file
    - Import .podlibrary to hardware (overwrites POD slots)
    - Import .podlibrary to local library (adds to collection)
  - Progress tracking for bulk operations
  - Success/failure feedback with toast messages
  - Metadata preservation (author, description, tags, genre, use case)

### Local Patch Library

- ✅ **Persistent Storage**
  - File-based storage (Documents directory)
  - Binary patch data (.bin files) + JSON metadata (.json files)
  - Automatic index generation for fast lookup
  - Cache system for performance

- ✅ **Patch Metadata**
  - Author field
  - Description field
  - Genre classification (Unspecified, Clean, Crunch, Lead, Rhythm, Bass)
  - Use Case tags (General, Live, Studio, Practice)
  - Custom tags (comma-separated)
  - Favorite marking
  - Import source tracking

- ✅ **Library Management**
  - Save patches to local library
  - Load patches from local library
  - Delete patches from local library
  - Clear entire library
  - Get library statistics (patch count, total size, favorite count)
  - Cache invalidation for data integrity

### User Interface

#### Main Screen

- ✅ **Landscape-Only Orientation**
  - Optimized for landscape viewing
  - POD hardware-inspired layout

- ✅ **POD Hardware Appearance**
  - Brushed metal background
  - LCD-style displays
  - LED indicators
  - Realistic knob graphics

- ✅ **Real-Time Updates**
  - Stream-based reactive architecture
  - Updates from hardware changes
  - Bi-directional synchronization

#### Controls

- ✅ **Rotary Knobs**
  - Drag-based rotation (vertical drag)
  - Mouse wheel support
  - Distance-based movement (non-accelerated)
  - Value display with custom formatters (dB, %, Hz, ms, etc.)
  - Min/max indicators
  - Smooth animation
  - Special handling for discrete parameters:
    - Small-range knobs (Heads, Bits, Wave) with optimized scroll sensitivity
    - 2-position switches (Rotary speed: SLOW/FAST) with direction-based movement
    - Tempo sync mode with compact note division labels (1/4, 1/8, etc.)
    - Hard stop at mode boundaries (prevents accidental crossing between tempo/ms modes)

- ✅ **Effect Buttons**
  - Enable/disable toggle
  - LED indicator (on/off/bypassed states)
  - Tap to toggle on/off
  - Hold or right-click to open effect modal
  - Displays effect name
  - Consistent interaction across all buttons (CAB, MIC, SET, TAP)
  - CAB button: Tap toggles between current cab and "No Cab", hold opens selector
  - MIC button: Tap does nothing, hold opens selector
  - SET button: Tap or hold opens settings
  - TAP button: Tap for tap tempo, vertical drag for BPM, hold for number entry

- ✅ **Dot-Matrix LCD Display**
  - Patch name display
  - POD-style dot-matrix font
  - Scrolling for long text

- ✅ **Connection Indicator**
  - Visual connection status
  - Color-coded (green=connected, red=disconnected)

- ✅ **Tap Tempo Button**
  - Tap to set tempo
  - Displays current BPM
  - Calculates tempo from tap intervals

#### Modals

- ✅ **Connection Modal**
  - Device scanning
  - Device selection
  - Bulk import trigger
  - Progress tracking

- ✅ **Patch Browser Modal**
  - 128-patch list
  - Bank organization (4 banks × 32 patches)
  - Current patch highlight
  - Select patch to load

- ✅ **Amp Selection Modal**
  - List view and grid view (toggle)
  - Expansion pack filtering
  - Factory/Real name display modes
  - "Load with defaults" option

- ✅ **Cabinet Selection Modal**
  - Guitar/bass cabinet separation
  - Real cabinet names
  - Pack indicators (BX)

- ✅ **Microphone Selection Modal**
  - Context-aware (guitar vs bass mics)
  - Microphone position visualization
  - Room parameter slider

- ✅ **Effect Modals** (Generic)
  - Effect model picker
  - Dynamic parameter knobs (model-dependent)
  - Tempo sync toggle (Mod/Delay)
  - 14-bit parameter support (Speed/Time)
  - Enable/disable toggle

- ✅ **Gate Modal**
  - Threshold slider with dB display
  - Decay slider

- ✅ **Compressor Modal**
  - Threshold slider
  - Gain slider

- ✅ **Tuner Modal**
  - 3-segment visual tuner (flat/in-tune/sharp)
  - Note name and octave display
  - Frequency display in Hz
  - Cents offset display
  - "IN TUNE" indicator (0 cents only)
  - Real-time updates (1 Hz polling)
  - Automatically enables/disables tuner mode (CC 69)
  - Opened by tapping "A" button on LCD

#### Settings

- ✅ **Amp Name Display Modes**
  - Factory names only (e.g., "Brit J-800")
  - Real amp names only (e.g., "1990 Marshall JCM-800")
  - Both (real name on top, factory name on bottom)

- ✅ **Grid Items Per Row**
  - Adjustable (4-6 items per row)
  - Applies to amp/cab grid views

- ✅ **Tempo Scrolling**
  - Enable/disable tempo knob scrolling

- ✅ **Warn on Unsaved Changes**
  - Confirmation dialog when switching patches with unsaved edits
  - Option to save, discard, or cancel
  - Can be disabled in settings

- ✅ **Disable A.I.R.**
  - Disable Advanced Impulse Response (A.I.R.) processing
  - For users with external IR devices
  - Bypasses cabinet and mic simulation

- ✅ **Settings Persistence**
  - SharedPreferences storage
  - Persists across app launches

### POD XT Pro Specific Implementation

- ✅ **160-Byte Patches**
  - Correct patch size (not 152 like POD XT)
  - 16-byte name + 144-byte parameters

- ✅ **Non-Contiguous Patch Mapping**
  - Patches 0-63 → MIDI 0-63
  - Patches 64-127 → MIDI 192-255 (not 64-127!)

- ✅ **Edit Buffer Dump Handling**
  - POD responds with 03 74 for patch requests (03 73)
  - Tracks expected patch number during bulk import
  - Distinguishes edit buffer vs patch dump by context

- ✅ **Individual 03 72 Markers**
  - POD sends 03 72 after each patch response
  - Ignored during bulk import
  - Not treated as completion signal

- ✅ **Inverted Parameters**
  - Amp Enable (CC 111) uses inverted logic (0=on, 127=off)

- ✅ **Expansion Pack Detection**
  - Requests installed packs on connection (03 0E)
  - Stores pack flags (MS/CC/FX/BX)
  - Filters unavailable models in UI

---

## Known Limitations (v1.0.0)

### Hardware Limitations

1. **No Bulk Dump Support**
   - POD XT Pro doesn't support AllProgramsDump command
   - Must request patches individually (takes ~6.4 seconds for 128 patches)

2. **Slow Response Time**
   - Hardware responds slowly to rapid requests
   - Requires 50ms delay between patch requests
   - Can't be sped up significantly

3. **Ambiguous Sysex Responses**
   - POD responds with 03 74 for both edit buffer and patch requests
   - Requires tracking expected patch number
   - Prone to desync if messages are missed

4. **Limited Tuner Data**
   - Tuner sysex doesn't include note name string
   - Must calculate note name from MIDI number

### Software Limitations

1. **POD Hardware Patch Sync**
   - POD hardware patches must be re-imported on every app launch
   - Takes ~6.4 seconds to import all 128 patches
   - No automatic sync (must use "Import All Patches" manually)
   - Local library provides persistent storage independent of hardware

2. **Limited Error Recovery**
   - No retry logic for failed sysex
   - Timeout handling could be more robust
   - Connection loss requires manual reconnect

3. **Single Device**
   - Can only connect to one POD at a time
   - No multi-device support

4. **Platform Limitations**
   - Linux MIDI support limited (ALSA required)
   - Windows BLE-MIDI not supported (USB MIDI only)
   - Web platform not supported (no MIDI API)

### Testing Limitations

1. **Limited Test Coverage**
   - Only basic widget_test.dart exists
   - No unit tests for protocol layer
   - No integration tests for PodController
   - No mock MIDI service
   - Production code works but testing infrastructure is minimal

---

## Possible Future Enhancements

The following features are not planned for v1.0.0 but could be considered for future releases:

- **Advanced Features**: Undo/Redo, A/B comparison mode, parameter randomization, patch morphing
- **Organization**: Search/filter patches, setlists for live performance, custom tags beyond current metadata
- **MIDI Features**: MIDI learn, MIDI clock sync, external controller mapping
- **UI Enhancements**: Portrait mode support, tablet/iPad optimization, custom themes, accessibility features
- **Performance**: Auto-reconnect on connection loss, retry logic for failed sysex, patch caching optimizations
- **Testing**: Comprehensive unit tests, integration tests, mock MIDI device for automated testing

---

## Comparison with POD-UI Reference

### Features Implemented from POD-UI

- ✅ Edit buffer synchronization
- ✅ Patch library (128 patches)
- ✅ Bulk import (sequential, correct handling of quirks)
- ✅ Parameter CC mapping
- ✅ Expansion pack detection
- ✅ Store with timeout (5 seconds)
- ✅ Non-contiguous patch mapping
- ✅ 160-byte patch size
- ✅ Inverted amp enable
- ✅ Tuner protocol (CC 69, sysex note/offset requests)
- ✅ Patch rename and hardware update
- ✅ Local patch library storage

### Flutter-Specific Features

- ✅ Mobile UI optimized for touch
- ✅ POD hardware-inspired appearance
- ✅ Stream-based reactive architecture
- ✅ Modal dialogs for detailed settings
- ✅ Settings persistence (SharedPreferences)
- ✅ Hot-plug device detection
- ✅ BLE MIDI support (POD-UI is USB-only)
- ✅ Tabbed patch library (Local + POD Presets)
- ✅ Local patch storage and backup
- ✅ Unsaved changes warning
- ✅ Clickable modified indicator with save/discard options
- ✅ Button interaction consistency (tap/hold/right-click)
- ✅ Visual tuner with 3-segment display
- ✅ BPM number entry dialog
- ✅ A.I.R. disable setting

---

## Contributing

POD Flutter v1.0.0 is a complete, production-ready MIDI controller for POD XT Pro.

If you'd like to contribute:

**Bug Fixes & Improvements**:
- Report issues on GitHub
- Fix bugs or improve existing features
- Improve documentation

**Feature Additions**:
- See "Possible Future Enhancements" section for ideas
- Propose new features via GitHub issues
- Follow existing code patterns and architecture

**Testing**:
- Add unit tests for protocol layer
- Add integration tests for PodController
- Create widget tests for UI components

**Documentation**:
- See `ARCHITECTURE.md` for complete code structure and design patterns
- See `PROTOCOL.md` for MIDI protocol details
- See `CLAUDE.md` for development guidelines
