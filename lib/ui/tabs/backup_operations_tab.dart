/// Backup & Restore tab - Bulk import/export operations

library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../../models/local_patch.dart';
import '../../services/local_library_service.dart';
import '../../services/pod_controller.dart';
import '../theme/pod_theme.dart';
import '../widgets/pod_modal.dart';

/// Backup and restore operations tab
class BackupOperationsTab extends StatefulWidget {
  final LocalLibraryService localLibraryService;
  final PodController podController;

  const BackupOperationsTab({
    super.key,
    required this.localLibraryService,
    required this.podController,
  });

  @override
  State<BackupOperationsTab> createState() => _BackupOperationsTabState();
}

class _BackupOperationsTabState extends State<BackupOperationsTab> {
  bool _exportingHardware = false;
  bool _exportingLibrary = false;
  bool _importing = false;
  final _uuid = const Uuid();

  Future<void> _exportAllHardwarePatches() async {
    setState(() => _exportingHardware = true);

    // Show progress modal
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
      // Import all 128 patches from hardware
      await widget.podController.importAllPatchesFromHardware();

      if (mounted) {
        Navigator.of(context).pop(); // Close progress modal

        // Prompt for save location
        final path = await FilePicker.platform.saveFile(
          dialogTitle: 'Export Hardware Patches',
          fileName: 'POD_XT_Pro_Backup.podlibrary',
          type: FileType.custom,
          allowedExtensions: ['podlibrary'],
        );

        if (path != null) {
          // Convert all patches to LocalPatch format
          final localPatches = <LocalPatch>[];
          for (var i = 0; i < 128; i++) {
            final patch = widget.podController.patchLibrary[i];
            localPatches.add(LocalPatch(
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
            ));
          }

          // Export to file
          await widget.localLibraryService.exportLibraryToFile(localPatches, path);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Hardware patches exported successfully!'),
                backgroundColor: PodColors.accent,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close progress modal
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exportingHardware = false);
    }
  }

  Future<void> _exportLocalLibrary() async {
    setState(() => _exportingLibrary = true);

    try {
      final patches = await widget.localLibraryService.loadAllPatches();

      if (patches.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Local library is empty'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
          setState(() => _exportingLibrary = false);
        }
        return;
      }

      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Local Library',
        fileName: 'My_Patches.podlibrary',
        type: FileType.custom,
        allowedExtensions: ['podlibrary'],
      );

