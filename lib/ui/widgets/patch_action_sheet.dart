/// Platform-specific action menu for patch operations
/// macOS: Right-click context menu
/// Mobile/Other: Bottom sheet

library;

import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/pod_theme.dart';

/// Configuration for patch actions
class PatchActionConfig {
  // POD Preset actions
  final VoidCallback? onRename;
  final VoidCallback? onSaveHere;
  final VoidCallback? onCopyTo;
  final VoidCallback? onSaveToLibrary;
  final VoidCallback? onImportFromLibrary;

  // Local Library actions
  final VoidCallback? onLoad;
  final VoidCallback? onExportToSlot;
  final VoidCallback? onClone;
  final VoidCallback? onDelete;
  final VoidCallback? onSaveToFile;

  const PatchActionConfig({
    // POD Preset actions
    this.onRename,
    this.onSaveHere,
    this.onCopyTo,
    this.onSaveToLibrary,
    this.onImportFromLibrary,
    // Local Library actions
    this.onLoad,
    this.onExportToSlot,
    this.onClone,
    this.onDelete,
    this.onSaveToFile,
  });

  /// Create config for POD preset actions
  factory PatchActionConfig.forPodPreset({
    VoidCallback? onRename,
    VoidCallback? onSaveHere,
    VoidCallback? onCopyTo,
    VoidCallback? onSaveToLibrary,
    VoidCallback? onImportFromLibrary,
    VoidCallback? onSaveToFile,
  }) {
    return PatchActionConfig(
      onRename: onRename,
      onSaveHere: onSaveHere,
      onCopyTo: onCopyTo,
      onSaveToLibrary: onSaveToLibrary,
      onImportFromLibrary: onImportFromLibrary,
      onSaveToFile: onSaveToFile,
    );
  }

  /// Create config for local library actions
  factory PatchActionConfig.forLocalLibrary({
    VoidCallback? onLoad,
    VoidCallback? onExportToSlot,
    VoidCallback? onRename,
    VoidCallback? onClone,
    VoidCallback? onDelete,
    VoidCallback? onSaveToFile,
  }) {
    return PatchActionConfig(
      onLoad: onLoad,
      onExportToSlot: onExportToSlot,
      onRename: onRename,
      onClone: onClone,
      onDelete: onDelete,
      onSaveToFile: onSaveToFile,
    );
  }
}

/// Action menu item
class _ActionMenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ActionMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });
}

/// Show platform-specific action menu
Future<void> showPatchActionMenu({
  required BuildContext context,
  required PatchActionConfig config,
  Offset? position, // Required for macOS right-click, ignored on mobile
}) async {
  final actions = _buildActionList(config);

  if (actions.isEmpty) {
    return;
  }

  if (Platform.isMacOS && position != null) {
    // macOS: Show context menu at cursor position
    await _showMacOSContextMenu(context, actions, position);
  } else {
    // Mobile/Other: Show bottom sheet with haptic feedback
    HapticFeedback.mediumImpact();
    await _showMobileBottomSheet(context, actions);
  }
}

/// Build list of actions from config
List<_ActionMenuItem> _buildActionList(PatchActionConfig config) {
  final actions = <_ActionMenuItem>[];

  // POD Preset actions
  if (config.onLoad != null) {
    actions.add(_ActionMenuItem(
      icon: Icons.download,
      label: 'Load to Edit Buffer',
      onTap: config.onLoad!,
    ));
  }

  if (config.onSaveHere != null) {
    actions.add(_ActionMenuItem(
      icon: Icons.save,
      label: 'Save Here',
      onTap: config.onSaveHere!,
    ));
  }

  if (config.onCopyTo != null) {
    actions.add(_ActionMenuItem(
      icon: Icons.content_copy,
      label: 'Copy to Another Slot',
      onTap: config.onCopyTo!,
    ));
  }

  if (config.onExportToSlot != null) {
    actions.add(_ActionMenuItem(
      icon: Icons.upload,
      label: 'Export to Hardware Slot',
      onTap: config.onExportToSlot!,
    ));
  }

  if (config.onRename != null) {
    actions.add(_ActionMenuItem(
      icon: Icons.edit,
      label: 'Rename',
      onTap: config.onRename!,
    ));
  }

  if (config.onSaveToLibrary != null) {
    actions.add(_ActionMenuItem(
      icon: Icons.library_add,
      label: 'Save to Local Library',
      onTap: config.onSaveToLibrary!,
    ));
  }

  if (config.onImportFromLibrary != null) {
    actions.add(_ActionMenuItem(
      icon: Icons.folder_open,
      label: 'Import from Local Library',
      onTap: config.onImportFromLibrary!,
    ));
  }

  if (config.onClone != null) {
    actions.add(_ActionMenuItem(
      icon: Icons.control_point_duplicate,
      label: 'Clone',
      onTap: config.onClone!,
    ));
  }

  if (config.onSaveToFile != null) {
    actions.add(_ActionMenuItem(
      icon: Icons.file_download,
      label: 'Export to File',
      onTap: config.onSaveToFile!,
    ));
  }

  if (config.onDelete != null) {
    actions.add(_ActionMenuItem(
      icon: Icons.delete,
      label: 'Delete',
      onTap: config.onDelete!,
      isDestructive: true,
    ));
  }

  return actions;
}

/// Show macOS context menu
Future<void> _showMacOSContextMenu(
  BuildContext context,
  List<_ActionMenuItem> actions,
  Offset position,
) async {
  final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

  await showMenu(
    context: context,
    position: RelativeRect.fromLTRB(
      position.dx,
      position.dy,
      overlay.size.width - position.dx,
      overlay.size.height - position.dy,
    ),
    items: actions.map((action) {
      return PopupMenuItem(
        onTap: action.onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              action.icon,
              size: 18,
              color: action.isDestructive
                  ? Colors.redAccent
                  : PodColors.textLabel,
            ),
            const SizedBox(width: 12),
            Text(
              action.label,
              style: TextStyle(
                fontFamily: 'Copperplate',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: action.isDestructive
                    ? Colors.redAccent
                    : PodColors.textPrimary,
              ),
            ),
          ],
        ),
      );
    }).toList(),
    color: PodColors.surface,
    elevation: 8,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: const BorderSide(color: PodColors.knobBase, width: 1),
    ),
  );
}

/// Show mobile bottom sheet
Future<void> _showMobileBottomSheet(
  BuildContext context,
  List<_ActionMenuItem> actions,
) async {
  await showModalBottomSheet(
    context: context,
    backgroundColor: PodColors.surface,
    elevation: 8,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: PodColors.knobBase,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Patch Actions',
                style: const TextStyle(
                  fontFamily: 'Copperplate',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: PodColors.textPrimary,
                ),
              ),
            ),

            const Divider(height: 1),

            // Actions
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: actions.length,
              itemBuilder: (context, index) {
                final action = actions[index];
                return ListTile(
                  leading: Icon(
                    action.icon,
                    color: action.isDestructive
                        ? Colors.redAccent
                        : PodColors.textLabel,
                  ),
                  title: Text(
                    action.label,
                    style: TextStyle(
                      fontFamily: 'Copperplate',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: action.isDestructive
                          ? Colors.redAccent
                          : PodColors.textPrimary,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    action.onTap();
                  },
                );
              },
            ),

            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
