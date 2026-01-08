/// Settings screen for app configuration
library;

import 'package:flutter/material.dart';
import '../theme/pod_theme.dart';
import '../../models/app_settings.dart';
import '../../models/amp_models.dart';

class SettingsScreen extends StatefulWidget {
  final AppSettings settings;
  final Function(AppSettings) onSettingsChanged;

  const SettingsScreen({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AppSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = AppSettings(
      ampNameDisplayMode: widget.settings.ampNameDisplayMode,
      gridItemsPerRow: widget.settings.gridItemsPerRow,
      enableTempoScrolling: widget.settings.enableTempoScrolling,
    );
  }

  void _updateMode(AmpNameDisplayMode? mode) {
    if (mode == null) return;
    setState(() {
      _settings.ampNameDisplayMode = mode;
    });
    widget.onSettingsChanged(_settings);
  }

  void _updateGridItemsPerRow(int? value) {
    if (value == null) return;
    setState(() {
      _settings.gridItemsPerRow = value;
    });
    widget.onSettingsChanged(_settings);
  }

  void _updateTempoScrolling(bool value) {
    setState(() {
      _settings.enableTempoScrolling = value;
    });
    widget.onSettingsChanged(_settings);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Settings',
            style: TextStyle(
              color: PodColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // Amp Name Display setting
          _buildSettingRow(
            label: 'Amp Name Display',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: PodColors.surfaceLight,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: PodColors.surfaceLight, width: 1),
              ),
              child: DropdownButton<AmpNameDisplayMode>(
                value: _settings.ampNameDisplayMode,
                dropdownColor: PodColors.surface,
                underline: const SizedBox(),
                style: const TextStyle(
                  color: PodColors.textPrimary,
                  fontSize: 13,
                ),
                items: AmpNameDisplayMode.values.map((mode) {
                  return DropdownMenuItem(
                    value: mode,
                    child: Text(AppSettings.getModeName(mode)),
                  );
                }).toList(),
                onChanged: _updateMode,
              ),
            ),
          ),

          // Grid Items Per Row setting
          _buildSettingRow(
            label: 'Grid Items Per Row',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: PodColors.surfaceLight,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: PodColors.surfaceLight, width: 1),
              ),
              child: DropdownButton<int>(
                value: _settings.gridItemsPerRow,
                dropdownColor: PodColors.surface,
                underline: const SizedBox(),
                style: const TextStyle(
                  color: PodColors.textPrimary,
                  fontSize: 13,
                ),
                items: [4, 5, 6].map((value) {
                  return DropdownMenuItem(
                    value: value,
                    child: Text('$value items'),
                  );
                }).toList(),
                onChanged: _updateGridItemsPerRow,
              ),
            ),
          ),

          // Tempo Scrolling setting
          _buildSettingRow(
            label: 'Enable Tempo Scrolling',
            child: Switch(
              value: _settings.enableTempoScrolling,
              onChanged: _updateTempoScrolling,
              activeTrackColor: const Color(0xFFFF7A00).withValues(alpha: 0.5),
              activeThumbColor: const Color(0xFFFF7A00),
            ),
          ),

          // Add more settings here in the future
        ],
      ),
    );
  }

  Widget _buildSettingRow({
    required String label,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: PodColors.textPrimary,
              fontSize: 14,
            ),
          ),
          child,
        ],
      ),
    );
  }
}
