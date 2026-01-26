import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/pod_controller.dart';
import '../theme/pod_theme.dart';
import '../widgets/pod_modal.dart';

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

      // Show success/failure feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.success
            ? 'Patch saved successfully!'
            : 'Save failed: ${result.error}'),
          backgroundColor: result.success ? PodColors.accent : Colors.red,
          duration: Duration(seconds: result.success ? 2 : 3),
        ),
      );

      // Update UI to show updated patch in the specific slot
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

  Future<void> _importAllPatches() async {
    if (!mounted) return;

    setState(() => _importing = true);

    // Show progress modal first, before starting import
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => _ImportProgressModal(
        podController: widget.podController,
      ),
    );

    // Small delay to ensure modal is ready
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      // Now start the import
      await widget.podController.importAllPatchesFromHardware();
      if (mounted) Navigator.of(context).pop(); // Close progress modal
    } catch (e) {
      if (mounted) Navigator.of(context).pop(); // Close progress modal
      rethrow;
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<void> _savePatchToSlot(int slotNumber, String patchName) async {
    // Update patch name in edit buffer before saving
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

  void _showSaveDialog() {
    final controller = TextEditingController(text: widget.podController.editBuffer.patch.name);

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
              // Editable patch name field
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
                }, isRenameMode: false),
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
              child: _buildPatchGrid(widget.onSelectPatch, isRenameMode: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatchGrid(ValueChanged<int> onTap, {required bool isRenameMode}) {
    return ListView.builder(
      itemCount: 32, // 32 banks
      itemBuilder: (context, bankIndex) {
        return _buildBankRow(bankIndex, onTap, isRenameMode: isRenameMode);
      },
    );
  }

  Widget _buildBankRow(int bankIndex, ValueChanged<int> onTap, {required bool isRenameMode}) {
    final bankNum = bankIndex + 1;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: List.generate(4, (slotIndex) {
          final program = bankIndex * 4 + slotIndex;
          final patch = widget.podController.patchLibrary[program];
          final isSelected = program == widget.currentProgram;
          final letter = String.fromCharCode('A'.codeUnitAt(0) + slotIndex);
          final slotLabel = '$bankNum$letter'; // e.g., "1A", "32D"

          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(program),
              onLongPress: isRenameMode ? () => _renamePatch(program, patch.name) : null,
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
                    // Bank+Slot label (e.g., "1A", "32D")
                    Text(
                      slotLabel,
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
    );
  }
}

/// Small progress modal that overlays during patch import
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
    // Listen to sync progress stream
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
    final percentage = _total > 0 ? (_current / _total * 100).toStringAsFixed(0) : '0';

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
