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
          // Close button (top-right)
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: const Icon(Icons.close, color: PodColors.textSecondary),
              onPressed: () => Navigator.of(context).pop(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
          const SizedBox(height: 8),

          // Version
          const Center(
            child: Text(
              'POD Flutter v1.0.0',
              style: TextStyle(
                color: PodColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Description
          const Text(
            'Cross-platform MIDI controller for the Line 6 POD XT Pro guitar processor. '
            'Control all parameters, manage patches, and sync with hardware via USB or Bluetooth MIDI.',
            style: TextStyle(
              color: PodColors.textPrimary,
              fontSize: 12,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          const Divider(height: 1, color: PodColors.surfaceLight),
          const SizedBox(height: 12),

          // License Section
          _buildInfoRow(
            icon: Icons.gavel,
            label: 'License',
            value: 'GNU General Public License v3.0',
          ),
          const SizedBox(height: 10),

          // Target Device
          _buildInfoRow(
            icon: Icons.device_hub,
            label: 'Target Device',
            value: 'Line 6 POD XT Pro',
          ),
          const SizedBox(height: 10),

          // Platform Support
          _buildInfoRow(
            icon: Icons.devices,
            label: 'Platforms',
            value: 'iOS, Android, macOS, Windows',
          ),
          const SizedBox(height: 12),

          const Divider(height: 1, color: PodColors.surfaceLight),
          const SizedBox(height: 12),

          // Repository Link
          const Center(
            child: Column(
              children: [
                Text(
                  'Repository',
                  style: TextStyle(
                    color: PodColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'github.com/bhsardinha/pod-flutter',
                  style: TextStyle(
                    color: PodColors.accent,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Credits
          const Center(
            child: Column(
              children: [
                Text(
                  'Reference Implementation',
                  style: TextStyle(
                    color: PodColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'pod-ui by arteme',
                  style: TextStyle(
                    color: PodColors.accent,
                    fontSize: 11,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'github.com/arteme/pod-ui',
                  style: TextStyle(
                    color: PodColors.textSecondary,
                    fontSize: 10,
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
                fontSize: 10,
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
          size: 16,
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
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: PodColors.textPrimary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
