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
    );
  }

  void _updateMode(AmpNameDisplayMode mode) {
    setState(() {
      _settings.ampNameDisplayMode = mode;
    });
    widget.onSettingsChanged(_settings);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PodColors.background,
      appBar: AppBar(
        backgroundColor: PodColors.surface,
        title: const Text(
          'Settings',
          style: TextStyle(color: PodColors.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: PodColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Amp Name Display Section
              const Text(
                'Amp Name Display',
                style: TextStyle(
                  color: PodColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose how amp names are displayed throughout the app',
                style: TextStyle(
                  color: PodColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),

              // Display mode options
              ...AmpNameDisplayMode.values.map((mode) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildModeOption(mode),
                );
              }),

              const SizedBox(height: 24),

              // Preview section
              const Text(
                'Preview',
                style: TextStyle(
                  color: PodColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildPreview(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeOption(AmpNameDisplayMode mode) {
    final isSelected = _settings.ampNameDisplayMode == mode;

    return GestureDetector(
      onTap: () => _updateMode(mode),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? PodColors.surfaceLight : PodColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? PodColors.accent : PodColors.surfaceLight,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? PodColors.accent : PodColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppSettings.getModeName(mode),
                    style: TextStyle(
                      color: PodColors.textPrimary,
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppSettings.getModeDescription(mode),
                    style: const TextStyle(
                      color: PodColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    // Example amps to show preview
    final exampleAmps = [
      AmpModels.byId(26), // Treadplate Dual (Mesa)
      AmpModels.byId(22), // Brit J-800 (Marshall)
      AmpModels.byId(37), // Bomber Uber (MS pack)
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PodColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: PodColors.surfaceLight, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: exampleAmps.map((amp) {
          if (amp == null) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: _buildAmpPreview(amp),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAmpPreview(AmpModel amp) {
    switch (_settings.ampNameDisplayMode) {
      case AmpNameDisplayMode.factory:
        return Text(
          amp.getDisplayName(AmpNameDisplayMode.factory),
          style: const TextStyle(
            color: PodColors.textPrimary,
            fontSize: 13,
          ),
        );

      case AmpNameDisplayMode.realAmp:
        return Text(
          amp.getDisplayName(AmpNameDisplayMode.realAmp),
          style: const TextStyle(
            color: PodColors.textPrimary,
            fontSize: 13,
          ),
        );

      case AmpNameDisplayMode.both:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (amp.realName != null)
              Text(
                amp.realName!,
                style: const TextStyle(
                  color: PodColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            Text(
              amp.getDisplayName(AmpNameDisplayMode.factory),
              style: const TextStyle(
                color: PodColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
    }
  }
}