      if (path != null) {
        await widget.localLibraryService.exportLibraryToFile(patches, path);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Exported ${patches.length} patches successfully!'),
              backgroundColor: PodColors.accent,
              duration: const Duration(seconds: 3),
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
    } finally {
      if (mounted) setState(() => _exportingLibrary = false);
    }
  }

  Future<void> _importLibraryToHardware() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['podlibrary'],
      );

      if (result == null || result.files.single.path == null) {
        return;
      }

      // Load library from file
      final patches = await widget.localLibraryService.importLibraryFromFile(
        result.files.single.path!,
      );

      if (patches.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Library file is empty'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // Confirm overwrite
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: PodColors.background,
          title: const Text(
            'Import to Hardware?',
            style: TextStyle(color: PodColors.textPrimary),
          ),
          content: Text(
            'This will overwrite the first ${patches.length} patches on your POD XT Pro. Continue?',
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
                backgroundColor: PodColors.accent,
                foregroundColor: Colors.white,
              ),
              child: const Text('IMPORT'),
            ),
          ],
        ),
      );

      if (confirmed != true || !mounted) return;

      setState(() => _importing = true);

      // Show progress
      final progressCompleter = Completer<void>();
      int currentPatch = 0;

      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: 0.7),
        builder: (context) => PodModal(
          maxWidth: 300,
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: patches.isNotEmpty ? currentPatch / patches.length : 0,
                          backgroundColor: PodColors.surfaceLight,
                          color: PodColors.accent,
                          strokeWidth: 8,
                        ),
                        Text(
                          '${(currentPatch / patches.length * 100).toStringAsFixed(0)}%',
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
                    'Importing to hardware...',
                    style: TextStyle(
                      color: PodColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$currentPatch/${patches.length} patches',
                    style: const TextStyle(
                      color: PodColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );

      try {
        // Import patches to hardware slots
        for (var i = 0; i < patches.length && i < 128; i++) {
          // Export the specific patch to hardware (not the edit buffer)
          await widget.podController.exportPatchToHardware(patches[i].patch, i);

          // Update local patch library after successful export
          widget.podController.patchLibrary.patches[i] = patches[i].patch.copy();

          currentPatch = i + 1;
          // Note: Can't update modal state directly, would need a StreamController
          await Future.delayed(const Duration(milliseconds: 50));
        }

        progressCompleter.complete();

        if (mounted) {
          Navigator.of(context).pop(); // Close progress modal
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Imported ${patches.length} patches to hardware!'),
              backgroundColor: PodColors.accent,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop(); // Close progress modal
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Import failed: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
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
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<void> _importLibraryToLocal() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['podlibrary'],
      );

      if (result == null || result.files.single.path == null) {
        return;
      }

      setState(() => _importing = true);

      // Load library from file
      final patches = await widget.localLibraryService.importLibraryFromFile(
        result.files.single.path!,
      );

      if (patches.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Library file is empty'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
          setState(() => _importing = false);
        }
        return;
      }

      // Save all patches to local library
      for (final patch in patches) {
        await widget.localLibraryService.savePatch(patch);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported ${patches.length} patches to local library!'),
            backgroundColor: PodColors.accent,
            duration: const Duration(seconds: 3),
          ),
        );
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
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Export Section
          _buildSectionHeader('Export', Icons.file_download),
          const SizedBox(height: 16),

          _buildOperationCard(
            title: 'Export All Hardware Patches',
            description: 'Import all 128 patches from POD XT Pro and save to file (~6.4 seconds)',
            icon: Icons.router,
            buttonLabel: _exportingHardware ? 'EXPORTING...' : 'EXPORT HARDWARE',
            onPressed: _exportingHardware ? null : _exportAllHardwarePatches,
            color: PodColors.accent,
          ),

          const SizedBox(height: 16),

          _buildOperationCard(
            title: 'Export Local Library',
            description: 'Save your personal patch collection to a file',
            icon: Icons.library_books,
            buttonLabel: _exportingLibrary ? 'EXPORTING...' : 'EXPORT LIBRARY',
            onPressed: _exportingLibrary ? null : _exportLocalLibrary,
            color: PodColors.surfaceLight,
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 32),

          // Import Section
          _buildSectionHeader('Import', Icons.file_upload),
          const SizedBox(height: 16),

          _buildOperationCard(
            title: 'Import to Hardware',
            description: 'Load patches from file and write to POD XT Pro slots',
            icon: Icons.router,
            buttonLabel: _importing ? 'IMPORTING...' : 'IMPORT TO HARDWARE',
            onPressed: _importing ? null : _importLibraryToHardware,
            color: PodColors.surfaceLight,
          ),

          const SizedBox(height: 16),

          _buildOperationCard(
            title: 'Import to Local Library',
            description: 'Add patches from file to your personal collection',
            icon: Icons.library_add,
            buttonLabel: _importing ? 'IMPORTING...' : 'IMPORT TO LIBRARY',
            onPressed: _importing ? null : _importLibraryToLocal,
            color: PodColors.surfaceLight,
          ),

          const SizedBox(height: 32),

          // Info box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: PodColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: PodColors.knobBase),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.info_outline, color: PodColors.accent, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'File Formats',
                      style: PodTextStyles.subheader,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '.podpatch - Single patch with metadata\n'
                  '.podlibrary - Collection of patches',
                  style: PodTextStyles.valueMedium.copyWith(
                    color: PodColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: PodColors.accent, size: 24),
        const SizedBox(width: 12),
        Text(
          title,
          style: PodTextStyles.header,
        ),
      ],
    );
  }

  Widget _buildOperationCard({
    required String title,
    required String description,
    required IconData icon,
    required String buttonLabel,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PodColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PodColors.knobBase),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: PodColors.textLabel, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: PodTextStyles.subheader,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: PodTextStyles.valueMedium.copyWith(
                        color: PodColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: color == PodColors.accent ? Colors.white : PodColors.textPrimary,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}

/// Progress modal for patch import (reused from POD Presets tab)
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
