/// MIDI Service for POD XT Pro communication
/// Handles BLE-MIDI connection and message routing

library;

import 'dart:async';
import 'dart:typed_data';
import '../protocol/cc_map.dart';
import '../protocol/sysex.dart';

/// MIDI message types
enum MidiMessageType {
  controlChange,
  programChange,
  sysex,
  unknown,
}

/// Parsed MIDI message
class MidiMessage {
  final MidiMessageType type;
  final int channel;
  final Uint8List data;

  MidiMessage({
    required this.type,
    required this.channel,
    required this.data,
  });

  /// Control Change specific
  int? get cc => type == MidiMessageType.controlChange ? data[1] : null;
  int? get ccValue => type == MidiMessageType.controlChange ? data[2] : null;

  /// Program Change specific
  int? get program => type == MidiMessageType.programChange ? data[1] : null;

  @override
  String toString() {
    switch (type) {
      case MidiMessageType.controlChange:
        return 'CC($cc=$ccValue, ch=$channel)';
      case MidiMessageType.programChange:
        return 'PC($program, ch=$channel)';
      case MidiMessageType.sysex:
        return 'Sysex(${data.length} bytes)';
      case MidiMessageType.unknown:
        return 'Unknown(${data.length} bytes)';
    }
  }
}

/// Abstract MIDI port interface
abstract class MidiPort {
  String get name;
  bool get isConnected;

  Future<void> connect();
  Future<void> disconnect();
}

/// Abstract MIDI input interface
abstract class MidiInput extends MidiPort {
  Stream<Uint8List> get dataStream;
}

/// Abstract MIDI output interface
abstract class MidiOutput extends MidiPort {
  Future<void> send(Uint8List data);
}

/// MIDI Service for POD XT Pro
///
/// Handles:
/// - Device discovery and connection (BLE-MIDI)
/// - Sending/receiving MIDI messages
/// - Control Change routing
/// - Sysex message handling
/// - Program changes
abstract class MidiService {
  /// Stream of incoming MIDI messages
  Stream<MidiMessage> get onMessage;

  /// Stream of incoming Control Changes
  Stream<({int cc, int value})> get onControlChange;

  /// Stream of incoming Program Changes
  Stream<int> get onProgramChange;

  /// Stream of incoming Sysex messages
  Stream<SysexMessage> get onSysex;

  /// Connection state
  bool get isConnected;
  Stream<bool> get onConnectionChanged;

  /// Stream of device list changes (fires when devices are connected/disconnected)
  Stream<List<MidiDeviceInfo>> get onDevicesChanged;

  /// Available devices
  Future<List<MidiDeviceInfo>> scanDevices();

  /// Connect to a device
  Future<void> connect(MidiDeviceInfo device);

  /// Disconnect
  Future<void> disconnect();

  /// Send Control Change
  Future<void> sendCC(int cc, int value, {int channel = 0});

  /// Send Control Change using parameter definition
  Future<void> sendParam(CCParam param, int value, {int channel = 0}) {
    return sendCC(param.cc, value, channel: channel);
  }

  /// Send Program Change
  Future<void> sendProgramChange(int program, {int channel = 0});

  /// Send raw sysex
  Future<void> sendSysex(Uint8List data);

  /// Request edit buffer dump
  Future<void> requestEditBuffer() {
    return sendSysex(PodXtSysex.requestEditBuffer());
  }

  /// Request specific patch
  Future<void> requestPatch(int patchNumber) {
    return sendSysex(PodXtSysex.requestPatch(patchNumber));
  }

  /// Request all patches
  Future<void> requestAllPatches() {
    return sendSysex(PodXtSysex.requestAllPatches());
  }

  /// Request installed expansion packs
  Future<void> requestInstalledPacks() {
    return sendSysex(PodXtSysex.requestInstalledPacks());
  }

  /// Request current program state
  Future<void> requestProgramState() {
    return sendSysex(PodXtSysex.requestProgramState());
  }

  /// Dispose resources
  void dispose();
}

/// MIDI device information
class MidiDeviceInfo {
  final String id;
  final String name;
  final bool isBleMidi;

  MidiDeviceInfo({
    required this.id,
    required this.name,
    this.isBleMidi = false,
  });

  @override
  String toString() => 'MidiDevice($name, ble: $isBleMidi)';
}

/// MIDI message parser utility
class MidiParser {
  /// Parse raw MIDI bytes into a message
  static MidiMessage? parse(Uint8List data) {
    if (data.isEmpty) return null;

    final status = data[0];

    // Sysex
    if (status == 0xF0) {
      return MidiMessage(
        type: MidiMessageType.sysex,
        channel: 0,
        data: data,
      );
    }

    // Channel messages
    final type = status & 0xF0;
    final channel = status & 0x0F;

    switch (type) {
      case 0xB0: // Control Change
        if (data.length >= 3) {
          return MidiMessage(
            type: MidiMessageType.controlChange,
            channel: channel,
            data: data,
          );
        }
      case 0xC0: // Program Change
        if (data.length >= 2) {
          return MidiMessage(
            type: MidiMessageType.programChange,
            channel: channel,
            data: data,
          );
        }
    }

    return MidiMessage(
      type: MidiMessageType.unknown,
      channel: 0,
      data: data,
    );
  }

  /// Build Control Change message
  static Uint8List buildCC(int cc, int value, {int channel = 0}) {
    return Uint8List.fromList([
      0xB0 | (channel & 0x0F),
      cc & 0x7F,
      value & 0x7F,
    ]);
  }

  /// Build Program Change message
  static Uint8List buildPC(int program, {int channel = 0}) {
    return Uint8List.fromList([
      0xC0 | (channel & 0x0F),
      program & 0x7F,
    ]);
  }
}
