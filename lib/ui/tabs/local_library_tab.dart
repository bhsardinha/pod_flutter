/// Local Library tab - Personal patch collection with metadata

library;

import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../../models/local_patch.dart';
import '../../models/patch_filter.dart';
import '../../services/local_library_service.dart';
import '../../services/pod_controller.dart';
import '../theme/pod_theme.dart';
import '../widgets/patch_action_sheet.dart';
import '../widgets/patch_detail_card.dart';
import '../widgets/patch_metadata_editor.dart';
import '../widgets/patch_filter_panel.dart';

/// Local library tab showing personal patches
class LocalLibraryTab extends StatefulWidget {
  final LocalLibraryService localLibraryService;
  final PodController podController;
  final Function(VoidCallback)? onRefreshCallback;

  const LocalLibraryTab({
    super.key,
    required this.localLibraryService,
    required this.podController,
    this.onRefreshCallback,
  });

  @override
  State<LocalLibraryTab> createState() => _LocalLibraryTabState();
}

class _LocalLibraryTabState extends State<LocalLibraryTab> {
  List<LocalPatch> _allPatches = [];
  List<LocalPatch> _filteredPatches = [];
  LocalPatch? _selectedPatch;
  bool _loading = true;
  FilterCriteria _criteria = const FilterCriteria();
  SortOrder _sortOrder = SortOrder.dateModifiedDesc;
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _loadPatches();

