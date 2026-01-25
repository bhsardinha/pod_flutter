# Features Documentation

## Current Implementation Status

This document provides a comprehensive overview of implemented features, known limitations, and planned enhancements.

---

## Fully Implemented Features ✅

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
- ✅ Model-specific parameter mapping

**Modulation** (24 models):
- ✅ Enable/disable
- ✅ Model selection (11 stock + 13 FX)
- ✅ Dynamic parameters (up to 3 per model)
- ✅ Speed control (14-bit MSB/LSB)
- ✅ Tempo sync (note divisions)
- ✅ Mix control

**Delay** (14 models):
- ✅ Enable/disable
- ✅ Model selection (9 stock + 5 FX)
- ✅ Dynamic parameters (up to 3 per model)
- ✅ Time control (14-bit MSB/LSB)
- ✅ Tempo sync (note divisions)
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
  - Tempo-synced effects (Delay/Mod)

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
  - List view with all 128 patches
  - Bank organization (A/B/C/D, 1-32 per bank)
  - Current patch highlighting
  - Modified patches indicator

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
  - Value display
  - Min/max indicators
  - Custom formatters (dB, %, Hz, ms, etc.)
  - Smooth animation

- ✅ **Effect Buttons**
  - Enable/disable toggle
  - LED indicator (on/off/bypassed states)
  - Opens effect modal on tap
  - Displays effect name

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

## Partially Implemented Features ⚠️

### Patch Management

- ⚠️ **Patch Rename**
  - UI has text input field
  - Changes name in edit buffer
  - Does NOT send sysex to update hardware name directly
  - Name is saved when patch is saved to hardware

**Status**: Functional but indirect (requires full patch save)

### Testing

- ⚠️ **Limited Test Coverage**
  - Only basic widget_test.dart exists
  - No unit tests for protocol layer
  - No integration tests for PodController
  - No mock MIDI service

**Status**: Production code works but testing infrastructure is minimal

---

## Not Implemented / Missing Features ❌

### Advanced Patch Management

- ❌ **Patch Copy/Paste**
  - Copy edit buffer to clipboard
  - Paste to different slot

- ❌ **Patch Export/Import (Files)**
  - Export patches to .syx files
  - Import patches from .syx files
  - Backup entire library to file
  - Restore library from backup

- ❌ **Undo/Redo**
  - Parameter change history
  - Multi-level undo/redo
  - Command pattern implementation

- ❌ **A/B Comparison Mode**
  - Store two patches in memory
  - Quick toggle between A/B
  - Compare different settings

### Organization & Favorites

- ❌ **Patch Tags/Categories**
  - User-defined tags (e.g., "clean", "metal", "solo")
  - Filter patches by tag
  - Multi-tag support

- ❌ **Favorites List**
  - Mark patches as favorites
  - Quick access to favorite patches
  - Favorite-only view

- ❌ **Setlists**
  - Create ordered lists of patches
  - Quick navigation during performance
  - Multiple setlists

### Effects & Visualization

- ❌ **Tuner Display**
  - POD sends tuner data (03 56)
  - App receives data but doesn't display
  - Needs visual tuner meter (needle or LED-style)

- ❌ **Effect Parameter Animations**
  - Animated waveforms for mod effects
  - Visual delay feedback
  - Reverb decay visualization

- ❌ **Waveform Displays**
  - Stomp effect waveforms
  - Mod LFO visualization
  - Delay echo pattern

### MIDI Features

- ❌ **MIDI Learn**
  - Assign external MIDI controllers to parameters
  - Map CC messages from external devices
  - Save controller mappings

- ❌ **MIDI Program Change Mapping**
  - Map external PC messages to patches
  - Setlist integration

- ❌ **MIDI Clock Sync**
  - Sync tempo to external MIDI clock
  - MIDI clock output

### Advanced Features

- ❌ **Parameter Randomization**
  - Randomize selected parameters
  - Intelligent randomization (musically useful ranges)
  - Exclude specific parameters

- ❌ **Morphing Between Patches**
  - Smooth transition between two patches
  - Adjustable morph speed
  - Parameter interpolation

- ❌ **Preset Browser**
  - Search patches by name
  - Filter by amp/effect type
  - Sort by last modified

### UI Enhancements

- ❌ **Portrait Mode Support**
  - Currently landscape-only
  - Portrait mode could use scrolling layout

- ❌ **Dark/Light Theme Toggle**
  - Currently fixed dark theme
  - Light mode for outdoor use

- ❌ **Custom Color Schemes**
  - User-selectable color palettes
  - High-contrast mode

- ❌ **Accessibility Features**
  - Screen reader support
  - High-contrast mode
  - Larger fonts option

