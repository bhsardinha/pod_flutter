/// Tabbed patch library modal - replaces old patch_list_modal.dart
/// Three tabs: POD Presets | Local Library | Backup & Restore

library;

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/pod_controller.dart';
import '../../services/local_library_service.dart';
import '../theme/pod_theme.dart';
import '../tabs/pod_presets_tab.dart';
import '../tabs/local_library_tab.dart';
import '../tabs/backup_operations_tab.dart';

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
      length: 3,
      vsync: this,
      initialIndex: 0,
    );
    _tabController.addListener(_onTabChanged);

    _initializeLibraryService();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() {}); // Rebuild to show/hide menu button
    }
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
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

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

  Future<void> _exportAllPatchesToFile() async {
    try {
      final patches = await _localLibraryService.loadAllPatches();

      if (patches.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No patches to export'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Export All Patches',
        fileName: 'pod_library_backup',
        type: FileType.custom,
        allowedExtensions: ['podlibrary'],
      );

      if (path != null) {
        await _localLibraryService.exportLibraryToFile(patches, path);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Exported ${patches.length} patches successfully'),
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

  Future<void> _importLibraryFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['podlibrary'],
      );

      if (result != null && result.files.single.path != null) {
        final patches = await _localLibraryService.importLibraryFromFile(
          result.files.single.path!,
        );

        // Save all imported patches
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
              content: Text('Imported ${patches.length} patches from library'),
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

  void _showLocalLibraryMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: PodColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Bulk Library',
                style: TextStyle(
                  fontFamily: 'Copperplate',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: PodColors.textSecondary,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.upload_file, color: PodColors.accent, size: 20),
              title: const Text(
                'Import Library (.podlibrary)',
                style: TextStyle(color: PodColors.textPrimary, fontSize: 14),
              ),
              onTap: () {
                Navigator.pop(context);
                _importLibraryFromFile();
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_download, color: PodColors.accent, size: 20),
              title: const Text(
                'Export All Patches (.podlibrary)',
                style: TextStyle(color: PodColors.textPrimary, fontSize: 14),
              ),
              onTap: () {
                Navigator.pop(context);
                _exportAllPatchesToFile();
              },
            ),
            const SizedBox(height: 8),
          ],
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
                      // Show menu button only on Local Library tab
                      if (_tabController.index == 1)
                        IconButton(
                          icon: const Icon(Icons.menu, color: PodColors.textSecondary),
                          onPressed: _showLocalLibraryMenu,
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
                  Tab(
                    icon: Icon(Icons.backup, size: 20),
                    text: 'BACKUP',
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

                        // Tab 3: Backup & Restore
                        BackupOperationsTab(
                          localLibraryService: _localLibraryService,
                          podController: widget.podController,
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
