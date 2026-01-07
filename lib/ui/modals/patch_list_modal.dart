import 'package:flutter/material.dart';
import '../../services/pod_controller.dart';
import '../theme/pod_theme.dart';

/// Patch list modal widget for selecting patches
class PatchListModal extends StatelessWidget {
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
  Widget build(BuildContext context) {
    // Show sync progress if not complete
    if (!patchesSynced && syncedCount < 128) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),
          CircularProgressIndicator(
            value: syncedCount / 128,
            backgroundColor: PodColors.surfaceLight,
            color: PodColors.accent,
          ),
          const SizedBox(height: 16),
          Text(
            'Syncing patches... $syncedCount/128',
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
    return SizedBox(
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
                  final patch = podController.patchLibrary[program];
                  final isSelected = program == currentProgram;
                  final letter = String.fromCharCode(
                    'A'.codeUnitAt(0) + slotIndex,
                  );

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onSelectPatch(program),
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
    );
  }
}
