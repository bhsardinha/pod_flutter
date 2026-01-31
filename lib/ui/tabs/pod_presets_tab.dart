/// POD Presets tab - Hardware patches grid with enhanced actions

library;

import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/pod_controller.dart';
import '../../models/local_patch.dart';
import '../../services/local_library_service.dart';
import '../theme/pod_theme.dart';
import '../widgets/patch_action_sheet.dart';
import '../widgets/pod_modal.dart';
import 'package:uuid/uuid.dart';

/// Tab showing hardware patches with action menu
class PodPresetsTab extends StatefulWidget {
  final PodController podController;
  final int currentProgram;
  final bool patchesSynced;
  final int syncedCount;
  final ValueChanged<int> onSelectPatch;
  final LocalLibraryService localLibraryService;

  const PodPresetsTab({
    super.key,
    required this.podController,
    required this.currentProgram,
    required this.patchesSynced,
    required this.syncedCount,
    required this.onSelectPatch,
    required this.localLibraryService,
  });

  @override
  State<PodPresetsTab> createState() => _PodPresetsTabState();
}

class _PodPresetsTabState extends State<PodPresetsTab> {
  bool _importing = false;
  StreamSubscription? _storeResultSubscription;
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();

    _storeResultSubscription = widget.podController.onStoreResult.listen((result) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.success
              ? 'Patch saved successfully!'
              : 'Save failed: ${result.error}'),
          backgroundColor: result.success ? PodColors.accent : Colors.red,
          duration: Duration(seconds: result.success ? 2 : 3),
        ),
      );

      if (result.success && result.patchNumber != null && mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _storeResultSubscription?.cancel();
    super.dispose();
  }

  /// Check if user has clicked IMPORT ALL and it completed (persists in controller)
  bool get _importCompleted => widget.podController.userImportedAllPatches;

  Future<void> _importAllPatches() async {
    if (!mounted) return;

    setState(() => _importing = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => _ImportProgressModal(
        podController: widget.podController,
      ),
    );

    await Future.delayed(const Duration(milliseconds: 100));

    try {
      await widget.podController.importAllPatchesFromHardware();
      if (mounted) {
        Navigator.of(context).pop();
        setState(() => _importing = false);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Import complete! All 128 patches loaded successfully.'),
            backgroundColor: PodColors.accent,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        setState(() => _importing = false);
      }
      rethrow;
    }
  }

  Future<void> _savePatchToSlot(int slotNumber, String patchName) async {
    widget.podController.editBuffer.patch.name = patchName;

    try {
      await widget.podController.savePatchToHardware(slotNumber);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _renamePatch(int patchNumber, String currentName) async {
    final controller = TextEditingController(text: currentName);

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
      try {
        await widget.podController.renamePatch(patchNumber, newName);
        setState(() {});
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

  Future<void> _copyPatchToAnotherSlot(int sourcePatchNumber) async {
    final sourcePatch = widget.podController.patchLibrary[sourcePatchNumber];

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
                    'Copy "${sourcePatch.name}" to...',
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
                child: _buildPatchGrid((program) => Navigator.pop(context, program)),
              ),
            ],
          ),
        ),
      ),
    );

    if (targetSlot != null && mounted) {
      try {
        // Export the source patch to target slot (not the edit buffer)
        await widget.podController.exportPatchToHardware(sourcePatch, targetSlot);

        // Update local patch library after successful export
        widget.podController.patchLibrary.patches[targetSlot] = sourcePatch.copy();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Copied "${sourcePatch.name}" to slot $targetSlot'),
              backgroundColor: PodColors.accent,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Copy failed: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  Future<void> _saveToLocalLibrary(int patchNumber) async {
    final patch = widget.podController.patchLibrary[patchNumber];

    final localPatch = LocalPatch(
      id: _uuid.v4(),
      patch: patch.copy(),
      metadata: PatchMetadata(
        author: '',
        description: '',
        favorite: false,
        genre: PatchGenre.unspecified,
        useCase: PatchUseCase.general,
        tags: [],
        importSource: 'hardware',
      ),
    );

    try {
      await widget.localLibraryService.savePatch(localPatch);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Patch saved to local library!'),
            backgroundColor: PodColors.accent,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save to library: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _exportPatchToFile(int patchNumber) async {
    final patch = widget.podController.patchLibrary[patchNumber];

    // Create LocalPatch with metadata
    final localPatch = LocalPatch(
      id: _uuid.v4(),
      patch: patch.copy(),
      metadata: PatchMetadata(
        author: '',
        description: '',
        favorite: false,
        genre: PatchGenre.unspecified,
        useCase: PatchUseCase.general,
        tags: [],
        importSource: 'hardware',
      ),
    );

    try {
      // Prompt for save location
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Patch',
        fileName: patch.name.isEmpty ? "Patch_$patchNumber" : patch.name,
        type: FileType.custom,
        allowedExtensions: ['podpatch'],
      );

      if (path != null) {
        await widget.localLibraryService.exportPatchToFile(localPatch, path);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Exported "${patch.name}" to file'),
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
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _importFromLocalLibrary(int targetSlot) async {
    // This would show a picker to select from local library
    // For now, show a placeholder message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Import from library - switch to Local Library tab'),
        backgroundColor: PodColors.accent,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showSaveDialog() {
    final controller = TextEditingController(
        text: widget.podController.editBuffer.patch.name);

    showDialog(
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
                  const Text(
                    'Save Current Patch',
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
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLength: 16,
                style: const TextStyle(color: PodColors.textPrimary, fontSize: 16),
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
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _buildPatchGrid((program) {
                  Navigator.pop(context);
                  _savePatchToSlot(program, controller.text);
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPatchActionMenu(int patchNumber, Offset? position) {
    // Only show action menu if IMPORT ALL has completed
    if (!_importCompleted) {
      // Show warning that patches need to be imported first
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please click "IMPORT ALL" to load patches from hardware before using patch actions.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final patch = widget.podController.patchLibrary[patchNumber];

    showPatchActionMenu(
      context: context,
      position: position,
      config: PatchActionConfig.forPodPreset(
        onRename: () => _renamePatch(patchNumber, patch.name),
        onSaveHere: () => _savePatchToSlot(patchNumber, widget.podController.editBuffer.patch.name),
        onCopyTo: () => _copyPatchToAnotherSlot(patchNumber),
        onSaveToLibrary: () => _saveToLocalLibrary(patchNumber),
        onImportFromLibrary: () => _importFromLocalLibrary(patchNumber),
        onSaveToFile: () => _exportPatchToFile(patchNumber),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Action buttons
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _importing ? null : _importAllPatches,
                  icon: const Icon(Icons.download, size: 18),
                  label: Text(_importing ? 'IMPORTING...' : 'IMPORT ALL'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PodColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showSaveDialog,
                  icon: const Icon(Icons.save, size: 18),
                  label: const Text('SAVE TO...'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PodColors.surfaceLight,
                    foregroundColor: PodColors.textPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Patch grid
        Expanded(
          child: _buildPatchGrid(widget.onSelectPatch),
        ),
      ],
    );
  }

  Widget _buildPatchGrid(ValueChanged<int> onTap) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 32, // 32 banks
      itemBuilder: (context, bankIndex) {
        return _buildBankRow(bankIndex, onTap);
      },
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
          final isSelected = program == widget.currentProgram;
          final letter = String.fromCharCode('A'.codeUnitAt(0) + slotIndex);
          final slotLabel = '$bankNum$letter';

          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(program),
              // macOS: Right-click shows context menu or warning
              onSecondaryTapDown: Platform.isMacOS
                  ? (details) => _showPatchActionMenu(program, details.globalPosition)
                  : null,
              // Mobile/Other: Long-press shows bottom sheet or warning
              onLongPress: !Platform.isMacOS
                  ? () => _showPatchActionMenu(program, null)
                  : null,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? PodColors.accent.withValues(alpha: 0.25)
                      : PodColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? PodColors.accent : PodColors.surfaceLight,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      slotLabel,
                      style: TextStyle(
                        fontFamily: 'Copperplate',
                        color: isSelected
                            ? PodColors.accent
                            : PodColors.textSecondary,
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
                            style: TextStyle(
                              fontFamily: 'Copperplate',
                              color: isSelected
                                  ? PodColors.textPrimary
                                  : PodColors.textPrimary,
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

/// Progress modal for patch import
class _ImportProgressModal extends StatefulWidget {
  final PodController podController;

  const _ImportProgressModal({
    required this.podController,
  });

  @override
  State<_ImportProgressModal> createState() => _ImportProgressModalState();
}

class _ImportProgressModalState extends State<_ImportProgressModal> {
  int _current = 0;
  int _total = 128;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = widget.podController.onSyncProgress.listen((progress) {
      if (mounted) {
        setState(() {
          _current = progress.current;
          _total = progress.total;
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final percentage =
        _total > 0 ? (_current / _total * 100).toStringAsFixed(0) : '0';

    return PodModal(
      maxWidth: 300,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: _total > 0 ? _current / _total : 0,
                    backgroundColor: PodColors.surfaceLight,
                    color: PodColors.accent,
                    strokeWidth: 8,
                  ),
                ),
                Text(
                  '$percentage%',
                  style: const TextStyle(
                    color: PodColors.accent,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Importing patches...',
            style: TextStyle(
              color: PodColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$_current/$_total patches',
            style: const TextStyle(
              color: PodColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
