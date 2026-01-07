import 'package:flutter/material.dart';
import 'services/pod_controller.dart';
import 'services/ble_midi_service.dart';
import 'models/app_settings.dart';
import 'ui/screens/main_screen.dart';
import 'ui/theme/pod_theme.dart';

void main() {
  runApp(const PodApp());
}

class PodApp extends StatefulWidget {
  const PodApp({super.key});

  @override
  State<PodApp> createState() => _PodAppState();
}

class _PodAppState extends State<PodApp> {
  late final PodController _podController;
  AppSettings? _settings;

  @override
  void initState() {
    super.initState();
    final midiService = BleMidiService();
    _podController = PodController(midiService);
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await AppSettings.load();
    setState(() {
      _settings = settings;
    });
  }

  @override
  void dispose() {
    _podController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POD XT Pro Controller',
      theme: PodTheme.theme,
      debugShowCheckedModeBanner: false,
      home: _settings == null
          ? const Scaffold(
              backgroundColor: PodColors.background,
              body: Center(
                child: CircularProgressIndicator(
                  color: PodColors.accent,
                ),
              ),
            )
          : MainScreen(
              podController: _podController,
              settings: _settings!,
            ),
    );
  }
}
