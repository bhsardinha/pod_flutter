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
enum PodConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
  error,
}

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

  // Stream controllers
  final _connectionStateController = StreamController<PodConnectionState>.broadcast();
  final _parameterChangeController = StreamController<ParameterChange>.broadcast();
  final _programChangeController = StreamController<int>.broadcast();
  final _editBufferController = StreamController<EditBuffer>.broadcast();

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
  Stream<PodConnectionState> get onConnectionStateChanged => _connectionStateController.stream;

  EditBuffer get editBuffer => _editBuffer;
  Stream<EditBuffer> get onEditBufferChanged => _editBufferController.stream;

  PatchLibrary get patchLibrary => _patchLibrary;

  int get currentProgram => _currentProgram;
  Stream<int> get onProgramChanged => _programChangeController.stream;

  Stream<ParameterChange> get onParameterChanged => _parameterChangeController.stream;

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

    // Send to device
    await _midi.sendParam(param, clampedValue);

    // Notify listeners
    _parameterChangeController.add(ParameterChange(param, clampedValue));
    _editBufferController.add(_editBuffer);
  }

  /// Set 16-bit parameter value
  Future<void> setParameter16(CCParam msbParam, CCParam lsbParam, int value) async {
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
  Future<void> setChannelVolume(int value) => setParameter(PodXtCC.chanVolume, value);

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

  EffectModel? get stompModel => StompModels.byId(getParameter(PodXtCC.stompSelect));
  Future<void> setStompModel(int id) => setParameter(PodXtCC.stompSelect, id);

  // Modulation
  bool get modEnabled => getSwitch(PodXtCC.modEnable);
  Future<void> setModEnabled(bool v) => setSwitch(PodXtCC.modEnable, v);

  EffectModel? get modModel => ModModels.byId(getParameter(PodXtCC.modSelect));
  Future<void> setModModel(int id) => setParameter(PodXtCC.modSelect, id);

  int get modSpeed => getParameter16(PodXtCC.modSpeedMsb, PodXtCC.modSpeedLsb);
  Future<void> setModSpeed(int value) => setParameter16(PodXtCC.modSpeedMsb, PodXtCC.modSpeedLsb, value);

  int get modMix => getParameter(PodXtCC.modMix);
  Future<void> setModMix(int value) => setParameter(PodXtCC.modMix, value);

  // Delay
  bool get delayEnabled => getSwitch(PodXtCC.delayEnable);
  Future<void> setDelayEnabled(bool v) => setSwitch(PodXtCC.delayEnable, v);

  EffectModel? get delayModel => DelayModels.byId(getParameter(PodXtCC.delaySelect));
  Future<void> setDelayModel(int id) => setParameter(PodXtCC.delaySelect, id);

  int get delayTime => getParameter16(PodXtCC.delayTimeMsb, PodXtCC.delayTimeLsb);
  Future<void> setDelayTime(int value) => setParameter16(PodXtCC.delayTimeMsb, PodXtCC.delayTimeLsb, value);

  int get delayMix => getParameter(PodXtCC.delayMix);
  Future<void> setDelayMix(int value) => setParameter(PodXtCC.delayMix, value);

  // Reverb
  bool get reverbEnabled => getSwitch(PodXtCC.reverbEnable);
  Future<void> setReverbEnabled(bool v) => setSwitch(PodXtCC.reverbEnable, v);

  EffectModel? get reverbModel => ReverbModels.byId(getParameter(PodXtCC.reverbSelect));
  Future<void> setReverbModel(int id) => setParameter(PodXtCC.reverbSelect, id);

  int get reverbDecay => getParameter(PodXtCC.reverbDecay);
  Future<void> setReverbDecay(int value) => setParameter(PodXtCC.reverbDecay, value);

  int get reverbLevel => getParameter(PodXtCC.reverbLevel);
  Future<void> setReverbLevel(int value) => setParameter(PodXtCC.reverbLevel, value);

  // Noise Gate
  bool get noiseGateEnabled => getSwitch(PodXtCC.noiseGateEnable);
  Future<void> setNoiseGateEnabled(bool v) => setSwitch(PodXtCC.noiseGateEnable, v);

  int get gateThreshold => getParameter(PodXtCC.gateThreshold);
  Future<void> setGateThreshold(int value) => setParameter(PodXtCC.gateThreshold, value);

  // Compressor
  bool get compressorEnabled => getSwitch(PodXtCC.compressorEnable);
  Future<void> setCompressorEnabled(bool v) => setSwitch(PodXtCC.compressorEnable, v);

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
  Future<void> setTempo(int bpm) => setParameter16(PodXtCC.tempoMsb, PodXtCC.tempoLsb, bpm);

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
    // Request expansion packs info
    await _midi.requestInstalledPacks();
    // Request current edit buffer
    await _midi.requestEditBuffer();
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
    if (message.isEditBufferDump) {
      _handleEditBufferDump(message);
    } else if (message.isPatchDump) {
      _handlePatchDump(message);
    } else if (message.isInstalledPacks) {
      _handleInstalledPacks(message);
    }
  }

  void _handleEditBufferDump(SysexMessage message) {
    final decoded = PodXtSysex.decodeNibbles(message.payload);
    if (decoded.length >= programSize) {
      _editBuffer = EditBuffer.fromPatch(
        Patch.fromData(decoded.sublist(0, programSize)),
        _currentProgram,
      );
      _editBufferController.add(_editBuffer);
    }
  }

  void _handlePatchDump(SysexMessage message) {
    // Extract patch number and data from payload
    if (message.payload.length < 2) return;
    final patchNum = message.payload[0];
    final data = PodXtSysex.decodeNibbles(message.payload.sublist(1));
    if (patchNum < programCount && data.length >= programSize) {
      _patchLibrary.patches[patchNum] = Patch.fromData(data.sublist(0, programSize));
    }
  }

  void _handleInstalledPacks(SysexMessage message) {
    if (message.payload.isNotEmpty) {
      _installedPacks = message.payload[0];
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
