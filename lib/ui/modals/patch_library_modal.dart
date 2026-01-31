/// Tabbed patch library modal - replaces old patch_list_modal.dart
/// Two tabs: POD Presets | Local Library

library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../../models/local_patch.dart';
import '../../services/pod_controller.dart';
import '../../services/local_library_service.dart';
import '../theme/pod_theme.dart';
import '../widgets/pod_modal.dart';
import '../tabs/pod_presets_tab.dart';
import '../tabs/local_library_tab.dart';

/// Main patch library modal with tabs
class PatchLibraryModal extends StatefulWidget {
  final PodController podController;
  final int currentProgram;
  final bool patchesSynced;
  final int syncedCount;
  final ValueChanged<int> onSelectPatch;

  const PatchLibraryModal({
    super.key,
    required this.podController,
    required this.currentProgram,
    required this.patchesSynced,
    required this.syncedCount,
    required this.onSelectPatch,
  });

  @override
  State<PatchLibraryModal> createState() => _PatchLibraryModalState();
}

class _PatchLibraryModalState extends State<PatchLibraryModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late LocalLibraryService _localLibraryService;
  bool _libraryInitialized = false;
  VoidCallback? _refreshLocalLibrary;

  @override
  void initState() {
    super.initState();
    // Initialize tab controller - always opens on POD Presets tab (index 0)
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: 0,
    );

    _initializeLibraryService();
  }

  Future<void> _initializeLibraryService() async {
    _localLibraryService = LocalLibraryService();

    try {
      await _localLibraryService.initialize();
      setState(() => _libraryInitialized = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initialize local library: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Single Patch Operations
  Future<void> _importPatchFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['podpatch'],
      );

      if (result != null && result.files.single.path != null) {
        final patch = await _localLibraryService.importPatchFromFile(
          result.files.single.path!,
        );

        await _localLibraryService.savePatch(patch);

        if (mounted) {
          // Switch to local library tab to show the imported patch
          _tabController.animateTo(1);

          // Trigger refresh of LocalLibraryTab
          _refreshLocalLibrary?.call();

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

  // Export Operations
  Future<void> _exportAllHardwarePatches() async {
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
          const uuid = Uuid();
          final localPatches = <LocalPatch>[];
          for (var i = 0; i < 128; i++) {
            final patch = widget.podController.patchLibrary[i];
            localPatches.add(LocalPatch(
              id: uuid.v4(),
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
          await _localLibraryService.exportLibraryToFile(localPatches, path);

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
    }
  }

  Future<void> _exportLocalLibrary() async {
    try {
      final patches = await _localLibraryService.loadAllPatches();

      if (patches.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Local library is empty'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
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
        await _localLibraryService.exportLibraryToFile(patches, path);

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
    }
  }

  // Import Operations
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
      final patches = await _localLibraryService.importLibraryFromFile(
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

      // Show progress
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
          await Future.delayed(const Duration(milliseconds: 50));
        }

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

      // Load library from file
      final patches = await _localLibraryService.importLibraryFromFile(
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

      // Save all patches to local library
      for (final patch in patches) {
        await _localLibraryService.savePatch(patch);
      }

      if (mounted) {
        // Switch to local library tab to show the imported patches
        _tabController.animateTo(1);

        // Trigger refresh of LocalLibraryTab
        _refreshLocalLibrary?.call();

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
    }
  }

  void _showOperationsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: PodColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Single Patch Section
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Single Patch',
                  style: TextStyle(
                    fontFamily: 'Copperplate',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: PodColors.textSecondary,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.file_upload, color: PodColors.accent, size: 20),
                title: const Text(
                  'Import Patch (.podpatch)',
                  style: TextStyle(color: PodColors.textPrimary, fontSize: 14),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _importPatchFromFile();
                },
              ),
              const Divider(height: 1),

              // Export Section
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Export',
                  style: TextStyle(
                    fontFamily: 'Copperplate',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: PodColors.textSecondary,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.router, color: PodColors.accent, size: 20),
                title: const Text(
                  'Export All Hardware Patches',
                  style: TextStyle(color: PodColors.textPrimary, fontSize: 14),
                ),
                subtitle: const Text(
                  'Import from POD and save to file (~6.4s)',
                  style: TextStyle(color: PodColors.textSecondary, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _exportAllHardwarePatches();
                },
              ),
              ListTile(
                leading: const Icon(Icons.library_books, color: PodColors.accent, size: 20),
                title: const Text(
                  'Export Local Library',
                  style: TextStyle(color: PodColors.textPrimary, fontSize: 14),
                ),
                subtitle: const Text(
                  'Save your collection to file',
                  style: TextStyle(color: PodColors.textSecondary, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _exportLocalLibrary();
                },
              ),
              const Divider(height: 1),

              // Import Section
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Import',
                  style: TextStyle(
                    fontFamily: 'Copperplate',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: PodColors.textSecondary,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.router, color: PodColors.accent, size: 20),
                title: const Text(
                  'Import to Hardware',
                  style: TextStyle(color: PodColors.textPrimary, fontSize: 14),
                ),
                subtitle: const Text(
                  'Load from file and write to POD slots',
                  style: TextStyle(color: PodColors.textSecondary, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _importLibraryToHardware();
                },
              ),
              ListTile(
                leading: const Icon(Icons.library_add, color: PodColors.accent, size: 20),
                title: const Text(
                  'Import to Local Library',
                  style: TextStyle(color: PodColors.textPrimary, fontSize: 14),
                ),
                subtitle: const Text(
                  'Add patches from file to your collection',
                  style: TextStyle(color: PodColors.textSecondary, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _importLibraryToLocal();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: PodColors.background,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: PodColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: PodColors.knobBase, width: 2),
        ),
        child: Column(
          children: [
            // Header with title and close button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: PodColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'PATCH LIBRARY',
                    style: PodTextStyles.header,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Show menu button on all tabs
                      IconButton(
                        icon: const Icon(Icons.menu, color: PodColors.textSecondary),
                        onPressed: _showOperationsMenu,
                        tooltip: 'Import/Export',
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: PodColors.textSecondary),
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Tab bar
            Container(
              color: PodColors.surface,
              child: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.router, size: 20),
                    text: 'POD PRESETS',
                  ),
                  Tab(
                    icon: Icon(Icons.library_music, size: 20),
                    text: 'LOCAL LIBRARY',
                  ),
                ],
                labelColor: PodColors.accent,
                unselectedLabelColor: PodColors.textSecondary,
                labelStyle: PodTextStyles.labelLarge,
                unselectedLabelStyle: PodTextStyles.labelMedium,
                indicatorColor: PodColors.accent,
                indicatorWeight: 3,
              ),
            ),

            const Divider(height: 1),

            // Tab views
            Expanded(
              child: _libraryInitialized
                  ? TabBarView(
                      controller: _tabController,
                      children: [
                        // Tab 1: POD Presets
                        PodPresetsTab(
                          podController: widget.podController,
                          currentProgram: widget.currentProgram,
                          patchesSynced: widget.patchesSynced,
                          syncedCount: widget.syncedCount,
                          onSelectPatch: widget.onSelectPatch,
                          localLibraryService: _localLibraryService,
                        ),

                        // Tab 2: Local Library
                        LocalLibraryTab(
                          localLibraryService: _localLibraryService,
                          podController: widget.podController,
                          onRefreshCallback: (callback) => _refreshLocalLibrary = callback,
                        ),
                      ],
                    )
                  : const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            color: PodColors.accent,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Initializing local library...',
                            style: PodTextStyles.valueMedium,
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
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
