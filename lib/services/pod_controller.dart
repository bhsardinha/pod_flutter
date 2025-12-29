/// POD XT Pro Controller Service
/// High-level interface for controlling the POD

library;

import 'dart:async';
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

  // Subscriptions
  StreamSubscription? _ccSubscription;
  StreamSubscription? _pcSubscription;
  StreamSubscription? _sysexSubscription;

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

  MicModel? get micModel => MicModels.byId(getParameter(PodXtCC.micSelect));
  Future<void> setMicModel(int id) => setParameter(PodXtCC.micSelect, id);

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
  Future<void> setTempo(int bpm) =>
      setParameter16(PodXtCC.tempoMsb, PodXtCC.tempoLsb, bpm);

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

  /// Refresh edit buffer from device
  Future<void> refreshEditBuffer() async {
    await _midi.requestEditBuffer();
  }

  /// Refresh all patches from device
  Future<void> refreshAllPatches() async {
    await _midi.requestAllPatches();
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

    print('POD: Requesting initial state...');

    // Reset sync state
    _patchesSynced = false;
    _patchesSyncedCount = 0;

    // Request expansion packs info
    await _midi.requestInstalledPacks();
    await Future.delayed(const Duration(milliseconds: 100));

    // Request current program state (to get correct program number)
    print('POD: Requesting program state...');
    await _midi.requestProgramState();
    await Future.delayed(const Duration(milliseconds: 100));

    // Request current edit buffer
    print('POD: Requesting edit buffer...');
    await _midi.requestEditBuffer();

    // TODO: Implement individual patch requests if bulk request doesn't work
    // For now, mark as synced since we have the edit buffer
    _patchesSynced = true;
    _syncProgressController.add(
      SyncProgress(programCount, programCount, 'Ready'),
    );
  }

  void _handleControlChange(({int cc, int value}) change) {
    final param = PodXtCC.byCC[change.cc];
    if (param != null && param.address != null) {
      _editBuffer.patch.setValueAt(param.address!, change.value);
      _editBuffer.markModified();
      _parameterChangeController.add(ParameterChange(param, change.value));
      _editBufferController.add(_editBuffer);
    }
  }

  void _handleProgramChange(int program) {
    _currentProgram = program;
    _programChangeController.add(program);
    // Request the edit buffer for the new program
    _midi.requestEditBuffer();
  }

  void _handleSysex(SysexMessage message) {
    // Debug: print received sysex
    print('POD Sysex received: $message');

    if (message.isEditBufferDump) {
      print('  -> Edit buffer dump!');
      _handleEditBufferDump(message);
    } else if (message.isPatchDump) {
      print('  -> Patch dump');
      _handlePatchDump(message);
    } else if (message.isPatchDumpEnd) {
      print('  -> Patch dump end');
      _handlePatchDumpEnd(message);
    } else if (message.isInstalledPacks) {
      print('  -> Installed packs');
      _handleInstalledPacks(message);
    } else if (message.isProgramState) {
      print('  -> Program state');
      _handleProgramState(message);
    }
  }

  void _handleEditBufferDump(SysexMessage message) {
    print('  Edit buffer payload: ${message.payload.length} bytes');

    // POD XT format: [id, raw_data...] - NOT nibble-encoded!
    // Skip first byte (ID), rest is raw patch data
    if (message.payload.length < 1 + programSize) {
      print(
        '  ERROR: Not enough data! Got ${message.payload.length}, need ${1 + programSize}',
      );
      return;
    }

    final id = message.payload[0];
    final data = message.payload.sublist(1, 1 + programSize);
    print('  ID: $id, Data: ${data.length} bytes');

    final patch = Patch.fromData(data);
    print('  Patch name: "${patch.name}"');
    print('  Drive: ${patch.getValue(PodXtCC.drive)}');

    _editBuffer = EditBuffer.fromPatch(patch, _currentProgram);
    _editBufferController.add(_editBuffer);
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

      print('    Name: "${patch.name}"');
    }
  }

  void _handlePatchDumpEnd(SysexMessage message) {
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
    // Program state format: [program_lsb, program_msb, ...]
    if (message.payload.length >= 2) {
      final program = message.payload[0] | (message.payload[1] << 8);
      print('  Current program: $program');
      if (program < programCount) {
        _currentProgram = program;
        _programChangeController.add(program);
      }
    }
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