- ❌ **Tablet/iPad Optimization**
  - Larger screen layout
  - Multi-column layout
  - Floating palettes

### Technical Features

- ❌ **Offline Mode**
  - Use app without hardware connection
  - Edit patches offline
  - Sync when reconnected

- ❌ **Patch Caching**
  - Cache patch library to disk
  - Avoid re-importing on every launch
  - Invalidate cache on hardware change

- ❌ **Performance Optimization**
  - Reduce UI rebuilds (use const widgets)
  - Optimize bulk import (parallel requests if safe)
  - Lazy loading for large lists

### Development & Testing

- ❌ **Comprehensive Unit Tests**
  - Protocol layer tests (sysex parsing, CC mapping)
  - Model tests (patch encoding/decoding)
  - Value formatter tests

- ❌ **Integration Tests**
  - PodController with mock MIDI service
  - Parameter read/write flow
  - Bulk import logic

- ❌ **Widget Tests**
  - RotaryKnob interaction
  - Effect button states
  - Modal dialogs

- ❌ **Mock MIDI Device**
  - Software POD emulator for testing
  - Automated end-to-end tests
  - CI/CD integration

- ❌ **CI/CD Pipeline**
  - Automated builds
  - Automated tests
  - Release automation

---

## Known Limitations

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

1. **No Patch Caching**
   - Patch library must be re-imported on every app launch
   - Takes ~6.4 seconds each time
   - No persistence between sessions

2. **Limited Error Recovery**
   - No retry logic for failed sysex
   - Timeout handling could be more robust
   - Connection loss requires manual reconnect

3. **Single Device**
   - Can only connect to one POD at a time
   - No multi-device support

4. **Platform Limitations**
   - Linux MIDI support limited (ALSA required)
   - Windows MIDI support limited (Win32 API required)
   - Web platform not supported (no MIDI API)

---

## Roadmap

### Short-Term (Next Sprint)

1. **Patch Caching**
   - Cache patch library to SharedPreferences or local file
   - Significantly reduce app startup time
   - Invalidate cache on manual request

2. **Tuner Display**
   - Parse tuner sysex (03 56)
   - Display note name and cents offset
   - Visual tuner meter

3. **Error Recovery**
   - Retry failed sysex messages
   - Timeout handling for store operations
   - Auto-reconnect on connection loss

### Medium-Term (Next Month)

1. **Patch Export/Import**
   - Export patches to .syx files
   - Import patches from .syx files
   - Share patches with other users

2. **Undo/Redo**
   - Command pattern implementation
   - Multi-level undo/redo
   - Persists across parameter changes

3. **A/B Comparison**
   - Quick toggle between two patches
   - Compare before/after settings
   - Useful for fine-tuning

4. **Comprehensive Testing**
   - Unit tests for protocol layer
   - Integration tests for PodController
   - Widget tests for UI components

### Long-Term (Next Quarter)

1. **Advanced Organization**
   - Tags/categories
   - Favorites
   - Setlists

2. **MIDI Learn**
   - Assign external controllers
   - Save controller mappings

3. **Portrait Mode Support**
   - Scrolling layout for portrait
   - Responsive design

4. **Performance Optimization**
   - Reduce UI rebuilds
   - Optimize bulk import
   - Lazy loading

### Future Ideas (Backlog)

1. **Morphing Between Patches**
   - Smooth transitions
   - Parameter interpolation

2. **Effect Visualizations**
   - Animated waveforms
   - LFO displays

3. **Custom Color Schemes**
   - User themes
   - Dark/light mode

4. **Tablet Optimization**
   - Multi-column layout
   - Larger screens

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

### Features NOT Yet Implemented from POD-UI

- ❌ Effect library (64 effect presets at address 0x0200+)
- ❌ Per-patch edited state tracking (XtProgramEditState)
- ❌ Virtual controls (UI-only parameters)
- ❌ Special parameter formatters (gate threshold, heel/toe)
- ❌ Queue-based request/response matching
- ❌ Program number request queue

### Flutter-Specific Features (Not in POD-UI)

- ✅ Mobile UI optimized for touch
- ✅ POD hardware-inspired appearance
- ✅ Stream-based reactive architecture
- ✅ Modal dialogs for detailed settings
- ✅ Settings persistence
- ✅ Hot-plug device detection
- ✅ BLE MIDI support (POD-UI is USB-only)

---

## Contributing

If you'd like to contribute, consider implementing one of the missing features:

**Easy**:
- Tuner display
- Patch export/import (.syx files)
- Dark/light theme toggle

**Medium**:
- Undo/redo with command pattern
- A/B comparison mode
- MIDI learn

**Hard**:
- Comprehensive test suite
- Portrait mode support
- Morphing between patches

See `ARCHITECTURE.md` for code structure and design patterns.
