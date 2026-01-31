# Windows Setup Guide

This guide covers setting up POD Flutter on Windows for USB MIDI communication with the Line 6 POD XT Pro.

---

## Requirements

### Hardware

- Line 6 POD XT Pro
- USB cable (USB-A to USB-B)
- Windows 10 or later

### Software

- [Line 6 Drivers](https://line6.com/software/) - Official POD XT Pro USB drivers
- Flutter SDK (for building from source)

---

## Installation

### 1. Install Line 6 Drivers

1. Download the official Line 6 POD XT Pro drivers from [line6.com/software/](https://line6.com/software/)
2. Run the installer and follow the prompts
3. Restart your computer after installation

### 2. Connect POD XT Pro

1. Power on your POD XT Pro
2. Connect the USB cable from your POD to your Windows PC
3. Windows should recognize the device as "Line 6 POD XT Pro"
4. Verify in Device Manager under "Sound, video and game controllers"

### 3. Install POD Flutter

#### Option A: Download Release (when available)

1. Download the latest Windows release from the [Releases](https://github.com/yourusername/pod_flutter/releases) page
2. Extract the ZIP file
3. Run `pod_flutter.exe`

#### Option B: Build from Source

```bash
# Clone repository
git clone https://github.com/yourusername/pod_flutter.git
cd pod_flutter

# Install dependencies
flutter pub get

# Build Windows release
flutter build windows --release

# Run the app
.\build\windows\x64\runner\Release\pod_flutter.exe
```

---

## Usage

### Connect to POD

1. Launch POD Flutter
2. Click the connection icon in the top-left
3. The POD XT Pro should appear in the device list as "Line 6 POD XT Pro"
4. Click to connect
5. The edit buffer will load automatically

### Controls

- **Right-click**: Context menu (on patch cards, program slots)
- **Left-click**: Select/activate
- **Scroll wheel**: Navigate lists
- **Drag knobs**: Adjust parameters

---

## Troubleshooting

### POD Not Detected

1. **Check Device Manager**:
   - Open Device Manager (Win+X → Device Manager)
   - Look under "Sound, video and game controllers"
   - Verify "Line 6 POD XT Pro" is listed without errors (yellow triangle)

2. **Reinstall Drivers**:
   - If device shows errors, uninstall and reinstall Line 6 drivers
   - Restart computer after reinstallation

3. **Try Different USB Port**:
   - Some USB 3.0 ports may have issues
   - Try a USB 2.0 port if available

4. **Check USB Cable**:
   - Verify cable is working (try another cable if available)
   - Ensure it's a data cable, not charge-only

### Connection Drops

- Close other MIDI applications (DAWs, etc.) that might be using the POD
- Disable Windows USB power management:
  1. Device Manager → Universal Serial Bus controllers
  2. Right-click each USB Root Hub → Properties
  3. Power Management → Uncheck "Allow computer to turn off this device"

### Parameters Not Updating

1. Verify connection status (green indicator in top-left)
2. Try disconnecting and reconnecting
3. Restart the app
4. Power cycle the POD XT Pro

---

## Known Limitations

### Windows-Specific

- **USB MIDI Only**: Bluetooth MIDI is not currently supported on Windows
  - The `flutter_midi_command` library does not support BLE-MIDI on Windows
  - Use direct USB connection with official Line 6 drivers

- **USB-C Adapters**: Some USB-C to USB-A adapters may cause issues
  - Prefer native USB-A ports when possible

### General

- Bulk import of 128 patches takes ~6-7 seconds (hardware limitation)
- No undo/redo for parameter changes
- Patch caching not yet implemented (re-import needed on app restart)

---

## Performance Tips

- **Disable Antivirus Scanning**: Add exception for pod_flutter.exe to improve performance
- **Close Background Apps**: Free up resources for smooth parameter updates
- **Use Release Build**: Debug builds are significantly slower

---

## Additional Resources

- [POD XT Pro Manual](https://line6.com/support/manuals/)
- [MIDI Protocol Documentation](../PROTOCOL.md)
- [Architecture Overview](../ARCHITECTURE.md)
- [Issue Tracker](https://github.com/yourusername/pod_flutter/issues)

---

## Support

For Windows-specific issues, please include:
- Windows version (e.g., Windows 11 23H2)
- Line 6 driver version
- Device Manager screenshot showing POD device
- Error messages or logs
