import 'package:flutter/material.dart';
import '../../services/ble_midi_service.dart';
import '../../services/midi_service.dart';

class MidiTestScreen extends StatefulWidget {
  const MidiTestScreen({super.key});

  @override
  State<MidiTestScreen> createState() => _MidiTestScreenState();
}

class _MidiTestScreenState extends State<MidiTestScreen> {
  final BleMidiService _midi = BleMidiService();

  List<MidiDeviceInfo> _devices = [];
  MidiDeviceInfo? _connectedDevice;
  bool _isScanning = false;
  String _status = 'Ready';
  final List<String> _log = [];

  @override
  void initState() {
    super.initState();
    _setupListeners();
  }

  void _setupListeners() {
    _midi.onControlChange.listen((cc) {
      _addLog('CC ${cc.cc} = ${cc.value}');
    });

    _midi.onProgramChange.listen((pc) {
      _addLog('Program Change: $pc');
    });

    _midi.onSysex.listen((sysex) {
      _addLog('Sysex: ${sysex.command.map((b) => b.toRadixString(16)).join(" ")} (${sysex.payload.length} bytes)');
    });

    _midi.onConnectionChanged.listen((connected) {
      setState(() {
        _status = connected ? 'Connected' : 'Disconnected';
        if (!connected) _connectedDevice = null;
      });
    });
  }

  void _addLog(String message) {
    setState(() {
      _log.insert(0, '${DateTime.now().toString().substring(11, 19)} $message');
      if (_log.length > 50) _log.removeLast();
    });
  }

  Future<void> _scanDevices() async {
    setState(() {
      _isScanning = true;
      _status = 'Scanning...';
    });

    try {
      final devices = await _midi.scanDevices();
      setState(() {
        _devices = devices;
        _status = 'Found ${devices.length} device(s)';
      });
      _addLog('Scan complete: ${devices.length} devices');
      for (final d in devices) {
        _addLog('  - ${d.name} (${d.isBleMidi ? "BLE" : "USB/Virtual"})');
      }
    } catch (e) {
      _addLog('Scan error: $e');
      setState(() => _status = 'Scan error: $e');
    } finally {
      setState(() => _isScanning = false);
    }
  }

  Future<void> _connect(MidiDeviceInfo device) async {
    setState(() => _status = 'Connecting to ${device.name}...');
    _addLog('Connecting to ${device.name}...');

    try {
      await _midi.connect(device);
      setState(() {
        _connectedDevice = device;
        _status = 'Connected to ${device.name}';
      });
      _addLog('Connected!');
    } catch (e) {
      _addLog('Connection error: $e');
      setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _disconnect() async {
    await _midi.disconnect();
    _addLog('Disconnected');
  }

  Future<void> _sendTestCC() async {
    if (_connectedDevice == null) return;

    // Send a test CC - reading the drive value
    _addLog('Sending CC 13 (drive) = 64');
    await _midi.sendCC(13, 64);
  }

  Future<void> _requestEditBuffer() async {
    if (_connectedDevice == null) return;

    _addLog('Requesting edit buffer dump...');
    await _midi.requestEditBuffer();
  }

  @override
  void dispose() {
    _midi.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MIDI Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status bar
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  _status,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Action buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _isScanning ? null : _scanDevices,
                  icon: _isScanning
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  label: const Text('Scan Devices'),
                ),
                if (_connectedDevice != null) ...[
                  ElevatedButton.icon(
                    onPressed: _disconnect,
                    icon: const Icon(Icons.link_off),
                    label: const Text('Disconnect'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _sendTestCC,
                    icon: const Icon(Icons.send),
                    label: const Text('Send CC'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _requestEditBuffer,
                    icon: const Icon(Icons.download),
                    label: const Text('Request Buffer'),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Device list
            if (_devices.isNotEmpty) ...[
              Text('Devices:', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  itemCount: _devices.length,
                  itemBuilder: (context, index) {
                    final device = _devices[index];
                    final isConnected = _connectedDevice?.id == device.id;
                    return ListTile(
                      leading: Icon(
                        device.isBleMidi ? Icons.bluetooth : Icons.usb,
                        color: isConnected ? Colors.green : null,
                      ),
                      title: Text(device.name),
                      subtitle: Text(device.isBleMidi ? 'Bluetooth MIDI' : 'USB/Virtual MIDI'),
                      trailing: isConnected
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : TextButton(
                              onPressed: () => _connect(device),
                              child: const Text('Connect'),
                            ),
                    );
                  },
                ),
              ),
              const Divider(),
            ],

            // Log
            Text('Log:', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(8),
                child: ListView.builder(
                  itemCount: _log.length,
                  itemBuilder: (context, index) {
                    return Text(
                      _log[index],
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Colors.greenAccent,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
