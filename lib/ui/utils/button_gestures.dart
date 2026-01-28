import 'package:flutter/material.dart';

/// Standard button gesture configuration
///
/// Provides consistent gesture detection patterns across all buttons in the app.
/// - `onTap`: Primary action (toggle, open, or nothing)
/// - `onLongPress`: Secondary action (usually modal)
/// - `enableSecondaryTap`: Maps right-click to `onLongPress` for desktop support
class ButtonGestureConfig {
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool enableSecondaryTap;

  const ButtonGestureConfig({
    this.onTap,
    this.onLongPress,
    this.enableSecondaryTap = true,
  });
}

/// Wrapper widget that provides consistent gesture detection across all buttons.
///
/// Features:
/// - Tap for primary action
/// - Long-press for secondary action
/// - Right-click (desktop) maps to long-press for mobile compatibility
/// - Consistent hit test behavior
class ButtonGestureDetector extends StatelessWidget {
  final Widget child;
  final ButtonGestureConfig config;

  const ButtonGestureDetector({
    super.key,
    required this.child,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: config.onTap,
      onLongPress: config.onLongPress,
      onSecondaryTap: config.enableSecondaryTap ? config.onLongPress : null,
      behavior: HitTestBehavior.opaque,
      child: child,
    );
  }
}
