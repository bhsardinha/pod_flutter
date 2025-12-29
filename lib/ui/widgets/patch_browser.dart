import 'package:flutter/material.dart';
import '../theme/pod_theme.dart';

/// A horizontal patch browser widget for navigating patches.
///
/// Features:
/// - Left/right arrows for previous/next patch
/// - Center area shows bank + number + patch name
/// - Tap center to open full patch list modal
/// - Modified indicator when patch has unsaved changes
class PatchBrowser extends StatelessWidget {
  /// Current patch bank (e.g., "01A", "16D")
  final String bank;

  /// Current patch name
  final String patchName;

  /// Whether the current patch has unsaved changes
  final bool isModified;

  /// Callback for previous patch
  final VoidCallback onPrevious;

  /// Callback for next patch
  final VoidCallback onNext;

  /// Callback when center is tapped (open patch list)
  final VoidCallback onTap;

  const PatchBrowser({
    super.key,
    required this.bank,
    required this.patchName,
    this.isModified = false,
    required this.onPrevious,
    required this.onNext,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: PodColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: PodColors.surfaceLight,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Previous button
          _NavButton(
            icon: Icons.chevron_left,
            onTap: onPrevious,
          ),

          // Patch info (tappable)
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Bank indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: PodColors.accent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: PodColors.accent.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        bank,
                        style: const TextStyle(
                          color: PodColors.accent,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Patch name
                    Flexible(
                      child: Text(
                        '"$patchName"',
                        style: const TextStyle(
                          color: PodColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    // Modified indicator
                    if (isModified) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: PodColors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Next button
          _NavButton(
            icon: Icons.chevron_right,
            onTap: onNext,
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          border: Border(
            left: icon == Icons.chevron_right
                ? BorderSide(color: PodColors.surfaceLight, width: 1)
                : BorderSide.none,
            right: icon == Icons.chevron_left
                ? BorderSide(color: PodColors.surfaceLight, width: 1)
                : BorderSide.none,
          ),
        ),
        child: Icon(
          icon,
          color: PodColors.textSecondary,
          size: 28,
        ),
      ),
    );
  }
}
