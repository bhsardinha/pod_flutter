import 'package:flutter/material.dart';
import '../theme/pod_theme.dart';

/// A custom modal widget with dark theme styling for the Pod application.
///
/// Features:
/// - Semi-transparent dark overlay
/// - Rounded corners
/// - Dark surface background
/// - Optional title
/// - Tap outside to dismiss
class PodModal extends StatelessWidget {
  /// The content to display inside the modal
  final Widget child;

  /// Optional title to display at the top of the modal
  final String? title;

  const PodModal({
    super.key,
    required this.child,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 500,
          maxHeight: 600,
        ),
        margin: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: PodColors.surface,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (title != null) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 16.0),
                  child: Text(
                    title!,
                    style: const TextStyle(
                      color: PodColors.textPrimary,
                      fontSize: 20.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  height: 1.0,
                  color: PodColors.surfaceLight,
                ),
              ],
              Flexible(
                child: Padding(
                  padding: title != null
                      ? const EdgeInsets.all(24.0)
                      : const EdgeInsets.all(32.0),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows a modal dialog with Pod styling.
///
/// The modal features:
/// - Centered on screen with generous padding from edges
/// - Dark overlay that can be tapped to dismiss
/// - Rounded corners and dark surface background
/// - Optional title at the top
///
/// Example:
/// ```dart
/// showPodModal(
///   context: context,
///   title: 'Settings',
///   child: Text('Modal content here'),
/// );
/// ```
///
/// Returns a [Future] that resolves to the value (if any) that was passed to
/// [Navigator.pop] when the modal was closed.
Future<T?> showPodModal<T>({
  required BuildContext context,
  required Widget child,
  String? title,
}) {
  return showDialog<T>(
    context: context,
    barrierColor: PodColors.modalOverlay,
    builder: (context) => PodModal(
      title: title,
      child: child,
    ),
  );
}
