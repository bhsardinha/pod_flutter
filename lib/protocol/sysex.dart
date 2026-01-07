/// Sysex protocol implementation for POD XT Pro
/// Based on pod-ui core/src/midi.rs

library;

import 'dart:typed_data';
import 'constants.dart';

/// Sysex message builder and parser for Line6 POD XT Pro
class PodXtSysex {
  /// Build a complete sysex message
  static Uint8List buildMessage(List<int> command, [List<int>? data]) {
    final buffer = <int>[
      0xF0, // Sysex start
      ...line6ManufacturerId,
      ...command,
      if (data != null) ...data,
      0xF7, // Sysex end
    ];
    return Uint8List.fromList(buffer);
  }

  /// Request edit buffer dump
  static Uint8List requestEditBuffer() {
    return buildMessage(SysexCommand.editBufferDumpRequest);
  }

  /// Request a specific patch dump
  static Uint8List requestPatch(int patchNumber) {
    // Patch number is sent as 2 bytes (bank, program)
    final bank = patchNumber ~/ 128;
    final program = patchNumber % 128;
    return buildMessage(SysexCommand.patchDumpRequest, [bank, program]);
  }

  /// Request all patches dump
  static Uint8List requestAllPatches() {
    return buildMessage([0x01, 0x00, 0x02]);
  }

  /// Request installed expansion packs
  static Uint8List requestInstalledPacks() {
    return buildMessage(SysexCommand.installedPacks);
  }

  /// Request current program number from POD
  static Uint8List requestProgramState() {
    // Request format: [0x03, 0x57, 0x11] - the 0x11 is the program number subcommand
    return buildMessage(SysexCommand.programNumberRequest, [SysexCommand.programNumberSubcmd]);
  }

  /// Parse incoming sysex message
  static SysexMessage? parse(Uint8List data) {
    if (data.length < 6) return null;
    if (data[0] != 0xF0) return null;
    if (data[data.length - 1] != 0xF7) return null;

    // Check Line6 manufacturer ID
    if (data[1] != 0x00 || data[2] != 0x01 || data[3] != 0x0C) {
      return null;
    }

    // Extract command and payload
    final command = data.sublist(4, 6);
    final payload = data.sublist(6, data.length - 1);

    return SysexMessage(command: command, payload: payload);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DATA ENCODING/DECODING (Nibble encoding)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Encode bytes to nibbles for sysex transmission
  /// Each byte becomes 2 nibbles (4-bit values)
  static Uint8List encodeNibbles(Uint8List data) {
    final result = Uint8List(data.length * 2);
    for (int i = 0; i < data.length; i++) {
      result[i * 2] = (data[i] >> 4) & 0x0F;
      result[i * 2 + 1] = data[i] & 0x0F;
    }
    return result;
  }

  /// Decode nibbles back to bytes
  static Uint8List decodeNibbles(Uint8List nibbles) {
    final result = Uint8List(nibbles.length ~/ 2);
    for (int i = 0; i < result.length; i++) {
      result[i] = ((nibbles[i * 2] & 0x0F) << 4) | (nibbles[i * 2 + 1] & 0x0F);
    }
    return result;
  }

  /// Encode 16-bit value as two 7-bit values
  static List<int> encode16To7Bit(int value) {
    return [(value >> 7) & 0x7F, value & 0x7F];
  }

  /// Decode two 7-bit values to 16-bit
  static int decode7BitTo16(int msb, int lsb) {
    return ((msb & 0x7F) << 7) | (lsb & 0x7F);
  }

  /// Encode 16-bit value as four 4-bit nibbles
  static List<int> encode16To4Bit(int value) {
    return [
      (value >> 12) & 0x0F,
      (value >> 8) & 0x0F,
      (value >> 4) & 0x0F,
      value & 0x0F,
    ];
  }

  /// Decode four 4-bit nibbles to 16-bit
  static int decode4BitTo16(List<int> nibbles) {
    return ((nibbles[0] & 0x0F) << 12) |
        ((nibbles[1] & 0x0F) << 8) |
        ((nibbles[2] & 0x0F) << 4) |
        (nibbles[3] & 0x0F);
  }
}

/// Parsed sysex message
class SysexMessage {
  final List<int> command;
  final Uint8List payload;

  SysexMessage({required this.command, required this.payload});

  /// Check if this is a specific command type
  bool isCommand(List<int> cmd) {
    if (command.length != cmd.length) return false;
    for (int i = 0; i < command.length; i++) {
      if (command[i] != cmd[i]) return false;
    }
    return true;
  }

  /// Message type identification
  bool get isEditBufferDump => isCommand(SysexCommand.bufferDumpResponse);
  bool get isPatchDump => isCommand(SysexCommand.patchDumpResponse);
  bool get isPatchDumpEnd => isCommand(SysexCommand.patchDumpEnd);
  bool get isInstalledPacks => isCommand(SysexCommand.installedPacks);
  bool get isStoreSuccess => isCommand(SysexCommand.storeSuccess);
  bool get isStoreFailure => isCommand(SysexCommand.storeFailure);
  // Tuner data is 0x03, 0x56 WITHOUT 0x11 subcommand prefix
  bool get isTunerData =>
      isCommand(SysexCommand.tunerData) &&
      (payload.isEmpty || payload[0] != SysexCommand.programNumberSubcmd);
  // Program number is 0x03, 0x56 WITH 0x11 subcommand prefix
  bool get isProgramState =>
      isCommand(SysexCommand.programNumberResponse) &&
      payload.isNotEmpty &&
      payload[0] == SysexCommand.programNumberSubcmd;

  @override
  String toString() {
    final cmdHex = command.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
    return 'SysexMessage(cmd: $cmdHex, payload: ${payload.length} bytes)';
  }
}

/// Sysex message types for event handling
enum SysexMessageType {
  editBufferDump,
  patchDump,
  patchDumpEnd,
  allPatchesDump,
  installedPacks,
  storeSuccess,
  storeFailure,
  tunerData,
  programState,
  savedPatchNotification,
  unknown,
}
