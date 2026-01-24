import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/pod_controller.dart';
import '../theme/pod_theme.dart';
import '../utils/color_extensions.dart';

/// Patch list modal widget for selecting patches
class PatchListModal extends StatefulWidget {
  final PodController podController;
  final int currentProgram;
  final bool patchesSynced;
  final int syncedCount;
  final ValueChanged<int> onSelectPatch;

  const PatchListModal({
    super.key,
    required this.podController,
    required this.currentProgram,
    required this.patchesSynced,
    required this.syncedCount,
    required this.onSelectPatch,
  });

  @override
  State<PatchListModal> createState() => _PatchListModalState();
}

class _PatchListModalState extends State<PatchListModal> {
  bool _importing = false;
  String _statusMessage = '';
  StreamSubscription? _storeResultSubscription;

  @override
  void initState() {
    super.initState();
    // Listen for store results
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
    });
  }

  @override
  void dispose() {
    _storeResultSubscription?.cancel();
    super.dispose();
  }

  Future<void> _importAllPatches() async {
    setState(() {
      _importing = true;
      _statusMessage = 'Importing all patches...';
    });

    try {
      await widget.podController.importAllPatchesFromHardware();
      if (mounted) {
        setState(() {
          _importing = false;
          _statusMessage = 'Import complete!';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _importing = false;
          _statusMessage = 'Import failed: $e';
        });
      }
    }
  }

  Future<void> _savePatchToSlot(int slotNumber) async {
    try {
      await widget.podController.savePatchToHardware(slotNumber);
      // Success/failure will be shown via stream listener
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

  void _showSaveDialog(BuildContext context) {
    // Show dialog to select slot number
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PodColors.surface,
        title: const Text(
          'Save Current Patch',
          style: TextStyle(color: PodColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select slot to save current patch:',
              style: TextStyle(color: PodColors.textSecondary),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              width: double.maxFinite,
              child: ListView.builder(
                itemCount: 128,
                itemBuilder: (context, index) {
                  final patch = widget.podController.patchLibrary[index];
                  return ListTile(
                    title: Text(
                      '${index.toString().padLeft(3, '0')}: ${patch.name.isEmpty ? "(empty)" : patch.name}',
                      style: const TextStyle(color: PodColors.textPrimary),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _savePatchToSlot(index);
                    },
                  );
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Action buttons row
    final actionButtons = Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _importing ? null : _importAllPatches,
              icon: const Icon(Icons.download, size: 16),
              label: Text(_importing ? 'Importing...' : 'Import All'),
              style: ElevatedButton.styleFrom(
                backgroundColor: PodColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showSaveDialog(context),
              icon: const Icon(Icons.save, size: 16),
              label: const Text('Save To...'),
              style: ElevatedButton.styleFrom(
                backgroundColor: PodColors.surfaceLight,
                foregroundColor: PodColors.textPrimary,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );

    // Show sync progress if not complete
    if (!widget.patchesSynced && widget.syncedCount < 128) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          actionButtons,
          const SizedBox(height: 20),
          CircularProgressIndicator(
            value: widget.syncedCount / 128,
            backgroundColor: PodColors.surfaceLight,
            color: PodColors.accent,
          ),
          const SizedBox(height: 16),
          Text(
            'Syncing patches... ${widget.syncedCount}/128',
            style: const TextStyle(
              color: PodColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
        ],
      );
    }

    // Group patches by bank (32 banks, 4 patches each)
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        actionButtons,
        if (_statusMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              _statusMessage,
              style: const TextStyle(
                color: PodColors.accent,
                fontSize: 12,
              ),
            ),
          ),
        SizedBox(
          height: 400,
          child: ListView.builder(
            itemCount: 32, // 32 banks
            itemBuilder: (context, bankIndex) {
              final bankNum = bankIndex + 1;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bank header
                  Padding(
                    padding: const EdgeInsets.only(left: 8, top: 12, bottom: 4),
                    child: Text(
                      'Bank ${bankNum.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        color: PodColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // 4 patches per bank (A, B, C, D)
                  Row(
                    children: List.generate(4, (slotIndex) {
                      final program = bankIndex * 4 + slotIndex;
                      final patch = widget.podController.patchLibrary[program];
                      final isSelected = program == widget.currentProgram;
                      final letter = String.fromCharCode(
                        'A'.codeUnitAt(0) + slotIndex,
                      );

                      return Expanded(
                        child: GestureDetector(
                          onTap: () => widget.onSelectPatch(program),
                          child: Container(
                            margin: const EdgeInsets.all(2),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? PodColors.accent.withValues(alpha: 0.2)
                                  : PodColors.surfaceLight,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isSelected
                                    ? PodColors.accent
                                    : PodColors.surfaceLight,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Program number
                                Text(
                                  letter,
                                  style: TextStyle(
                                    color: isSelected
                                        ? PodColors.accent
                                        : PodColors.textSecondary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                // Patch name
                                Text(
                                  patch.name.isEmpty ? '(empty)' : patch.name,
                                  style: TextStyle(
                                    color: isSelected
                                        ? PodColors.textPrimary
                                        : patch.name.isEmpty
                                            ? PodColors.textSecondary
                                            : PodColors.textPrimary,
                                    fontSize: 11,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}