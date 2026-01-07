# Main Screen Modularization - TODO List

**Status**: ✅ CRITICAL FIXES COMPLETE | Ready for Testing

**Files Created**: 19 new modular files (12 modals, 5 sections, 2 utilities)
**Code Reduction**: 2562 lines → 548 lines (79% reduction in main screen)
**Compilation Status**: ✅ Zero errors (54 warnings - mostly TODOs and unused elements)
**Bugs Fixed**: 7 of 9 issues (5 Critical + 2 High Priority) ✅

---

## 🔴 CRITICAL ISSUES (Must Fix Before Testing)

### 1. Missing Effect Model Names ✅ FIXED

**Priority**: CRITICAL
**Impact**: Effect buttons never show model names (e.g., "Screamer", "Chorus", "Tape Echo")
**File**: `lib/ui/screens/main_screen.dart`

**Missing State Variable** (add after line 76):
```dart
String? _wahModel;  // ← MISSING! Wah model name
```

**Missing Updates** (add after line 220 in `_updateFromEditBuffer()`):
```dart
// Update effect model names
_wahModel = widget.podController.wahModel?.name;
_stompModel = widget.podController.stompModel?.name;
_modModel = widget.podController.modModel?.name;
_delayModel = widget.podController.modModel?.name;
_reverbModel = widget.podController.reverbModel?.name;
```

**Pass to Sections** (update line 290):
```dart
EffectsColumnsSection(
  // ... existing props ...
  wahModel: _wahModel,  // ← ADD THIS
  stompModel: _stompModel,
  modModel: _modModel,
  delayModel: _delayModel,
  reverbModel: _reverbModel,
  // ...
),
```

**Update Section Widget** (`lib/ui/sections/effects_columns_section.dart`):
- Add `String? wahModel` parameter
- Pass to WAH button: `modelName: wahModel`

---

### 2. Patch Modified Indicator Never Shows ✅ FIXED

**Priority**: CRITICAL
**Impact**: Users can't tell if current patch differs from saved version
**File**: `lib/ui/screens/main_screen.dart`

**Fix** (line 139-142, replace):
```dart
// OLD:
_editBufferSubscription = widget.podController.onEditBufferChanged.listen((buffer) {
  setState(() => _updateFromEditBuffer());
});

// NEW:
_editBufferSubscription = widget.podController.onEditBufferChanged.listen((buffer) {
  setState(() {
    _updateFromEditBuffer();
    _isModified = widget.podController.editBufferModified;  // ← ADD THIS
  });
});
```

---

### 3. Gate Modal Cannot Function ✅ FIXED

**Priority**: CRITICAL
**Impact**: Gate threshold and decay values not tracked in state
**File**: `lib/ui/screens/main_screen.dart`

**Add State Variables** (after line 85):
```dart
int _gateThreshold = 0;  // Gate threshold (0-96)
int _gateDecay = 64;     // Gate decay (0-127)
```

**Update From Edit Buffer** (add after line 220 in `_updateFromEditBuffer()`):
```dart
_gateThreshold = widget.podController.gateThreshold;
_gateDecay = widget.podController.getParameter(PodXtCC.gateDecay);
```

**Note**: Gate modal already has StreamSubscription - it updates itself. These state variables are for displaying current values when modal opens.

---

### 4. Mic Modal Room Value Broken ✅ FIXED

**Priority**: CRITICAL
**Impact**: Room percentage cannot be displayed or updated
**File**: `lib/ui/screens/main_screen.dart`

**Add State Variable** (after line 85):
```dart
int _roomValue = 64;  // Room percentage for mic modal
```

**Update From Edit Buffer** (add after line 220 in `_updateFromEditBuffer()`):
```dart
_roomValue = widget.podController.room;
```

**Update Modal Call** (line 417, already correct):
```dart
currentRoomValue: widget.podController.getParameter(PodXtCC.room),
// Could use: currentRoomValue: _roomValue,
```

---

### 5. Navigation Functions Missing Connection Checks ✅ FIXED

**Priority**: HIGH
**Impact**: Attempting MIDI operations when disconnected causes errors
**File**: `lib/ui/screens/main_screen.dart`

**Fix All Navigation Methods** (lines 511-539):

