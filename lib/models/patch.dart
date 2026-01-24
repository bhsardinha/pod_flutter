/// Patch/Program data model for POD XT Pro
/// Based on pod-ui core/src/dump.rs and core/src/edit.rs

library;

import 'dart:typed_data';
import '../protocol/constants.dart';
import '../protocol/cc_map.dart';

/// Represents a single patch/program
class Patch {
  /// Raw patch data (160 bytes for POD XT/XT Pro)
  final Uint8List _data;

  /// Whether this patch has been modified since last save/load
  bool modified = false;

  Patch() : _data = Uint8List(programSize);

  Patch.fromData(Uint8List data)
      : _data = data.length == programSize
            ? Uint8List.fromList(data)
            : throw ArgumentError('Invalid patch data size: ${data.length}');

  /// Patch name (first 16 bytes, space-padded)
  String get name {
    final nameBytes = _data.sublist(0, programNameLength);
    // Find the last non-space character
    int end = programNameLength;
    while (end > 0 && nameBytes[end - 1] == 0x20) {
      end--;
    }
    return String.fromCharCodes(nameBytes.sublist(0, end));
  }

  set name(String value) {
    final bytes = value.padRight(programNameLength).substring(0, programNameLength).codeUnits;
    for (int i = 0; i < programNameLength; i++) {
      _data[i] = bytes[i];
    }
    modified = true;
  }

  /// Get parameter value by buffer address
  int getValueAt(int address) {
    if (address < 0 || address >= programSize) return 0;
    return _data[address];
  }

  /// Set parameter value by buffer address
  void setValueAt(int address, int value) {
    if (address < 0 || address >= programSize) return;
    _data[address] = value.clamp(0, 255);
    modified = true;
  }

  /// Get parameter value by CC param definition
  int getValue(CCParam param) {
    // Use bufferAddress which falls back to (32 + cc) if address is not explicitly set
    return getValueAt(param.bufferAddress);
  }

  /// Set parameter value by CC param definition
  void setValue(CCParam param, int value) {
    // Use bufferAddress which falls back to (32 + cc) if address is not explicitly set
    int finalValue = value.clamp(param.minValue, param.maxValue);
    if (param.inverted) {
      finalValue = param.maxValue - finalValue;
    }
    setValueAt(param.bufferAddress, finalValue);
  }

  /// Get a 16-bit value from MSB/LSB pair
  int getValue16(CCParam msbParam, CCParam lsbParam) {
    final msb = getValue(msbParam);
    final lsb = getValue(lsbParam);
    return (msb << 7) | lsb;
  }

  /// Set a 16-bit value to MSB/LSB pair
  void setValue16(CCParam msbParam, CCParam lsbParam, int value) {
    setValue(msbParam, (value >> 7) & 0x7F);
    setValue(lsbParam, value & 0x7F);
  }

  /// Get boolean switch value
  bool getSwitch(CCParam param) {
    final value = getValue(param);
    return param.inverted ? value < 64 : value >= 64;
  }

  /// Set boolean switch value
  void setSwitch(CCParam param, bool enabled) {
    setValue(param, enabled ? 127 : 0);
  }

  /// Raw data access
  Uint8List get data => Uint8List.fromList(_data);

  /// Copy patch data
  Patch copy() => Patch.fromData(_data);

  @override
  String toString() => 'Patch("$name")';
}

/// Collection of all patches in POD memory
class PatchLibrary {
  final List<Patch> patches;

  PatchLibrary() : patches = List.generate(programCount, (_) => Patch());

  PatchLibrary.fromPatches(this.patches);

  Patch operator [](int index) => patches[index];

  int get length => patches.length;

  /// Check if any patch has been modified
  bool get hasModifications => patches.any((p) => p.modified);

  /// Get list of modified patch indices
  List<int> get modifiedIndices =>
      patches.asMap().entries.where((e) => e.value.modified).map((e) => e.key).toList();
}

/// Current edit buffer state
class EditBuffer {
  Patch patch;
  int? sourceProgram; // Which program this was loaded from (null = new)
  bool modified = false;

  EditBuffer() : patch = Patch();

  EditBuffer.fromPatch(this.patch, [this.sourceProgram]);

  /// Load a program into the edit buffer
  void loadProgram(Patch source, int programNumber) {
    patch = source.copy();
    sourceProgram = programNumber;
    modified = false;
  }

  /// Mark as modified (called when any parameter changes)
  void markModified() {
    modified = true;
    patch.modified = true;
  }
}
