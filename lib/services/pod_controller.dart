/// POD XT Pro Controller Service
/// High-level interface for controlling the POD

library;

import 'dart:async';
import 'dart:typed_data';
import '../models/patch.dart';
import '../models/amp_models.dart';
import '../models/cab_models.dart';
import '../models/effect_models.dart';
import '../protocol/cc_map.dart';
import '../protocol/sysex.dart';
import '../protocol/constants.dart';
import 'midi_service.dart';

/// Connection state
enum PodConnectionState { disconnected, scanning, connecting, connected, error }

/// POD XT Pro Controller
///
/// Manages:
/// - Device connection and identification
/// - Edit buffer synchronization
/// - Parameter read/write
/// - Patch management
/// - Real-time parameter updates
class PodController {
  final MidiService _midi;

  // State
  PodConnectionState _connectionState = PodConnectionState.disconnected;
  EditBuffer _editBuffer = EditBuffer();
  final PatchLibrary _patchLibrary = PatchLibrary();
  int _currentProgram = 0;
  int _installedPacks = 0;
  bool _patchesSynced = false;
  int _patchesSyncedCount = 0;

  // Stream controllers
  final _connectionStateController =
      StreamController<PodConnectionState>.broadcast();
  final _parameterChangeController =
      StreamController<ParameterChange>.broadcast();
  final _programChangeController = StreamController<int>.broadcast();
  final _editBufferController = StreamController<EditBuffer>.broadcast();
  final _syncProgressController = StreamController<SyncProgress>.broadcast();
  final _storeResultController = StreamController<StoreResult>.broadcast();

  // Subscriptions
  StreamSubscription? _ccSubscription;
  StreamSubscription? _pcSubscription;
  StreamSubscription? _sysexSubscription;

  // Bulk import tracking
  Completer<void>? _patchDumpCompleter;
  int? _expectedPatchNumber;
  bool _bulkImportInProgress = false;

  // Save operation tracking
  int? _lastSavedPatchNumber;
  List<int>? _lastSavedPatchData;

  // CC handling - suppress marking as modified right after patch load
  bool _suppressModifiedFlag = false;