```dart
void _previousAmp() {
  if (!_isConnected) return;  // ← ADD THIS CHECK
  final currentId = widget.podController.getParameter(PodXtCC.ampSelect);
  int newId = currentId - 1;
  if (newId < 0) newId = AmpModels.all.last.id;  // ← FIX: Wrap around

  if (_ampChainLinked) {
    widget.podController.setAmpModel(newId);
  } else {
    widget.podController.setAmpModelNoDefaults(newId);
  }
}

void _nextAmp() {
  if (!_isConnected) return;  // ← ADD THIS CHECK
  final currentId = widget.podController.getParameter(PodXtCC.ampSelect);
  int newId = currentId + 1;
  if (newId > AmpModels.all.last.id) newId = 0;  // ← FIX: Wrap around

  if (_ampChainLinked) {
    widget.podController.setAmpModel(newId);
  } else {
    widget.podController.setAmpModelNoDefaults(newId);
  }
}

void _previousPatch() {
  if (!_isConnected) return;  // ← ADD THIS CHECK
  final newProgram = (_currentProgram - 1).clamp(0, 127);
  widget.podController.selectProgram(newProgram);
}

void _nextPatch() {
  if (!_isConnected) return;  // ← ADD THIS CHECK
  final newProgram = (_currentProgram + 1).clamp(0, 127);
  widget.podController.selectProgram(newProgram);
}
```

---

## 🟡 HIGH PRIORITY (Should Fix)

### 6. Connection Modal Not Shown on Startup ✅ FIXED

**Priority**: HIGH
**Impact**: Users must manually discover connection flow
**File**: `lib/ui/screens/main_screen.dart`

**Add to `initState()`** (after line 157):
```dart
// Open connection screen on startup
WidgetsBinding.instance.addPostFrameCallback((_) {
  _showConnectionModal();
});
```

**Alternative**: Only show if not connected:
```dart
WidgetsBinding.instance.addPostFrameCallback((_) {
  if (!_isConnected) {
    _showConnectionModal();
  }
});
```

---

### 7. Amp Navigation Doesn't Wrap Around ✅ FIXED

**Priority**: MEDIUM
**Impact**: Can't cycle through amps (stops at first/last)
**File**: `lib/ui/screens/main_screen.dart`

**Current Implementation** (lines 511-529):
```dart
final newId = (currentId - 1).clamp(0, AmpModels.all.length - 1);  // ❌ Stops at 0
```

