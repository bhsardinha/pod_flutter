/// BLE MIDI Service implementation using flutter_midi_command
/// Concrete implementation of MidiService for Bluetooth MIDI

library;

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_midi_command/flutter_midi_command.dart';
import '../protocol/sysex.dart';
import '../protocol/cc_map.dart';
import 'midi_service.dart';

/// BLE MIDI implementation of MidiService
class BleMidiService implements MidiService {
  final MidiCommand _midiCommand = MidiCommand();

  MidiDevice? _connectedDevice;
  StreamSubscription? _dataSubscription;
  StreamSubscription? _setupSubscription;

  // Stream controllers
  final _messageController = StreamController<MidiMessage>.broadcast();
  final _ccController = StreamController<({int cc, int value})>.broadcast();
  final _pcController = StreamController<int>.broadcast();
  final _sysexController = StreamController<SysexMessage>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  // Sysex buffer for multi-packet messages
  List<int>? _sysexBuffer;

  @override
  Stream<MidiMessage> get onMessage => _messageController.stream;

  @override
  Stream<({int cc, int value})> get onControlChange => _ccController.stream;

  @override
  Stream<int> get onProgramChange => _pcController.stream;

  @override
  Stream<SysexMessage> get onSysex => _sysexController.stream;

  @override
  bool get isConnected => _connectedDevice?.connected ?? false;

  @override
  Stream<bool> get onConnectionChanged => _connectionController.stream;

  Future<List<MidiDevice>> _getDevices() async {
    final devices = await _midiCommand.devices;
    return devices ?? <MidiDevice>[];
  }

  @override
  Future<List<MidiDeviceInfo>> scanDevices() async {
    // Start scanning for BLE devices
    _midiCommand.startScanningForBluetoothDevices();

    // Wait a bit for devices to be discovered
    await Future.delayed(const Duration(seconds: 2));

    // Get all devices (both connected and discovered)
    final devices = await _getDevices();

    // Stop scanning
    _midiCommand.stopScanningForBluetoothDevices();

    return devices
        .map(
          (d) => MidiDeviceInfo(
            id: d.id,
            name: d.name,
            isBleMidi: d.type == 'BLE',
          ),
        )
        .toList();
  }

  @override
  Future<void> connect(MidiDeviceInfo device) async {
    // Find the actual device
    final devices = await _getDevices();
    final midiDevice = devices.cast<MidiDevice?>().firstWhere(
      (d) => d?.id == device.id,
      orElse: () => null,
    );

    if (midiDevice == null) {
      throw Exception('Device not found: ${device.name}');
    }

    // Connect
    _midiCommand.connectToDevice(midiDevice);

    // Wait for connection
    final completer = Completer<void>();

    _setupSubscription = _midiCommand.onMidiSetupChanged?.listen((data) async {
      final devices = await _getDevices();
      final connected = devices.any((d) => d.id == device.id && d.connected);
      if (connected && !completer.isCompleted) {
        _connectedDevice = midiDevice;
        _startListening();
        _connectionController.add(true);
        completer.complete();
      }
    });

    // Timeout after 10 seconds
    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        _setupSubscription?.cancel();
        throw Exception('Connection timeout');
      },
    );
  }

  void _startListening() {
    _dataSubscription = _midiCommand.onMidiDataReceived?.listen(
      _handleMidiData,
    );
  }

  void _handleMidiData(MidiPacket packet) {
    final data = Uint8List.fromList(packet.data);
    if (data.isEmpty) return;

    // Handle sysex (may span multiple packets)
    if (data[0] == 0xF0 || _sysexBuffer != null) {
      _handleSysexData(data);
      return;
    }

    // Parse regular MIDI message
    final message = MidiParser.parse(data);
    if (message == null) return;

    _messageController.add(message);

    switch (message.type) {
      case MidiMessageType.controlChange:
        _ccController.add((cc: message.cc!, value: message.ccValue!));
      case MidiMessageType.programChange:
        _pcController.add(message.program!);
      default:
        break;
    }
  }

  void _handleSysexData(Uint8List data) {
    // Start of sysex
    if (data[0] == 0xF0) {
      _sysexBuffer = List.from(data);
    } else if (_sysexBuffer != null) {
      // Continuation
      _sysexBuffer!.addAll(data);
    }

    // Check for end of sysex
    if (_sysexBuffer != null && _sysexBuffer!.last == 0xF7) {
      final sysexData = Uint8List.fromList(_sysexBuffer!);
      _sysexBuffer = null;

      // Parse and emit
      final sysexMessage = PodXtSysex.parse(sysexData);
      if (sysexMessage != null) {
        _sysexController.add(sysexMessage);
      }

      // Also emit as regular message
      _messageController.add(
        MidiMessage(type: MidiMessageType.sysex, channel: 0, data: sysexData),
      );
    }
  }

  @override
  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      _midiCommand.disconnectDevice(_connectedDevice!);
      _connectedDevice = null;
    }
    _dataSubscription?.cancel();
    _dataSubscription = null;
    _setupSubscription?.cancel();
    _setupSubscription = null;
    _sysexBuffer = null;
    _connectionController.add(false);
  }

  @override
  Future<void> sendCC(int cc, int value, {int channel = 0}) async {
    final data = MidiParser.buildCC(cc, value, channel: channel);
    await _send(data);
  }

  @override
  Future<void> sendProgramChange(int program, {int channel = 0}) async {
    final data = MidiParser.buildPC(program, channel: channel);
    await _send(data);
  }

  @override
  Future<void> sendSysex(Uint8List data) async {
    await _send(data);
  }

  @override
  Future<void> sendParam(CCParam param, int value, {int channel = 0}) {
    return sendCC(param.cc, value, channel: channel);
  }

  @override
  Future<void> requestEditBuffer() {
    return sendSysex(PodXtSysex.requestEditBuffer());
  }

  @override
  Future<void> requestPatch(int patchNumber) {
    return sendSysex(PodXtSysex.requestPatch(patchNumber));
  }

  @override
  Future<void> requestAllPatches() {
    return sendSysex(PodXtSysex.requestAllPatches());
  }

  @override
  Future<void> requestInstalledPacks() {
    return sendSysex(PodXtSysex.requestInstalledPacks());
  }

  @override
  Future<void> requestProgramState() {
    return sendSysex(PodXtSysex.requestProgramState());
  }

  Future<void> _send(Uint8List data) async {
    if (_connectedDevice == null) {
      throw Exception('Not connected to any device');
    }
    _midiCommand.sendData(data, deviceId: _connectedDevice!.id);
  }

  @override
  void dispose() {
    disconnect();
    _messageController.close();
    _ccController.close();
    _pcController.close();
    _sysexController.close();
    _connectionController.close();
  }
}