    // Register refresh callback with parent - force refresh when called from import
    widget.onRefreshCallback?.call(() => _loadPatches(forceRefresh: true));
  }

  Future<void> _loadPatches({bool forceRefresh = false}) async {
    setState(() => _loading = true);

    try {
      final patches = await widget.localLibraryService.loadAllPatches(
        forceRefresh: forceRefresh,
      );
      setState(() {
        _allPatches = patches;
        _applyFiltersAndSort();
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load library: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _applyFiltersAndSort() {
    setState(() {
      _filteredPatches = applyFilterAndSort(_allPatches, _criteria, _sortOrder);
    });
  }

  List<String> _getAllTags() {
    final tags = <String>{};
    for (final patch in _allPatches) {
      tags.addAll(patch.metadata.tags);
    }
    return tags.toList()..sort();
  }

  Future<void> _loadPatchToEditBuffer(LocalPatch patch) async {
    try {
      await widget.podController.loadPatchToHardware(patch.patch);

      if (mounted) {
        // Close the modal
        Navigator.of(context).pop();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Loaded "${patch.patch.name}" to hardware'),
            backgroundColor: PodColors.accent,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load patch: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _exportToHardwareSlot(LocalPatch patch) async {
    // Show patch grid picker
    final targetSlot = await showDialog<int>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: PodColors.background,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Export "${patch.patch.name}" to...',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: PodColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: PodColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: 32,
                  itemBuilder: (context, bankIndex) {
                    return _buildBankRow(bankIndex, (program) => Navigator.pop(context, program));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (targetSlot != null && mounted) {
      try {
        // Export the specific patch to hardware (not the edit buffer)
        await widget.podController.exportPatchToHardware(patch.patch, targetSlot);

        // Update local patch library after successful export
        widget.podController.patchLibrary.patches[targetSlot] = patch.patch.copy();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Exported "${patch.patch.name}" to slot $targetSlot'),
              backgroundColor: PodColors.accent,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Export failed: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  Future<void> _renamePatch(LocalPatch patch) async {
    final controller = TextEditingController(text: patch.patch.name);

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: PodColors.background,
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Rename Patch',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: PodColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: PodColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                maxLength: 16,
                autofocus: true,
                style: const TextStyle(color: PodColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Patch Name',
                  labelStyle: const TextStyle(color: PodColors.textSecondary),
                  filled: true,
                  fillColor: PodColors.surfaceLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  counterStyle: const TextStyle(color: PodColors.textSecondary),
                ),
                onSubmitted: (value) => Navigator.pop(context, value),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('CANCEL'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, controller.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PodColors.accent,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('RENAME'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (newName != null && newName.isNotEmpty && mounted) {
      final updatedPatch = patch.copyWith(
        patch: patch.patch..name = newName,
        metadata: patch.metadata.copyWithUpdate(),
      );

      try {
        await widget.localLibraryService.savePatch(updatedPatch);
        await _loadPatches(forceRefresh: true);

        if (_selectedPatch?.id == patch.id) {
          setState(() => _selectedPatch = updatedPatch);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Rename failed: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  Future<void> _clonePatch(LocalPatch patch) async {
    final newId = _uuid.v4();
    final clonedPatch = patch.clone(newId, '${patch.patch.name} Copy');

    try {
      await widget.localLibraryService.savePatch(clonedPatch);
      await _loadPatches(forceRefresh: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Patch cloned successfully'),
            backgroundColor: PodColors.accent,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Clone failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _deletePatch(LocalPatch patch) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PodColors.background,
        title: const Text(
          'Delete Patch?',
          style: TextStyle(color: PodColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete "${patch.patch.name}"? This cannot be undone.',
          style: const TextStyle(color: PodColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await widget.localLibraryService.deletePatch(patch.id);
        await _loadPatches(forceRefresh: true);

        if (_selectedPatch?.id == patch.id) {
          setState(() => _selectedPatch = null);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Patch deleted'),
              backgroundColor: PodColors.accent,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Delete failed: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  Future<void> _exportToFile(LocalPatch patch) async {
    try {
      // Don't include extension in fileName - it will be added automatically
      final filePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Patch',
        fileName: patch.patch.name,
        type: FileType.custom,
        allowedExtensions: ['podpatch'],
      );

      if (filePath != null) {
        // Ensure extension is added on Windows (macOS adds it automatically)
        final pathWithExtension = _ensureExtension(filePath, '.podpatch');
        await widget.localLibraryService.exportPatchToFile(patch, pathWithExtension);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Patch exported successfully'),
              backgroundColor: PodColors.accent,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Ensure file path has the correct extension (Windows doesn't add it automatically)
  String _ensureExtension(String filePath, String extension) {
    if (!filePath.toLowerCase().endsWith(extension.toLowerCase())) {
      return filePath + extension;
    }
    return filePath;
  }

  Future<void> _editMetadata(LocalPatch patch) async {
    final updatedMetadata = await showPatchMetadataEditor(
      context: context,
      initialMetadata: patch.metadata,
    );

    if (updatedMetadata != null && mounted) {
      final updatedPatch = patch.copyWith(metadata: updatedMetadata);

      try {
        await widget.localLibraryService.savePatch(updatedPatch);
        await _loadPatches(forceRefresh: true);

        if (_selectedPatch?.id == patch.id) {
          setState(() => _selectedPatch = updatedPatch);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Metadata updated'),
              backgroundColor: PodColors.accent,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Update failed: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  Future<void> _importFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['podpatch'],
      );

      if (result != null && result.files.single.path != null) {
        final patch = await widget.localLibraryService.importPatchFromFile(
          result.files.single.path!,
        );

        await widget.localLibraryService.savePatch(patch);
        await _loadPatches(forceRefresh: true);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Imported "${patch.patch.name}"'),
              backgroundColor: PodColors.accent,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showPatchActionMenu(LocalPatch patch, Offset? position) {
    showPatchActionMenu(
      context: context,
      position: position,
      config: PatchActionConfig.forLocalLibrary(
        onLoad: () => _loadPatchToEditBuffer(patch),
        onExportToSlot: () => _exportToHardwareSlot(patch),
        onRename: () => _renamePatch(patch),
        onClone: () => _clonePatch(patch),
        onDelete: () => _deletePatch(patch),
        onSaveToFile: () => _exportToFile(patch),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: PodColors.accent,
        ),
      );
    }

    if (_allPatches.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.library_music_outlined,
              size: 64,
              color: PodColors.textSecondary,
            ),
            const SizedBox(height: 16),
            const Text(
              'No patches in local library',
              style: TextStyle(
                fontFamily: 'Copperplate',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: PodColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _importFromFile,
              icon: const Icon(Icons.file_upload, size: 18),
              label: const Text('IMPORT PATCH FROM FILE'),
              style: ElevatedButton.styleFrom(
                backgroundColor: PodColors.accent,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Filter panel
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: PatchFilterPanel(
            criteria: _criteria,
            sortOrder: _sortOrder,
            availableTags: _getAllTags(),
            onCriteriaChanged: (criteria) {
              setState(() {
                _criteria = criteria;
                _applyFiltersAndSort();
              });
            },
            onSortOrderChanged: (order) {
              setState(() {
                _sortOrder = order;
                _applyFiltersAndSort();
              });
            },
          ),
        ),

        // Main content: 25% list + 75% detail
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left: Patch list (25%)
                Expanded(
                  flex: 1,
                  child: _buildPatchList(),
                ),
                const SizedBox(width: 12),

                // Right: Detail view (75%)
                Expanded(
                  flex: 3,
                  child: PatchDetailCard(
                    patch: _selectedPatch,
                    onLoadToEditBuffer: _selectedPatch != null
                        ? () => _loadPatchToEditBuffer(_selectedPatch!)
                        : null,
                    onExportToSlot: _selectedPatch != null
                        ? () => _exportToHardwareSlot(_selectedPatch!)
                        : null,
                    onEditMetadata: _selectedPatch != null
                        ? () => _editMetadata(_selectedPatch!)
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPatchList() {
    return Container(
      decoration: BoxDecoration(
        color: PodColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: PodColors.knobBase),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(4),
        itemCount: _filteredPatches.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final patch = _filteredPatches[index];
          final isSelected = patch.id == _selectedPatch?.id;

          return GestureDetector(
            onTap: () => setState(() => _selectedPatch = patch),
            // Desktop: Right-click shows context menu
            onSecondaryTapDown: (Platform.isMacOS || Platform.isWindows)
                ? (details) => _showPatchActionMenu(patch, details.globalPosition)
                : null,
            // Mobile: Long-press shows bottom sheet
            onLongPress: !(Platform.isMacOS || Platform.isWindows)
                ? () => _showPatchActionMenu(patch, null)
                : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? PodColors.accent.withValues(alpha: 0.25)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isSelected ? PodColors.accent : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      patch.patch.name,
                      style: TextStyle(
                        fontFamily: 'Copperplate',
                        fontSize: 12,
                        color: isSelected
                            ? PodColors.textPrimary
                            : PodColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (patch.metadata.favorite)
                    const Icon(
                      Icons.star,
                      color: PodColors.accent,
                      size: 12,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBankRow(int bankIndex, ValueChanged<int> onTap) {
    final bankNum = bankIndex + 1;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: List.generate(4, (slotIndex) {
          final program = bankIndex * 4 + slotIndex;
          final patch = widget.podController.patchLibrary[program];
          final letter = String.fromCharCode('A'.codeUnitAt(0) + slotIndex);
          final slotLabel = '$bankNum$letter';

          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(program),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: PodColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: PodColors.surfaceLight,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      slotLabel,
                      style: const TextStyle(
                        fontFamily: 'Copperplate',
                        color: PodColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    patch.name.isEmpty
                        ? const SizedBox(height: 12) // Empty space instead of text
                        : Text(
                            patch.name,
                            style: const TextStyle(
                              fontFamily: 'Copperplate',
                              color: PodColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