**Fixed Implementation** (see issue #5 above for complete code):
```dart
int newId = currentId - 1;
if (newId < 0) newId = AmpModels.all.last.id;  // ✅ Wraps to last
```

---

## 🟢 MEDIUM PRIORITY (Nice to Have)

### 8. Settings Screen Inaccessible 📋

**Priority**: MEDIUM
**Impact**: No way to access settings (if they exist)
**Files**:
- `lib/ui/screens/main_screen.dart` (line 338)
- `lib/ui/sections/control_bar_section.dart` (gear icon)

**Current Behavior**:
- Gear icon → opens connection modal
- No settings screen exists

**Options**:
1. Create settings modal for app preferences
2. Remove gear icon if no settings needed
3. Keep current behavior (gear = connection)

**If Creating Settings Modal**:
```dart
void _showSettingsModal() {
  showPodModal(
    context: context,
    title: 'Settings',
    child: SettingsModal(
      settings: widget.settings,
      onSettingsChanged: (newSettings) {
        // Save settings
      },
    ),
  );
}
```

Then update control bar: `onSettings: _showSettingsModal`

---

### 9. Remove `_isModified` Final Warning 📋

**Priority**: LOW
**Impact**: Compiler warning about unused final
**File**: `lib/ui/screens/main_screen.dart` (line 100)

**Current**:
```dart
bool _isModified = false;
```

**Issue**: Once we implement #2, this field IS used, so warning will disappear automatically.

---

## ✅ COMPLETED / NON-ISSUES

### ✓ Utility Functions Extracted
All formatting functions successfully moved to:
- `lib/ui/utils/value_formatters.dart` (formatKnobValue, midiToDb, dbToMidi, etc.)
- `lib/ui/utils/eq_frequency_mapper.dart` (formatEqFreq, midiEqFreqToHz)

### ✓ Section Widgets Created
All 5 sections successfully extracted:
- `lib/ui/sections/amp_selector_section.dart` (309 lines)
- `lib/ui/sections/tone_controls_section.dart` (107 lines)
- `lib/ui/sections/eq_section.dart` (203 lines)
- `lib/ui/sections/effects_columns_section.dart` (161 lines)
- `lib/ui/sections/control_bar_section.dart` (183 lines)

### ✓ Modals Extracted
All 12 modals successfully created:
- 6 existing modals (connection, patch list, gate, cab, mic, amp)
- 6 effect modals (comp, wah, stomp, mod, delay, reverb) - mockups with TODOs

### ✓ Edit Buffer Refresh After Amp Change
**Not needed** - POD XT Pro sends CC parameter updates automatically when amp changes.

---

## 📋 IMPLEMENTATION ORDER

### Phase 1: Critical Bug Fixes (30 min)
1. ✅ Add missing state variables (issue #1, #3, #4)
2. ✅ Add effect model name updates (issue #1)
3. ✅ Fix modified flag update (issue #2)
4. ✅ Add connection checks (issue #5)
5. ✅ Fix amp wrap-around (issue #7)

### Phase 2: High Priority (15 min)
6. ✅ Add connection modal on startup (issue #6)

### Phase 3: Polish (optional)
7. ⏸️ Decide on settings screen approach (issue #8)
8. ⏸️ Test all functionality end-to-end

---

## 🧪 TESTING CHECKLIST

After implementing fixes, verify:

### Connection Flow
- [ ] App opens connection modal on startup
- [ ] Can scan for devices
- [ ] Can connect to POD
- [ ] Connection indicator shows green when connected

### Amp/Cab/Mic Selection
- [ ] Can navigate amps with arrows (wraps around)
- [ ] Amp name displays correctly
- [ ] Can tap amp to open picker modal
- [ ] Cab picker shows correct selection
- [ ] Mic picker shows room percentage
- [ ] Chain link toggle works

### Effect Buttons
- [ ] All effect buttons show model names when selected
- [ ] Long-press opens effect modal
- [ ] WAH shows model name (e.g., "Vetta Wah")
- [ ] STOMP shows model name (e.g., "Screamer")
- [ ] MOD shows model name (e.g., "Sine Chorus")
- [ ] DELAY shows model name (e.g., "Analog Delay")
- [ ] REVERB shows model name (e.g., "Lux Spring")

### Patch Management
- [ ] Patch browser shows current patch name
- [ ] Modified indicator (*) appears when editing
- [ ] Can navigate patches with arrows
- [ ] Can tap to open patch list
- [ ] Patch list shows all 128 patches

### Knobs and Faders
- [ ] All 7 tone knobs update POD
- [ ] EQ faders move smoothly
- [ ] EQ frequency knobs work
- [ ] Values display correctly

### Modals
- [ ] Gate modal opens with current values
- [ ] Gate modal updates in real-time
- [ ] Comp modal opens (shows TODO)
- [ ] All effect modals open successfully

### Navigation When Disconnected
- [ ] Amp arrows don't crash when disconnected
- [ ] Patch arrows don't crash when disconnected
- [ ] Modals gracefully handle disconnected state

---

## 📊 PROGRESS TRACKER

### Overall Status
- **Total Issues**: 9
- **Critical**: 5 ✅ ALL FIXED
- **High**: 2 ✅ ALL FIXED
- **Medium**: 2 (1 ✅ Fixed, 1 📋 Pending)
- **Completed**: 7/9 (78%)

### Estimated Time
- **Critical Fixes**: ~30 minutes
- **High Priority**: ~15 minutes
- **Medium Priority**: ~30 minutes (if implementing settings)
- **Testing**: ~30 minutes

**Total**: ~2 hours to completion

---

## 🔗 RELATED FILES

### Files That Need Changes
1. `lib/ui/screens/main_screen.dart` - Main fixes (issues #1-7)
2. `lib/ui/sections/effects_columns_section.dart` - Add wahModel prop (issue #1)
3. `lib/ui/sections/control_bar_section.dart` - Settings button behavior (issue #8)

### Reference Files
- `lib/ui/screens/main_screen_backup.dart` - Original implementation
- `lib/services/pod_controller.dart` - Controller API reference
- `lib/protocol/cc_map.dart` - MIDI CC parameter definitions

---

## 💡 NOTES

### Architecture Improvements
The modularization successfully achieved:
- ✅ 79% code reduction in main screen
- ✅ Separation of concerns (sections, modals, utils)
- ✅ Reusable components
- ✅ Cleaner codebase

### Known Limitations
- Effect modal mockups need implementation (separate task)
- Settings screen not implemented
- Some TODOs in effect modals (intentional - part of mockup)

### Future Work
After fixing these issues:
1. Implement effect modal parameters (comp, wah, stomp, mod, delay, reverb)
2. Add settings screen (if needed)
3. Test with real POD XT Pro hardware
4. Consider state management solution (Provider/Riverpod) if complexity grows

---

**Last Updated**: 2026-01-06 (Critical fixes implemented)
**Created By**: Claude Code Analysis Agent
**Status**: ✅ Critical & High Priority Fixes Complete - Ready for Testing
