import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/pod_controller.dart';
import '../theme/pod_theme.dart';

/// Patch list modal for selecting and managing patches
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
  StreamSubscription? _storeResultSubscription;

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
    });
  }

  @override
  void dispose() {
    _storeResultSubscription?.cancel();
    super.dispose();
  }

  Future<void> _importAllPatches() async {
    setState(() => _importing = true);
    try {
      await widget.podController.importAllPatchesFromHardware();
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<void> _savePatchToSlot(int slotNumber) async {
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

  void _showSaveDialog() {
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
              Expanded(
                child: _buildPatchGrid((program) {
                  Navigator.pop(context);
                  _savePatchToSlot(program);
                }),
              ),
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
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'PATCHES',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: PodColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: PodColors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Action buttons
            Row(
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
            const SizedBox(height: 16),

            // Main content
            Expanded(
              child: _importing || (!widget.patchesSynced && widget.syncedCount < 128)
                  ? _buildImportProgress()
                  : _buildPatchGrid(widget.onSelectPatch),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportProgress() {
    final percentage = ((widget.syncedCount / 128) * 100).toStringAsFixed(0);

    return Center(
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
                    value: widget.syncedCount / 128,
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
            '${widget.syncedCount}/128 patches',
            style: const TextStyle(
              color: PodColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatchGrid(ValueChanged<int> onTap) {
    return ListView.builder(
      itemCount: 32, // 32 banks
      itemBuilder: (context, bankIndex) {
        return _buildBankRow(bankIndex, onTap);
      },
    );
  }

  Widget _buildBankRow(int bankIndex, ValueChanged<int> onTap) {
    final bankNum = bankIndex + 1;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bank label
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              'BANK ${bankNum.toString().padLeft(2, '0')}',
              style: const TextStyle(
                color: PodColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
          ),
          // 4 patches (A, B, C, D)
          Row(
            children: List.generate(4, (slotIndex) {
              final program = bankIndex * 4 + slotIndex;
              final patch = widget.podController.patchLibrary[program];
              final isSelected = program == widget.currentProgram;
              final letter = String.fromCharCode('A'.codeUnitAt(0) + slotIndex);

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
                      color: isSelected
                          ? PodColors.accent.withValues(alpha: 0.25)
                          : PodColors.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? PodColors.accent
                            : PodColors.surfaceLight,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Slot letter
                        Text(
                          letter,
                          style: TextStyle(
                            color: isSelected
                                ? PodColors.accent
                                : PodColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Patch name with dynamic font sizing
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            patch.name.isEmpty ? '(empty)' : patch.name,
                            style: TextStyle(
                              color: isSelected
                                  ? PodColors.textPrimary
                                  : patch.name.isEmpty
                                      ? PodColors.textSecondary.withValues(alpha: 0.6)
                                      : PodColors.textPrimary,
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.visible,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
