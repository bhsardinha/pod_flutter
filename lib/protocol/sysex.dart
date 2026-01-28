/// Sysex protocol implementation for POD XT Pro
/// Based on pod-ui core/src/midi.rs

library;

import 'dart:typed_data';
import 'dart:math' as math;
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
  ///
  /// Format: F0 00 01 0C 03 73 P1 P2 00 00 F7
  ///
  /// POD XT Pro uses NON-CONTIGUOUS patch mapping (from pod-ui core/src/midi.rs):
  /// - Patches 0-63: MIDI patch 0-63
  /// - Patches 64-127: MIDI patch 192-255 (NOT 64-127!)
  ///
  /// After MIDI patch conversion, encode as 14-bit value split into two 7-bit bytes:
  /// - P1 = upper 7 bits (midi_patch >> 7)
  /// - P2 = lower 7 bits (midi_patch & 0x7F)
  static Uint8List requestPatch(int patchNumber) {
    assert(patchNumber >= 0 && patchNumber < programCount);

    // POD XT Pro patch mapping (pod-ui: core/src/midi.rs PodXtPatch::to_midi)
    int midiPatch;
    if (patchNumber >= 0 && patchNumber <= 63) {
      midiPatch = patchNumber;        // 0-63 -> MIDI 0-63
    } else if (patchNumber >= 64 && patchNumber <= 127) {
      midiPatch = patchNumber + 128;  // 64-127 -> MIDI 192-255
    } else {
      throw ArgumentError('Patch number must be 0-127, got $patchNumber');
    }

    // Encode MIDI patch as two 7-bit bytes (pod-ui: core/src/util.rs u16_to_2_u7)
    final p1 = (midiPatch >> 7) & 0x7F;  // Upper 7 bits
    final p2 = midiPatch & 0x7F;         // Lower 7 bits

    return buildMessage(
      SysexCommand.patchDumpRequest,
      [p1, p2, 0x00, 0x00],
    );
  }

  /// Request patch dump end marker
  ///
  /// Must be sent after receiving a patch dump response
  /// Format: F0 00 01 0C 03 72 F7
  static Uint8List requestPatchDumpEnd() {
    return buildMessage(SysexCommand.patchDumpEnd);
  }

  /// Store patch to hardware slot
  ///
  /// Format: F0 00 01 0C 03 71 ID P1 P2 ...160 bytes... F7
  /// After sending, must send patchDumpEnd marker
  ///
  /// POD XT Pro uses NON-CONTIGUOUS patch mapping (same as requestPatch):
  /// - Patches 0-63: MIDI patch 0-63
  /// - Patches 64-127: MIDI patch 192-255
  ///
  /// Returns the complete store message
  static Uint8List storePatch(int patchNumber, Uint8List patchData) {
    assert(patchNumber >= 0 && patchNumber < programCount,
      'Patch number must be 0-127');
    assert(patchData.length == programSize,
      'Patch data must be $programSize bytes');

    // POD XT Pro patch mapping (same as requestPatch)
    int midiPatch;
    if (patchNumber >= 0 && patchNumber <= 63) {
      midiPatch = patchNumber;        // 0-63 -> MIDI 0-63
    } else if (patchNumber >= 64 && patchNumber <= 127) {
      midiPatch = patchNumber + 128;  // 64-127 -> MIDI 192-255
    } else {
      throw ArgumentError('Patch number must be 0-127, got $patchNumber');
    }

    // Encode MIDI patch as two 7-bit bytes
    final p1 = (midiPatch >> 7) & 0x7F;  // Upper 7 bits
    final p2 = midiPatch & 0x7F;         // Lower 7 bits
    final id = 0x05;  // Device ID (broadcast)

    // Format from pod-ui: ID, P1, P2, data
    // (Note: Different from receive format which is P1, P2, ID, data)
    return buildMessage(
      SysexCommand.patchDumpResponse, // 03 71
      [id, p1, p2, ...patchData],
    );
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

  /// Request tuner note (current detected note)
  ///
  /// Format: F0 00 01 0C 03 57 16 F7
  /// Response: F0 00 01 0C 03 56 16 P1 P2 P3 P4 F7
  /// where note = u16 from 4 nibbles (P1 P2 P3 P4)
  static Uint8List requestTunerNote() {
    return buildMessage(SysexCommand.tunerRequest, [SysexCommand.tunerNoteSubcmd]);
  }

  /// Request tuner offset (cents from perfect pitch)
  ///
  /// Format: F0 00 01 0C 03 57 17 F7
  /// Response: F0 00 01 0C 03 56 17 P1 P2 P3 P4 F7
  /// where offset = i16 from 4 nibbles (P1 P2 P3 P4)
  static Uint8List requestTunerOffset() {
    return buildMessage(SysexCommand.tunerRequest, [SysexCommand.tunerOffsetSubcmd]);
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

/// Tuner data from POD XT Pro
class TunerData {
  final int? noteNumber; // MIDI note number (0-127+), null = no signal
  final int cents; // Tuning offset in cents (-50 to +50), 0 = in tune
  
  TunerData({
    this.noteNumber,
    required this.cents,
  });
  
  /// No signal constant (0xFFFE for note)
  static const int noSignalNote = 0xFFFE;
  
  /// No signal constant (97 for offset)
  static const int noSignalOffset = 97;
  
  /// Check if there's a valid signal
  bool get hasSignal => noteNumber != null;
  
  /// Get note name from MIDI note number
  /// Note names from pod-ui: ["B", "C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb"]
  String get noteName {
    if (noteNumber == null) return '—';
    const notes = ["B", "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#"];
    return notes[noteNumber! % 12];
  }
  
  /// Get octave number (1-based like pod-ui)
  int? get octave {
    if (noteNumber == null) return null;
    return (noteNumber! ~/ 12) + 1;
  }
  
  /// Calculate frequency from MIDI note number
  /// Formula: f = 440 * 2^((n-69)/12) where n is MIDI note number
  /// A4 (MIDI 69) = 440 Hz
  double? get frequency {
    if (noteNumber == null) return null;
    return 440.0 * math.pow(2, (noteNumber! - 69) / 12.0).toDouble();
  }
  
  /// Parse tuner note response
  /// Format: F0 00 01 0C 03 56 16 P1 P2 P3 P4 F7
  static TunerData? parseNote(List<int> payload) {
    if (payload.length < 5) return null;
    if (payload[0] != SysexCommand.tunerNoteSubcmd) return null;
    
    // Decode 4 nibbles to 16-bit value
    final note = PodXtSysex.decode4BitTo16(payload.sublist(1, 5));
    
    // Check for no signal
    if (note == noSignalNote) {
      return TunerData(noteNumber: null, cents: 0);
    }
    
    return TunerData(noteNumber: note, cents: 0);
  }
  
  /// Parse tuner offset response
  /// Format: F0 00 01 0C 03 56 17 P1 P2 P3 P4 F7
  static int? parseOffset(List<int> payload) {
    if (payload.length < 5) return null;
    if (payload[0] != SysexCommand.tunerOffsetSubcmd) return null;
    
    // Decode 4 nibbles to 16-bit value (signed)
    final rawOffset = PodXtSysex.decode4BitTo16(payload.sublist(1, 5));
    
    // Check for no signal
    if (rawOffset == noSignalOffset) {
      return null;
    }
    
    // Convert to signed int16 and clamp to -50..+50
    final offset = (rawOffset > 32767) ? rawOffset - 65536 : rawOffset;
    return offset.clamp(-50, 50);
  }
}
