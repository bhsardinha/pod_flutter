/// Line6 POD XT Pro MIDI Protocol Constants
/// Extracted from pod-ui (https://github.com/arteme/pod-ui)

library;

/// Line6 Manufacturer ID for sysex messages
const List<int> line6ManufacturerId = [0x00, 0x01, 0x0C];

/// POD XT Pro device identification
const int podXtFamily = 0x0003;
const int podXtProMember = 0x0005;

/// Sysex command bytes
class SysexCommand {
  // POD XT specific commands (0x03 prefix)
  static const installedPacks = [0x03, 0x0E];
  static const editBufferDumpRequest = [0x03, 0x75];
  static const bufferDumpResponse = [0x03, 0x74];
  static const patchDumpRequest = [0x03, 0x73];
  static const patchDumpResponse = [0x03, 0x71];
  static const patchDumpEnd = [0x03, 0x72];
  static const savedPatchNotification = [0x03, 0x24];
  static const storeSuccess = [0x03, 0x50];
  static const storeFailure = [0x03, 0x51];
  static const tunerData = [0x03, 0x56];
  static const programState = [0x03, 0x57];
}

/// Program/Patch storage constants
const int programCount = 128;
const int programSize = 160; // 72*2 + 16 bytes = 144 + 16 = 160
const int programNameLength = 16;
const int programNameAddress = 0;

/// Expansion pack bitflags
class XtPacks {
  static const int ms = 0x01; // Metal Shop Amp Expansion
  static const int cc = 0x02; // Collector's Classic Amp Expansion
  static const int fx = 0x04; // FX Junkie Effects Expansion
  static const int bx = 0x08; // Bass Expansion
}
