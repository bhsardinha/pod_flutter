import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/pod_controller.dart';
import '../../services/midi_service.dart';
import '../theme/pod_theme.dart';

/// Connection panel widget for device discovery and connection
class ConnectionModal extends StatefulWidget {
  final PodController podController;
  final bool isConnected;
  final bool isConnecting;
  final VoidCallback onDisconnect;

  const ConnectionModal({
    super.key,
    required this.podController,
    required this.isConnected,
    required this.isConnecting,
    required this.onDisconnect,
  });

  @override
  State<ConnectionModal> createState() => _ConnectionModalState();
}

class _ConnectionModalState extends State<ConnectionModal> {
  List<MidiDeviceInfo> _devices = [];
  bool _scanning = false;
  String? _error;
  String? _connectingDeviceId; // Track which device is being connected
  StreamSubscription<List<MidiDeviceInfo>>? _deviceSubscription;

  @override
  void initState() {
    super.initState();

    // Listen for device changes (hot-plug detection)
    // But don't update list while connecting to avoid reordering
    _deviceSubscription = widget.podController.onDevicesChanged.listen((devices) {
      if (mounted && _connectingDeviceId == null) {
        setState(() {
          _devices = devices;
          _scanning = false;
          _error = null;
        });
      }
    });

    if (!widget.isConnected) {
      _scanDevices();
    }
  }

  @override
  void dispose() {
    _deviceSubscription?.cancel();
    super.dispose();
  }

  Future<void> _scanDevices() async {
    if (!mounted) return;

    setState(() {
      _scanning = true;
      _error = null;
    });

    try {
      final devices = await widget.podController.scanDevices();
      if (mounted) {
        setState(() {
          _devices = devices;
          _scanning = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // Remove "Exception: " prefix for cleaner display
          _error = e.toString().replaceFirst('Exception: ', '');
          _scanning = false;
        });
      }
    }
  }

  Future<void> _connectToDevice(MidiDeviceInfo device) async {
    if (!mounted) return;

    // Set connecting state immediately for UI feedback
    setState(() {
      _connectingDeviceId = device.id;
      _error = null;
    });

    try {
      // Start connection in background
      await widget.podController.connect(device);

      // Close modal immediately on success
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Show error and clear connecting state
      if (mounted) {
        setState(() {
          _connectingDeviceId = null;
          _error = 'Failed to connect: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isConnected) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Connected to POD XT Pro',
            style: TextStyle(color: PodColors.textPrimary, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Connection established and ready',
            style: TextStyle(color: PodColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              ElevatedButton(
                onPressed: () {
                  widget.podController.refreshEditBuffer();
                },
                child: const Text('Sync from POD'),
              ),
              ElevatedButton(
                onPressed: widget.onDisconnect,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                ),
                child: const Text('Disconnect'),
              ),
            ],
          ),
        ],
      );
    }

    if (widget.isConnecting) {
      return const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Connecting...', style: TextStyle(color: PodColors.textPrimary)),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.red.shade900.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade700, width: 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red.shade300, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Colors.red.shade200,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (_scanning)
          const Center(
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text(
                  'Scanning for MIDI devices...',
                  style: TextStyle(color: PodColors.textPrimary),
                ),
                SizedBox(height: 4),
                Text(
                  'Checking USB connections',
                  style: TextStyle(
                    color: PodColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          )
        else if (_devices.isEmpty)
          Column(
            children: [
              Icon(
                Icons.devices_other,
                color: PodColors.textSecondary,
                size: 48,
              ),
              const SizedBox(height: 12),
              const Text(
                'No MIDI devices found',
                style: TextStyle(
                  color: PodColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Make sure your POD XT Pro is:\n'
                '• Powered on\n'
                '• Connected via USB cable\n'
                '• Recognized by your device\n'
                '\n'
                'Tip: USB MIDI devices are detected\n'
                'automatically when connected',
                style: TextStyle(
                  color: PodColors.textSecondary,
                  fontSize: 12,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _connectingDeviceId == null ? _scanDevices : null,
                icon: const Icon(Icons.refresh),
                label: const Text('Scan Again'),
              ),
            ],
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Available Devices:',
                style: TextStyle(color: PodColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 12),
              ..._devices.map(
                (device) {
                  final isConnecting = _connectingDeviceId == device.id;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ElevatedButton(
                      onPressed: _connectingDeviceId == null
                          ? () => _connectToDevice(device)
                          : null, // Disable all buttons while connecting
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isConnecting
                            ? PodColors.surfaceLight.withValues(alpha: 0.7)
                            : PodColors.surfaceLight,
                        foregroundColor: PodColors.textPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      child: Row(
                        children: [
                          if (isConnecting)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  PodColors.textPrimary,
                                ),
                              ),
                            )
                          else
                            Icon(
                              device.isBleMidi ? Icons.bluetooth : Icons.usb,
                              size: 18,
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              device.name,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isConnecting
                                    ? PodColors.textPrimary.withValues(alpha: 0.7)
                                    : PodColors.textPrimary,
                              ),
                            ),
                          ),
                          if (isConnecting)
                            const Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: Text(
                                'Connecting...',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: PodColors.textSecondary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _connectingDeviceId == null ? _scanDevices : null,
                child: const Text('Refresh'),
              ),
            ],
          ),
      ],
    );
  }
}