  PodController(this._midi) {
    _setupListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PUBLIC API - State
  // ═══════════════════════════════════════════════════════════════════════════

  PodConnectionState get connectionState => _connectionState;
  Stream<PodConnectionState> get onConnectionStateChanged =>
      _connectionStateController.stream;

  EditBuffer get editBuffer => _editBuffer;
  Stream<EditBuffer> get onEditBufferChanged => _editBufferController.stream;

  PatchLibrary get patchLibrary => _patchLibrary;

  int get currentProgram => _currentProgram;
  Stream<int> get onProgramChanged => _programChangeController.stream;

  Stream<ParameterChange> get onParameterChanged =>
      _parameterChangeController.stream;

  /// Sync progress (0-128 patches)
  bool get patchesSynced => _patchesSynced;
  int get patchesSyncedCount => _patchesSyncedCount;
  Stream<SyncProgress> get onSyncProgress => _syncProgressController.stream;

  /// Store operation results (success/failure)
  Stream<StoreResult> get onStoreResult => _storeResultController.stream;

  /// Get patch name by program number
  String getPatchName(int program) {
    if (program < 0 || program >= programCount) return '';
    return _patchLibrary[program].name;
  }

  /// Check if current edit buffer differs from stored patch
  bool get editBufferModified {
    if (!_patchesSynced || _editBuffer.sourceProgram == null) return false;
    // Compare current edit buffer with stored patch
    final stored = _patchLibrary[_editBuffer.sourceProgram!];
    return _editBuffer.patch.data.toString() != stored.data.toString();
  }

  /// Debug method: compare edit buffer with stored patch byte-by-byte
  /// Returns list of differences (byte index, edit buffer value, stored value)
  List<String> debugComparePatch() {
    if (!_patchesSynced || _editBuffer.sourceProgram == null) {
      return ['No patch loaded or patches not synced'];
    }

    final stored = _patchLibrary[_editBuffer.sourceProgram!];
    final editData = _editBuffer.patch.data;
    final storedData = stored.data;

    if (editData.length != storedData.length) {
      return ['ERROR: Different lengths! Edit=${editData.length}, Stored=${storedData.length}'];
    }

    final differences = <String>[];

    // Find parameter name for each address
    String getParamName(int address) {
      for (final param in PodXtCC.all) {
        if (param.address == address) {
          return param.name;
        }
      }
      return 'unknown';
    }

    for (int i = 0; i < editData.length; i++) {
      if (editData[i] != storedData[i]) {
        final paramName = getParamName(i);
        differences.add(
          'Byte $i ($paramName): Edit=${editData[i]} (0x${editData[i].toRadixString(16).padLeft(2, '0')}), '
          'Stored=${storedData[i]} (0x${storedData[i].toRadixString(16).padLeft(2, '0')})',
        );
      }
    }

    if (differences.isEmpty) {
      return ['No differences found - patches are identical'];
    }

    // Add context: show byte 39 and nearby bytes regardless of differences
    differences.add('\n--- Context around byte 39 (volLevel) ---');
    for (int i = 35; i <= 45; i++) {
      if (i < editData.length) {
        final paramName = getParamName(i);
        differences.add(
          'Byte $i ($paramName): Edit=${editData[i]}, Stored=${storedData[i]}',
        );
      }
    }

    return differences;
  }

  /// Check if expansion pack is installed
  bool hasExpansionPack(int packFlag) => (_installedPacks & packFlag) != 0;

  // ═══════════════════════════════════════════════════════════════════════════
  // PUBLIC API - Connection
  // ═══════════════════════════════════════════════════════════════════════════

  /// Scan for available MIDI devices
  Future<List<MidiDeviceInfo>> scanDevices() async {
    _setConnectionState(PodConnectionState.scanning);
    try {
      return await _midi.scanDevices();
    } finally {
      if (_connectionState == PodConnectionState.scanning) {
        _setConnectionState(PodConnectionState.disconnected);
      }
    }
  }

  /// Stream of device changes (fires when devices are connected/disconnected)
  /// Use this to auto-refresh device list when USB devices are hot-plugged
  Stream<List<MidiDeviceInfo>> get onDevicesChanged => _midi.onDevicesChanged;

  /// Connect to a MIDI device
  Future<void> connect(MidiDeviceInfo device) async {
    _setConnectionState(PodConnectionState.connecting);
    try {
      await _midi.connect(device);
      _setConnectionState(PodConnectionState.connected);

      // Request initial state
      await _requestInitialState();
    } catch (e) {
      _setConnectionState(PodConnectionState.error);
      rethrow;
    }
  }

  /// Disconnect
  Future<void> disconnect() async {
    await _midi.disconnect();
    _setConnectionState(PodConnectionState.disconnected);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PUBLIC API - Parameters
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get current parameter value
  int getParameter(CCParam param) {
    return _editBuffer.patch.getValue(param);
  }

  /// Get 16-bit parameter value
  int getParameter16(CCParam msbParam, CCParam lsbParam) {
    return _editBuffer.patch.getValue16(msbParam, lsbParam);
  }

  /// Get switch state
  bool getSwitch(CCParam param) {
    return _editBuffer.patch.getSwitch(param);
  }

  /// Set parameter value (sends to device and updates local state)
  Future<void> setParameter(CCParam param, int value) async {
    final clampedValue = value.clamp(param.minValue, param.maxValue);

    // Update local state
    _editBuffer.patch.setValue(param, clampedValue);
    _editBuffer.markModified();

    // Send to device. If parameter is marked inverted, MIDI/CC value
    // semantics are inverted as well, so send the inverted value.
    final sendValue = param.inverted
        ? (param.maxValue - clampedValue)
        : clampedValue;
    await _midi.sendParam(param, sendValue);

    // Notify listeners
    _parameterChangeController.add(ParameterChange(param, clampedValue));
    _editBufferController.add(_editBuffer);
  }

  /// Set 16-bit parameter value
  Future<void> setParameter16(
    CCParam msbParam,
    CCParam lsbParam,
    int value,
  ) async {
    final msb = (value >> 7) & 0x7F;
    final lsb = value & 0x7F;

    // Update local state
    _editBuffer.patch.setValue(msbParam, msb);
    _editBuffer.patch.setValue(lsbParam, lsb);
    _editBuffer.markModified();

    // Send to device (both CCs)
    await _midi.sendParam(msbParam, msb);
    await _midi.sendParam(lsbParam, lsb);

    _editBufferController.add(_editBuffer);
  }

  /// Set switch state
  Future<void> setSwitch(CCParam param, bool enabled) async {
    await setParameter(param, enabled ? 127 : 0);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PUBLIC API - Convenience Accessors
  // ═══════════════════════════════════════════════════════════════════════════

  // Amp
  AmpModel? get ampModel => AmpModels.byId(getParameter(PodXtCC.ampSelect));
  Future<void> setAmpModel(int id) => setParameter(PodXtCC.ampSelect, id);

  /// Set amp model without loading defaults (preserves current parameters)
  Future<void> setAmpModelNoDefaults(int id) async {
    // Use CC 12 to change amp without resetting parameters
    await _midi.sendParam(PodXtCC.ampSelectNoDefaults, id);
    // Also update local state
    _editBuffer.patch.setValue(PodXtCC.ampSelect, id);
    _editBuffer.markModified();
    _editBufferController.add(_editBuffer);
  }

  int get drive => getParameter(PodXtCC.drive);
  Future<void> setDrive(int value) => setParameter(PodXtCC.drive, value);

  int get bass => getParameter(PodXtCC.bass);
  Future<void> setBass(int value) => setParameter(PodXtCC.bass, value);

  int get mid => getParameter(PodXtCC.mid);
  Future<void> setMid(int value) => setParameter(PodXtCC.mid, value);

  int get treble => getParameter(PodXtCC.treble);
  Future<void> setTreble(int value) => setParameter(PodXtCC.treble, value);

  int get presence => getParameter(PodXtCC.presence);
  Future<void> setPresence(int value) => setParameter(PodXtCC.presence, value);

  int get channelVolume => getParameter(PodXtCC.chanVolume);
  Future<void> setChannelVolume(int value) =>
      setParameter(PodXtCC.chanVolume, value);

  // Cabinet
  CabModel? get cabModel => CabModels.byId(getParameter(PodXtCC.cabSelect));
  Future<void> setCabModel(int id) => setParameter(PodXtCC.cabSelect, id);

  // Mic - POD uses 0-3, names differ based on cab type (guitar vs bass)
  MicModel? get micModel {
    final micPosition = getParameter(PodXtCC.micSelect);
    final isBass = cabModel?.pack == 'BX';
    return MicModels.byPosition(micPosition, isBass: isBass);
  }

  Future<void> setMicModel(int position) =>
      setParameter(PodXtCC.micSelect, position);

  int get room => getParameter(PodXtCC.room);
  Future<void> setRoom(int value) => setParameter(PodXtCC.room, value);

  // Stomp
  bool get stompEnabled => getSwitch(PodXtCC.stompEnable);
  Future<void> setStompEnabled(bool v) => setSwitch(PodXtCC.stompEnable, v);

  EffectModel? get stompModel =>
      StompModels.byId(getParameter(PodXtCC.stompSelect));
  Future<void> setStompModel(int id) => setParameter(PodXtCC.stompSelect, id);

  // Modulation
  bool get modEnabled => getSwitch(PodXtCC.modEnable);
  Future<void> setModEnabled(bool v) => setSwitch(PodXtCC.modEnable, v);

  EffectModel? get modModel => ModModels.byId(getParameter(PodXtCC.modSelect));
  Future<void> setModModel(int id) => setParameter(PodXtCC.modSelect, id);

  int get modSpeed => getParameter16(PodXtCC.modSpeedMsb, PodXtCC.modSpeedLsb);
  Future<void> setModSpeed(int value) =>
      setParameter16(PodXtCC.modSpeedMsb, PodXtCC.modSpeedLsb, value);

  int get modMix => getParameter(PodXtCC.modMix);
  Future<void> setModMix(int value) => setParameter(PodXtCC.modMix, value);

  // Delay
  bool get delayEnabled => getSwitch(PodXtCC.delayEnable);
  Future<void> setDelayEnabled(bool v) => setSwitch(PodXtCC.delayEnable, v);

  EffectModel? get delayModel =>
      DelayModels.byId(getParameter(PodXtCC.delaySelect));
  Future<void> setDelayModel(int id) => setParameter(PodXtCC.delaySelect, id);

  int get delayTime =>
      getParameter16(PodXtCC.delayTimeMsb, PodXtCC.delayTimeLsb);
  Future<void> setDelayTime(int value) =>
      setParameter16(PodXtCC.delayTimeMsb, PodXtCC.delayTimeLsb, value);

  int get delayMix => getParameter(PodXtCC.delayMix);
  Future<void> setDelayMix(int value) => setParameter(PodXtCC.delayMix, value);

  // Reverb
  bool get reverbEnabled => getSwitch(PodXtCC.reverbEnable);
  Future<void> setReverbEnabled(bool v) => setSwitch(PodXtCC.reverbEnable, v);

  EffectModel? get reverbModel =>
      ReverbModels.byId(getParameter(PodXtCC.reverbSelect));
  Future<void> setReverbModel(int id) => setParameter(PodXtCC.reverbSelect, id);

  int get reverbDecay => getParameter(PodXtCC.reverbDecay);
  Future<void> setReverbDecay(int value) =>
      setParameter(PodXtCC.reverbDecay, value);

  int get reverbLevel => getParameter(PodXtCC.reverbLevel);
  Future<void> setReverbLevel(int value) =>
      setParameter(PodXtCC.reverbLevel, value);

  // Noise Gate
  bool get noiseGateEnabled => getSwitch(PodXtCC.noiseGateEnable);
  Future<void> setNoiseGateEnabled(bool v) =>
      setSwitch(PodXtCC.noiseGateEnable, v);

  int get gateThreshold => getParameter(PodXtCC.gateThreshold);
  Future<void> setGateThreshold(int value) =>
      setParameter(PodXtCC.gateThreshold, value);

  // Compressor
  bool get compressorEnabled => getSwitch(PodXtCC.compressorEnable);
  Future<void> setCompressorEnabled(bool v) =>
      setSwitch(PodXtCC.compressorEnable, v);

  // Wah
  bool get wahEnabled => getSwitch(PodXtCC.wahEnable);
  Future<void> setWahEnabled(bool v) => setSwitch(PodXtCC.wahEnable, v);

  EffectModel? get wahModel => WahModels.byId(getParameter(PodXtCC.wahSelect));
  Future<void> setWahModel(int id) => setParameter(PodXtCC.wahSelect, id);

  // EQ
  bool get eqEnabled => getSwitch(PodXtCC.eqEnable);
  Future<void> setEqEnabled(bool v) => setSwitch(PodXtCC.eqEnable, v);

  // Loop (PODxt Pro only)
  bool get loopEnabled => getSwitch(PodXtCC.loopEnable);
  Future<void> setLoopEnabled(bool v) => setSwitch(PodXtCC.loopEnable, v);

  // Tempo
  int get tempo => getParameter16(PodXtCC.tempoMsb, PodXtCC.tempoLsb);

  /// Set tempo in BPM (30-240)
  Future<void> setTempo(int bpm) {
    // Convert BPM to internal value (BPM * 10)
    // Range: 30-240 BPM -> 300-2400 internal
    final internalValue = (bpm.clamp(30, 240) * 10);
    return setParameter16(PodXtCC.tempoMsb, PodXtCC.tempoLsb, internalValue);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PUBLIC API - Program Management
  // ═══════════════════════════════════════════════════════════════════════════

  /// Change to a different program
  Future<void> selectProgram(int program) async {
    if (program < 0 || program >= programCount) return;

    await _midi.sendProgramChange(program);
    _currentProgram = program;
    _programChangeController.add(program);

    // Request the new edit buffer
    await _midi.requestEditBuffer();
  }

  /// Save current edit buffer to a program slot
  Future<void> saveToProgram(int program) async {
    // TODO: Implement sysex store command
    throw UnimplementedError('Save to program not yet implemented');
  }

  /// Load a patch to the edit buffer and send all parameters to hardware
  Future<void> loadPatchToHardware(Patch patch) async {
    // Update edit buffer
    _editBuffer.patch = patch.copy();
    _editBuffer.modified = true;
    _editBuffer.sourceProgram = null; // No source program

    _suppressModifiedFlag = true;

    // Send all key parameters to hardware via CC
    // Amp section
    await setParameter(PodXtCC.ampSelect, patch.getValue(PodXtCC.ampSelect));
    await setParameter(PodXtCC.drive, patch.getValue(PodXtCC.drive));
    await setParameter(PodXtCC.bass, patch.getValue(PodXtCC.bass));
    await setParameter(PodXtCC.mid, patch.getValue(PodXtCC.mid));
    await setParameter(PodXtCC.treble, patch.getValue(PodXtCC.treble));
    await setParameter(PodXtCC.presence, patch.getValue(PodXtCC.presence));
    await setParameter(PodXtCC.chanVolume, patch.getValue(PodXtCC.chanVolume));
    await setSwitch(PodXtCC.ampEnable, patch.getSwitch(PodXtCC.ampEnable));

    // Cab section
    await setParameter(PodXtCC.cabSelect, patch.getValue(PodXtCC.cabSelect));
    await setParameter(PodXtCC.micSelect, patch.getValue(PodXtCC.micSelect));
    await setParameter(PodXtCC.room, patch.getValue(PodXtCC.room));

    // Effects enables
    await setSwitch(PodXtCC.noiseGateEnable, patch.getSwitch(PodXtCC.noiseGateEnable));
    await setSwitch(PodXtCC.wahEnable, patch.getSwitch(PodXtCC.wahEnable));
    await setSwitch(PodXtCC.stompEnable, patch.getSwitch(PodXtCC.stompEnable));
    await setSwitch(PodXtCC.modEnable, patch.getSwitch(PodXtCC.modEnable));
    await setSwitch(PodXtCC.delayEnable, patch.getSwitch(PodXtCC.delayEnable));
    await setSwitch(PodXtCC.reverbEnable, patch.getSwitch(PodXtCC.reverbEnable));
    await setSwitch(PodXtCC.compressorEnable, patch.getSwitch(PodXtCC.compressorEnable));
    await setSwitch(PodXtCC.eqEnable, patch.getSwitch(PodXtCC.eqEnable));

    // Effect models
    await setParameter(PodXtCC.stompSelect, patch.getValue(PodXtCC.stompSelect));
    await setParameter(PodXtCC.modSelect, patch.getValue(PodXtCC.modSelect));
    await setParameter(PodXtCC.delaySelect, patch.getValue(PodXtCC.delaySelect));
    await setParameter(PodXtCC.reverbSelect, patch.getValue(PodXtCC.reverbSelect));

    // Delay/Reverb mix
    await setParameter(PodXtCC.delayMix, patch.getValue(PodXtCC.delayMix));
    await setParameter(PodXtCC.reverbLevel, patch.getValue(PodXtCC.reverbLevel));

    _suppressModifiedFlag = false;

    // Notify listeners
    _editBufferController.add(_editBuffer);
  }

  /// Refresh edit buffer from device
  Future<void> refreshEditBuffer() async {
    await _midi.requestEditBuffer();
  }

  /// Refresh all patches from device
  Future<void> refreshAllPatches() async {
    await _midi.requestAllPatches();
  }

  /// Send tap tempo message
  /// Tap this repeatedly to set the tempo
  Future<void> sendTapTempo() async {
    // POD XT uses CC 64 (sustain pedal) for tap tempo
    // Send value 127 (on) to register a tap
    await _midi.sendCC(64, 127);

    // Wait a bit for POD to process the tap, then request updated tempo
    // The POD doesn't send tempo CC updates automatically, we need to request edit buffer
    await Future.delayed(const Duration(milliseconds: 50));
    await _midi.requestEditBuffer();
  }

  /// Check if delay is in tempo sync mode (note division vs ms)
  bool get isDelayTempoSynced {
    final noteSelect = getParameter(PodXtCC.delayNoteSelect);
    // Value 0 = ms mode (not tempo synced)
    // Value > 0 = note division (tempo synced)
    return noteSelect > 0;
  }

  /// Get current tempo in BPM from edit buffer
  int get currentTempoBpm {
    final tempoMsb = getParameter(PodXtCC.tempoMsb);
    final tempoLsb = getParameter(PodXtCC.tempoLsb);

    // Combine MSB and LSB to get internal tempo value
    // POD XT stores the internal value directly (not normalized)
    // Internal range: 300-2400
    final internalValue = (tempoMsb << 7) | tempoLsb;

    // Convert to BPM using POD XT formula from pod-ui reference:
    // Display BPM = internal * 0.1
    // Range: 30.0-240.0 BPM (from internal 300-2400)
    if (internalValue < 300) return 120; // Default to 120 BPM if invalid

    final bpm = (internalValue * 0.1).round();
    final clampedBpm = bpm.clamp(30, 240);

    return clampedBpm;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIVATE - Setup & Handlers
  // ═══════════════════════════════════════════════════════════════════════════

  void _setupListeners() {
    _ccSubscription = _midi.onControlChange.listen(_handleControlChange);
    _pcSubscription = _midi.onProgramChange.listen(_handleProgramChange);
    _sysexSubscription = _midi.onSysex.listen(_handleSysex);
  }

  void _setConnectionState(PodConnectionState state) {
    _connectionState = state;
    _connectionStateController.add(state);
  }

  Future<void> _requestInitialState() async {
    // Wait a moment for the connection to stabilize
    await Future.delayed(const Duration(milliseconds: 500));

    // Reset sync state
    _patchesSynced = false;
    _patchesSyncedCount = 0;

    // Request expansion packs info
    await _midi.requestInstalledPacks();
    await Future.delayed(const Duration(milliseconds: 100));

    // Request current program state (to get correct program number)
    await _midi.requestProgramState();
    await Future.delayed(const Duration(milliseconds: 400));

    // Request current edit buffer
    await _midi.requestEditBuffer();

    // TODO: Implement individual patch requests if bulk request doesn't work
    // For now, mark as synced since we have the edit buffer
    _patchesSynced = true;
    _syncProgressController.add(
      SyncProgress(programCount, programCount, 'Ready'),
    );
  }

  void _handleControlChange(({int cc, int value}) change) {
    // Handle tap tempo (CC 64) - request edit buffer to get updated tempo
    if (change.cc == 64 && change.value == 127) {
      // Tap tempo received (from hardware or echo of our own tap)
      // Request edit buffer after a short delay to get updated tempo
      Future.delayed(const Duration(milliseconds: 100), () {
        _midi.requestEditBuffer();
      });
    }

    final param = PodXtCC.byCC[change.cc];
    if (param != null && param.address != null) {
      _editBuffer.patch.setValueAt(param.address!, change.value);

      // Only mark as modified if not suppressed (during patch load)
      if (!_suppressModifiedFlag) {
        _editBuffer.markModified();
      }

      _parameterChangeController.add(ParameterChange(param, change.value));
      _editBufferController.add(_editBuffer);

      // When amp is changed via hardware, POD loads new default parameters
      // Request full edit buffer to get all updated values
      if (param == PodXtCC.ampSelect) {
        _midi.requestEditBuffer();
      }
    }
  }

  void _handleProgramChange(int program) {
    _currentProgram = program;
    _programChangeController.add(program);
    // Request the edit buffer for the new program
    _midi.requestEditBuffer();
  }

  void _handleSysex(SysexMessage message) {
    // Route sysex messages to appropriate handlers
    if (message.isEditBufferDump) {
      _handleEditBufferDump(message);
    } else if (message.isPatchDump) {
      _handlePatchDump(message);
    } else if (message.isPatchDumpEnd) {
      _handlePatchDumpEnd(message);
    } else if (message.isInstalledPacks) {
      _handleInstalledPacks(message);
    } else if (message.isProgramState) {
      _handleProgramState(message);
    } else if (message.isStoreSuccess) {
      print('POD: Patch stored successfully');
      _handleStoreSuccess(message);
    } else if (message.isStoreFailure) {
      print('POD: ERROR - Patch store failed');
      _handleStoreFailure(message);
    }
  }

  void _handleEditBufferDump(SysexMessage message) {
    // POD XT format: [id, raw_data...] - NOT nibble-encoded!
    // Skip first byte (ID), rest is raw patch data
    if (message.payload.length < 1 + programSize) {
      print(
        '  ERROR: Not enough data! Got ${message.payload.length}, need ${1 + programSize}',
      );
      return;
    }

    // Skip first byte (ID), extract raw patch data
    final data = message.payload.sublist(1, 1 + programSize);
    final patch = Patch.fromData(data);

    // CRITICAL: POD XT/XT Pro responds to patch dump requests with edit buffer dumps (03 74)
    // Check if we're waiting for a patch dump response during bulk import
    if (_expectedPatchNumber != null && _patchDumpCompleter != null) {
      // This edit buffer dump is actually a response to our patch dump request
      final patchNum = _expectedPatchNumber!;

      _patchLibrary.patches[patchNum] = patch;
      _patchesSyncedCount = patchNum + 1;

      // Update progress
      _syncProgressController.add(
        SyncProgress(
          _patchesSyncedCount,
          programCount,
          'Patch ${patchNum + 1}/$programCount: ${patch.name}',
        ),
      );

      // Complete completer
      if (!_patchDumpCompleter!.isCompleted) {
        _patchDumpCompleter!.complete();
      }
      _expectedPatchNumber = null;
    } else if (_bulkImportInProgress) {
      // During bulk import, ignore unexpected edit buffer dumps
      // (POD sends Amp Presets and User FX after the 128 user patches)
      return;
    } else {
      // Normal edit buffer update (not during bulk import)
      _editBuffer = EditBuffer.fromPatch(patch, _currentProgram);
      _editBufferController.add(_editBuffer);

      // Suppress modified flag for incoming CC messages for a brief window
      // to avoid false positives from POD auto-adjusting parameters on load
      _suppressModifiedFlag = true;
      Future.delayed(const Duration(milliseconds: 500), () {
        _suppressModifiedFlag = false;
      });
    }
  }

  void _handlePatchDump(SysexMessage message) {
    // POD XT format: [patch_lsb, patch_msb, id, raw_data...] - NOT nibble-encoded!
    // For single patch request: [patch_num (2 bytes), id, data]
    if (message.payload.length < 3 + programSize) {
      print('  Patch dump too short: ${message.payload.length} bytes');
      return;
    }

    // Patch number is 2 bytes (LSB, MSB)
    final patchNum = message.payload[0] | (message.payload[1] << 8);
    final id = message.payload[2];
    final data = message.payload.sublist(3, 3 + programSize);

    print('  Patch $patchNum (id=$id): ${data.length} bytes');

    if (patchNum < programCount) {
      final patch = Patch.fromData(data);
      _patchLibrary.patches[patchNum] = patch;
      _patchesSyncedCount = patchNum + 1;

      // Update progress
      _syncProgressController.add(
        SyncProgress(
          _patchesSyncedCount,
          programCount,
          'Syncing patch ${patchNum + 1}/$programCount: ${patch.name}',
        ),
      );
    }
  }

  void _handlePatchDumpEnd(SysexMessage message) {
    // During bulk import, ignore individual patch dump end markers
    // The bulk import function will handle completion
    if (_bulkImportInProgress) {
      return;
    }

    print('POD: All patches synced! ($_patchesSyncedCount patches)');
    _patchesSynced = true;
    _syncProgressController.add(
      SyncProgress(programCount, programCount, 'Sync complete!'),
    );
  }

  void _handleInstalledPacks(SysexMessage message) {
    if (message.payload.isNotEmpty) {
      _installedPacks = message.payload[0];
    }
  }

  void _handleProgramState(SysexMessage message) {
    // Program number response format: [0x11, p1, p2, p3, p4]
    // Where p1-p4 are 4-bit nibbles that combine to a 16-bit program number
    if (message.payload.length >= 5) {
      // Skip first byte (0x11 subcommand), read 4 nibbles
      final p1 = message.payload[1] & 0x0F;
      final p2 = message.payload[2] & 0x0F;
      final p3 = message.payload[3] & 0x0F;
      final p4 = message.payload[4] & 0x0F;
      final program = (p1 << 12) | (p2 << 8) | (p3 << 4) | p4;
      if (program < programCount) {
        _currentProgram = program;
        _programChangeController.add(program);
      } else {
        print(
          'POD: ERROR - Program $program out of range (max: ${programCount - 1})',
        );
      }
    } else {
      print(
        'POD: ERROR - Program state payload too short (need 5 bytes, got ${message.payload.length})',
      );
    }
  }

  /// Handle store success response (03 50)
  void _handleStoreSuccess(SysexMessage message) {
    // Update patch library with saved patch data
    if (_lastSavedPatchNumber != null && _lastSavedPatchData != null) {
      final patchData = Uint8List.fromList(_lastSavedPatchData!);
      final savedPatch = Patch.fromData(patchData);
      _patchLibrary.patches[_lastSavedPatchNumber!] = savedPatch;

      // If we saved/renamed the currently loaded patch, reload it on hardware
      // to update the POD's display with the new name
      if (_lastSavedPatchNumber == _currentProgram) {
        // Update local edit buffer immediately
        _editBuffer.patch = savedPatch;
        _editBufferController.add(_editBuffer);

        // Tell POD to reload the patch from saved slot to update its display
        // Use program change to force reload
        _midi.sendProgramChange(_currentProgram);

        // Small delay before requesting edit buffer to ensure POD has switched
        Future.delayed(const Duration(milliseconds: 100), () {
          _midi.requestEditBuffer();
        });
      }
    }

    _storeResultController.add(
      StoreResult(success: true, patchNumber: _lastSavedPatchNumber),
    );
    _lastSavedPatchNumber = null;
    _lastSavedPatchData = null;
  }

  /// Handle store failure response (03 51)
  void _handleStoreFailure(SysexMessage message) {
    _storeResultController.add(
      StoreResult(
        success: false,
        patchNumber: _lastSavedPatchNumber,
        error: 'Store operation failed',
      ),
    );
    _lastSavedPatchNumber = null;
    _lastSavedPatchData = null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BULK OPERATIONS - Import/Export
  // ═══════════════════════════════════════════════════════════════════════════

  /// Import all 128 patches from hardware (sequential, not parallel)
  ///
  /// POD XT Pro BULK IMPORT PROTOCOL (from pod-ui reference lines 531-576):
  /// - Uses Patch Dump Request (03 73) - queries patch WITHOUT loading it (silent!)
  /// - POD responds with Edit Buffer Dump (03 74) - NOT Patch Dump (03 71)
  /// - Does NOT change current patch (background operation)
  /// - Must request patches individually 0-127 (no AllProgramsDump)
  ///
  /// NOTE: Program Change is ONLY for loading a patch to edit (audible switch)
  Future<void> importAllPatchesFromHardware() async {
    if (_connectionState != PodConnectionState.connected) {
      throw StateError('Not connected to device');
    }

    // Reset sync state
    _bulkImportInProgress = true;
    _patchesSynced = false;
    _patchesSyncedCount = 0;
    _syncProgressController.add(
      SyncProgress(0, programCount, 'Starting import...'),
    );

    try {
      // Request patches sequentially (0-127)
      for (int i = 0; i < programCount; i++) {
        try {
          // Create completer to wait for response
          _patchDumpCompleter = Completer<void>();
          _expectedPatchNumber = i; // Track which patch we're expecting

          // Send Patch Dump Request (03 73)
          // POD will respond with Edit Buffer Dump (03 74) containing the patch data
          // This does NOT change the current patch (silent background query)
          await _midi.sendSysex(PodXtSysex.requestPatch(i));

          // Wait for response with timeout (edit buffer dump handler will complete the completer)
          try {
            await _patchDumpCompleter!.future.timeout(
              const Duration(milliseconds: 800),
              onTimeout: () {
                throw TimeoutException('Patch $i response timeout');
              },
            );
          } catch (e) {
            _patchDumpCompleter = null;
            _expectedPatchNumber = null;
            // Continue with next patch despite error
            continue;
          }

          _patchDumpCompleter = null;
          _expectedPatchNumber = null;

          // Small delay before next patch request
          await Future.delayed(const Duration(milliseconds: 50));
        } catch (e) {
          _patchDumpCompleter = null;
          _expectedPatchNumber = null;
          // Continue with next patch
        }
      }

      _patchesSynced = true;
      _syncProgressController.add(
        SyncProgress(programCount, programCount, 'Import complete!'),
      );
    } finally {
      // Always reset the flag, even if import was interrupted
      _bulkImportInProgress = false;
    }
  }

  /// Save current edit buffer to a hardware slot
  ///
  /// Sends store command, end marker, then waits for success/failure response
  Future<void> savePatchToHardware(int patchNumber) async {
    if (_connectionState != PodConnectionState.connected) {
      throw StateError('Not connected to device');
    }

    if (patchNumber < 0 || patchNumber >= programCount) {
      throw ArgumentError('Patch number must be 0-${programCount - 1}');
    }

    print('POD: Saving current edit buffer to hardware slot $patchNumber...');

    // Get patch data from current edit buffer
    final patchData = _editBuffer.patch.data;

    // Track which patch we're saving for the result callback
    _lastSavedPatchNumber = patchNumber;
    _lastSavedPatchData = List<int>.from(patchData);

    // Build and send store command
    final storeMsg = PodXtSysex.storePatch(patchNumber, patchData);
    await _midi.sendSysex(storeMsg);

    // Send end marker
    await _midi.sendSysex(PodXtSysex.requestPatchDumpEnd());

    // Wait for success/failure response (handled in _handleSysex)
    // The response will be 03 50 (success) or 03 51 (failure)
    print('POD: Store command sent, waiting for confirmation...');
  }

  /// Export a specific patch to a hardware slot without loading it to edit buffer
  ///
  /// This is different from savePatchToHardware which saves the current edit buffer.
  /// Use this when you want to save a patch from local library directly to hardware.
  Future<void> exportPatchToHardware(Patch patch, int patchNumber) async {
    if (_connectionState != PodConnectionState.connected) {
      throw StateError('Not connected to device');
    }

    if (patchNumber < 0 || patchNumber >= programCount) {
      throw ArgumentError('Patch number must be 0-${programCount - 1}');
    }

    print('POD: Exporting "${patch.name}" to hardware slot $patchNumber...');

    // Use the provided patch data (not edit buffer)
    final patchData = patch.data;

    // Track which patch we're saving for the result callback
    _lastSavedPatchNumber = patchNumber;
    _lastSavedPatchData = List<int>.from(patchData);

    // Build and send store command
    final storeMsg = PodXtSysex.storePatch(patchNumber, patchData);
    await _midi.sendSysex(storeMsg);

    // Send end marker
    await _midi.sendSysex(PodXtSysex.requestPatchDumpEnd());

    // Wait for success/failure response (handled in _handleSysex)
    print('POD: Export command sent, waiting for confirmation...');
  }

  /// Rename an existing patch slot without loading it
  ///
  /// Updates the patch name in the specified slot and saves to hardware
  Future<void> renamePatch(int patchNumber, String newName) async {
    if (_connectionState != PodConnectionState.connected) {
      throw StateError('Not connected to device');
    }

    if (patchNumber < 0 || patchNumber >= programCount) {
      throw ArgumentError('Patch number must be 0-${programCount - 1}');
    }

    print('POD: Renaming patch $patchNumber to "$newName"...');

    // Get existing patch data from library and create a copy
    final existingPatch = _patchLibrary[patchNumber];

    // Create a new patch from the existing data
    final updatedPatch = Patch.fromData(existingPatch.data);

    // Update name (this modifies the underlying data bytes)
    updatedPatch.name = newName;

    // Track which patch we're saving and store the data
    _lastSavedPatchNumber = patchNumber;
    _lastSavedPatchData = List<int>.from(updatedPatch.data);

    // Build and send store command with updated patch
    final storeMsg = PodXtSysex.storePatch(patchNumber, updatedPatch.data);
    await _midi.sendSysex(storeMsg);

    // Send end marker
    await _midi.sendSysex(PodXtSysex.requestPatchDumpEnd());

    print('POD: Rename command sent, waiting for confirmation...');
  }

  /// Dispose resources
  void dispose() {
    _ccSubscription?.cancel();
    _pcSubscription?.cancel();
    _sysexSubscription?.cancel();
    _connectionStateController.close();
    _parameterChangeController.close();
    _programChangeController.close();
    _editBufferController.close();
    _syncProgressController.close();
    _storeResultController.close();
  }
}

/// Parameter change event
class ParameterChange {
  final CCParam param;
  final int value;

  ParameterChange(this.param, this.value);

  @override
  String toString() => 'ParameterChange(${param.name}=$value)';
}

/// Sync progress event
class SyncProgress {
  final int current;
  final int total;
  final String message;

  SyncProgress(this.current, this.total, this.message);

  double get progress => total > 0 ? current / total : 0;
  bool get isComplete => current >= total;

  @override
  String toString() => 'SyncProgress($current/$total: $message)';
}

/// Store operation result
class StoreResult {
  final bool success;
  final int? patchNumber;
  final String? error;

  StoreResult({required this.success, this.patchNumber, this.error});

  @override
  String toString() =>
      success ? 'StoreResult(success, patch=$patchNumber)' : 'StoreResult(failed: $error)';
}
