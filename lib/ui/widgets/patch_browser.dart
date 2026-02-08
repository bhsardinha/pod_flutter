import 'package:flutter/material.dart';
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

  /// Callback when modified indicator (*) is tapped
  final VoidCallback? onModifiedTap;

  const PatchBrowser({
    super.key,
    required this.bank,
    required this.patchName,
    this.isModified = false,
    required this.onPrevious,
    required this.onNext,
    required this.onTap,
    this.onModifiedTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Previous button (outside container)
        _NavButton(icon: Icons.chevron_left, onTap: onPrevious),

        // Patch info (tappable) with container styling
        Expanded(
          child: GestureDetector(
            onTap: onTap,
            onSecondaryTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              child: DotMatrixLCD(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Center(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Left column: Bank
                      SizedBox(
                        width: 60,
                        child: Text(
                          bank,
                          style: const TextStyle(
                            fontFamily: 'Doto',
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF7A00),
                            letterSpacing: 1.5,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ),
                      // Center column: Patch name
                      Expanded(
                        child: Text(
                          patchName,
                          style: const TextStyle(
                            fontFamily: 'Doto',
                            fontSize: 24,
                            color: Color(0xFFFF7A00),
                            letterSpacing: 1.2,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      // Right column: Modified indicator
                      SizedBox(
                        width: 30,
                        child: GestureDetector(
                          onTap: isModified ? onModifiedTap : null,
                          child: Text(
                            isModified ? '*' : '',
                            style: const TextStyle(
                              fontFamily: 'Doto',
                              fontSize: 24,
                              color: Color(0xFFFF7A00),
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Next button (outside container)
        _NavButton(icon: Icons.chevron_right, onTap: onNext),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Icon(
          icon,
          color: const Color(0xFF3D0112), // Much darker to match darker brushed metal
          size: 34,
          shadows: [
            // Dark shadow on top-left (engraved depression)
            Shadow(
              color: Colors.black.withValues(alpha: 0.9),
              offset: const Offset(-1.5, -1.5),
              blurRadius: 2.0,
            ),
            // Light highlight on bottom-right (edge catch light)
            Shadow(
              color: Colors.white.withValues(alpha: 0.2),
              offset: const Offset(1.5, 1.5),
              blurRadius: 2.0,
            ),
          ],
        ),
      ),
    );
  }
}
