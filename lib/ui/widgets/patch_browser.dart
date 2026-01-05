import 'package:flutter/material.dart';
import '../theme/pod_theme.dart';
import 'dot_matrix_lcd.dart';

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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: DotMatrixLCD(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Center(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: bank,
                            style: const TextStyle(
                              fontFamily: 'Doto',
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFF7A00),
                              letterSpacing: 1.5,
                            ),
                          ),
                          const TextSpan(
                            text: ': ',
                            style: TextStyle(
                              fontFamily: 'Doto',
                              fontSize: 18,
                              color: Color(0xFFFF7A00),
                            ),
                          ),
                          TextSpan(
                            text: patchName,
                            style: const TextStyle(
                              fontFamily: 'Doto',
                              fontSize: 18,
                              color: Color(0xFFFF7A00),
                              letterSpacing: 1.2,
                            ),
                          ),
                          if (isModified)
                            const TextSpan(
                              text: ' *',
                              style: TextStyle(
                                fontFamily: 'Doto',
                                fontSize: 18,
                                color: Color(0xFFFF7A00),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
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
