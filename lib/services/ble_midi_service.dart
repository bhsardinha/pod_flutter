/// MIDI Service implementation using flutter_midi_command
/// Supports both USB MIDI and Bluetooth (BLE) MIDI connections

library;

import 'dart:async';
import 'dart:io' show Platform;
import 'dart:typed_data';
import 'package:flutter_midi_command/flutter_midi_command.dart';
import '../protocol/sysex.dart';
import '../protocol/cc_map.dart';
import 'midi_service.dart';

/// MIDI service implementation supporting both USB and BLE MIDI
class BleMidiService implements MidiService {
  final MidiCommand _midiCommand = MidiCommand();

  MidiDevice? _connectedDevice;
  StreamSubscription? _dataSubscription;
  StreamSubscription? _setupSubscription;
  StreamSubscription? _deviceMonitorSubscription;
  bool _manualDisconnect = false;

  // Stream controllers
  final _messageController = StreamController<MidiMessage>.broadcast();
  final _ccController = StreamController<({int cc, int value})>.broadcast();
  final _pcController = StreamController<int>.broadcast();
  final _sysexController = StreamController<SysexMessage>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();
  final _devicesController = StreamController<List<MidiDeviceInfo>>.broadcast();

  // Sysex buffer for multi-packet messages
  List<int>? _sysexBuffer;

  /// Constructor - starts monitoring for device changes immediately
  BleMidiService() {
    _startDeviceMonitoring();
  }

  /// Start listening for MIDI setup changes (device connect/disconnect)
  void _startDeviceMonitoring() {
    _deviceMonitorSubscription = _midiCommand.onMidiSetupChanged?.listen(
      (data) async {
        // MIDI setup changed - refresh device list and notify listeners
        final devices = await _getDevices();
        final deviceInfos = devices
            .map(
              (d) => MidiDeviceInfo(
                id: d.id,
                name: d.name,
                isBleMidi: d.type == 'BLE',
              ),
            )
            .toList();
        _devicesController.add(deviceInfos);
      },
    );
  }

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

  @override
  Stream<List<MidiDeviceInfo>> get onDevicesChanged => _devicesController.stream;

  Future<List<MidiDevice>> _getDevices() async {
    final devices = await _midiCommand.devices;
    return devices ?? <MidiDevice>[];
  }

  @override
  Future<List<MidiDeviceInfo>> scanDevices() async {
    // USB MIDI devices are detected automatically via CoreMIDI (macOS/iOS)
    // or android.media.midi (Android) and the onMidiSetupChanged stream.
    // This method just returns the current device list.
    //
    // Note: BLE scanning is skipped due to bluetoothNotAvailable errors.
    // BLE devices will still be detected if Bluetooth is available via
    // the onMidiSetupChanged stream when they connect.

    // Get current device list
    final devices = await _getDevices();

    // Return all found devices
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

    // If device is already connected (stale connection), disconnect first
    if (midiDevice.connected) {
      try {
        _manualDisconnect = true;
        _midiCommand.disconnectDevice(midiDevice);
        // Wait a bit for disconnect to complete
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        // Ignore disconnect errors, we'll try to connect anyway
      }
    }

    // Disconnect any existing connection we're tracking
    if (_connectedDevice != null) {
      await disconnect();
      // Wait a bit to ensure clean state
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // Reset flag before new connection
    _manualDisconnect = false;

    try {
      // Connect
      _midiCommand.connectToDevice(midiDevice);

      // Wait for connection and monitor for disconnection
      final completer = Completer<void>();

      _setupSubscription = _midiCommand.onMidiSetupChanged?.listen((data) async {
        final devices = await _getDevices();

        final deviceStatus = devices.cast<MidiDevice?>().firstWhere(
          (d) => d?.id == device.id,
          orElse: () => null,
        );

        if (deviceStatus != null) {
          if (deviceStatus.connected && !completer.isCompleted) {
            // Device just connected
            _connectedDevice = midiDevice;
            _startListening();
            _connectionController.add(true);
            completer.complete();
          }
        } else {
          // Device disconnected (physically unplugged or powered off)
          if (_connectedDevice != null && _connectedDevice!.id == device.id) {
            _handleUnexpectedDisconnection();
          }
        }
      });

      // Windows workaround: onMidiSetupChanged may not fire for USB MIDI
      // Poll device status instead
      if (Platform.isWindows && !device.isBleMidi) {
        Timer.periodic(const Duration(milliseconds: 200), (timer) async {
          if (completer.isCompleted) {
            timer.cancel();
            return;
          }

          final devices = await _getDevices();
          final deviceStatus = devices.cast<MidiDevice?>().firstWhere(
            (d) => d?.id == device.id,
            orElse: () => null,
          );

          if (deviceStatus != null && deviceStatus.connected) {
            timer.cancel();
            _connectedDevice = midiDevice;
            _startListening();
            _connectionController.add(true);
            if (!completer.isCompleted) {
              completer.complete();
            }
          }
        });
      }

      // Timeout after 10 seconds
      return await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          _setupSubscription?.cancel();
          throw Exception('Connection timeout - no setup changed event received');
        },
      );
    } catch (e) {
      // If "already connected" error, force disconnect and retry once
      if (e.toString().contains('already connected')) {
        try {
          _manualDisconnect = true;
          _midiCommand.disconnectDevice(midiDevice);
          await Future.delayed(const Duration(milliseconds: 500));
          _manualDisconnect = false;

          // Retry connection
          _midiCommand.connectToDevice(midiDevice);

          final completer = Completer<void>();

          _setupSubscription = _midiCommand.onMidiSetupChanged?.listen((data) async {
            final devices = await _getDevices();
            final deviceStatus = devices.cast<MidiDevice?>().firstWhere(
              (d) => d?.id == device.id,
              orElse: () => null,
            );

            if (deviceStatus != null && deviceStatus.connected && !completer.isCompleted) {
              // Device just connected
              _connectedDevice = midiDevice;
              _startListening();
              _connectionController.add(true);
              completer.complete();
            } else if (deviceStatus == null || !deviceStatus.connected) {
              // Device disconnected (physically unplugged or powered off)
              if (_connectedDevice != null && _connectedDevice!.id == device.id) {
                _handleUnexpectedDisconnection();
              }
            }
          });

          return await completer.future.timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              _setupSubscription?.cancel();
              throw Exception('Connection timeout on retry');
            },
          );
        } catch (retryError) {
          throw Exception('Failed to reconnect: $retryError');
        }
      }
      rethrow;
    }
  }

  void _startListening() {
    _dataSubscription = _midiCommand.onMidiDataReceived?.listen(
      _handleMidiData,
    );
  }

  void _handleUnexpectedDisconnection() {
    // Ignore if this was a manual disconnect
    if (_manualDisconnect) {
      _manualDisconnect = false;
      return;
    }

    // Clean up state
    _connectedDevice = null;
    _dataSubscription?.cancel();
    _dataSubscription = null;
    _sysexBuffer = null;

    // Notify listeners
    _connectionController.add(false);
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
    // Mark as manual disconnect to prevent unexpected disconnection handler
    _manualDisconnect = true;

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
    _deviceMonitorSubscription?.cancel();
    _messageController.close();
    _ccController.close();
    _pcController.close();
    _sysexController.close();
    _connectionController.close();
    _devicesController.close();
  }
}
