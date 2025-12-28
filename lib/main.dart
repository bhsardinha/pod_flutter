import 'package:flutter/material.dart';
import 'ui/screens/main_screen.dart';
import 'ui/theme/pod_theme.dart';

void main() {
  runApp(const PodApp());
}

class PodApp extends StatelessWidget {
  const PodApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POD XT Pro Controller',
      theme: PodTheme.theme,
      debugShowCheckedModeBanner: false,
      home: const MainScreen(),
    );
  }
}
