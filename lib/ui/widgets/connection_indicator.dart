import 'package:flutter/material.dart';
import '../theme/pod_theme.dart';

/// A simple connection status indicator widget.
///
/// Displays a colored dot indicating connection state:
/// - Green dot with glow = connected
/// - Red dot = disconnected
///
/// Tap to open connection screen/modal.
class ConnectionIndicator extends StatelessWidget {
  /// Whether the device is connected
  final bool isConnected;

  /// Callback when tapped (e.g., to open connection modal)
  final VoidCallback onTap;

  const ConnectionIndicator({
    super.key,
    required this.isConnected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color dotColor = isConnected
        ? PodColors.buttonOnGreen
        : const Color(0xFFCC0000);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: PodColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: PodColors.surfaceLight,
            width: 1,
          ),
        ),
        child: Center(
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dotColor,
              boxShadow: isConnected
                  ? [
                      BoxShadow(
                        color: dotColor.withValues(alpha: 0.6),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
