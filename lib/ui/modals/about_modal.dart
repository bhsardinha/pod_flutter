/// About modal displaying app information, version, and credits
library;

import 'package:flutter/material.dart';
import '../theme/pod_theme.dart';
import '../widgets/pod_modal.dart';

class AboutModal extends StatelessWidget {
  const AboutModal({super.key});

  @override
  Widget build(BuildContext context) {
    return PodModal(
      maxWidth: 450,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'About POD Flutter',
                style: TextStyle(
                  color: PodColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: PodColors.textSecondary),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // App Icon and Name
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: PodColors.accent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: PodColors.accent, width: 2),
                  ),
                  child: const Icon(
                    Icons.router,
                    size: 48,
                    color: PodColors.accent,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'POD Flutter',
                  style: TextStyle(
                    color: PodColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    color: PodColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Description
          const Text(
            'Cross-platform MIDI controller for the Line 6 POD XT Pro guitar processor. '
            'Control all parameters, manage patches, and sync with hardware via USB or Bluetooth MIDI.',
            style: TextStyle(
              color: PodColors.textPrimary,
              fontSize: 14,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          const Divider(height: 1, color: PodColors.surfaceLight),
          const SizedBox(height: 16),

          // License Section
          _buildInfoRow(
            icon: Icons.gavel,
            label: 'License',
            value: 'GNU General Public License v3.0',
          ),
          const SizedBox(height: 12),

          // Target Device
          _buildInfoRow(
            icon: Icons.device_hub,
            label: 'Target Device',
            value: 'Line 6 POD XT Pro',
          ),
          const SizedBox(height: 12),

          // Platform Support
          _buildInfoRow(
            icon: Icons.devices,
            label: 'Platforms',
            value: 'iOS, Android, macOS, Windows',
          ),
          const SizedBox(height: 16),

          const Divider(height: 1, color: PodColors.surfaceLight),
          const SizedBox(height: 16),

          // Repository Link
          const Center(
            child: Column(
              children: [
                Text(
                  'Repository',
                  style: TextStyle(
                    color: PodColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'github.com/bhsardinha/pod-flutter',
                  style: TextStyle(
                    color: PodColors.accent,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Credits
          const Center(
            child: Column(
              children: [
                Text(
                  'Reference Implementation',
                  style: TextStyle(
                    color: PodColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'pod-ui by arteme',
                  style: TextStyle(
                    color: PodColors.accent,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'github.com/arteme/pod-ui',
                  style: TextStyle(
                    color: PodColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Copyright
          const Center(
            child: Text(
              '© 2026 POD Flutter Contributors',
              style: TextStyle(
                color: PodColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: PodColors.accent,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: PodColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: PodColors.textPrimary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
