import 'package:flutter/material.dart';
import '../../services/pod_controller.dart';
import '../../models/cab_models.dart';
import '../theme/pod_theme.dart';

/// Cabinet picker modal
class CabModal extends StatelessWidget {
  final int currentCabId;
  final PodController podController;
  final bool isConnected;

  const CabModal({
    super.key,
    required this.currentCabId,
    required this.podController,
    required this.isConnected,
  });

  @override
  Widget build(BuildContext context) {
    // Separate standard and BX cabs
    final standardCabs = CabModels.all
        .where((cab) => cab.pack != 'BX')
        .toList();
    final bxCabs = CabModels.all.where((cab) => cab.pack == 'BX').toList();

    return Dialog(
      backgroundColor: PodColors.background,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        child: Column(
        children: [
          // Header with title and close button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Select Cabinet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: PodColors.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.close,
                  color: PodColors.textSecondary,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Cabinet list
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Standard Cabinets Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: Text(
                      'GUITAR CABINETS',
                      style: PodTextStyles.labelMedium.copyWith(
                        color: PodColors.accent,
                      ),
                    ),
                  ),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      childAspectRatio: 2.35,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: standardCabs.length,
                    itemBuilder: (context, index) {
                      final cab = standardCabs[index];
                      final isSelected = cab.id == currentCabId;
                      return _buildCabButton(context, cab, isSelected);
                    },
                  ),

                  // Divider
                  const SizedBox(height: 16),
                  const Divider(height: 1, thickness: 2),
                  const SizedBox(height: 16),

                  // BX Cabinets Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: Row(
                      children: [
                        Text(
                          'BASS CABINETS',
                          style: PodTextStyles.labelMedium.copyWith(
                            color: PodColors.accent,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: PodColors.accent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Text(
                            'BX',
                            style: TextStyle(fontSize: 10, color: PodColors.accent),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      childAspectRatio: 2.35,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: bxCabs.length,
                    itemBuilder: (context, index) {
                      final cab = bxCabs[index];
                      final isSelected = cab.id == currentCabId;
                      return _buildCabButton(context, cab, isSelected);
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildCabButton(BuildContext context, CabModel cab, bool isSelected) {
    return GestureDetector(
      onTap: () {
        if (isConnected) {
          podController.setCabModel(cab.id);
        }
        Navigator.of(context).pop();
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? PodColors.accent.withValues(alpha: 0.3)
              : PodColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? PodColors.accent : PodColors.knobBase,
            width: isSelected ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.all(6),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                cab.name,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? PodColors.accent : PodColors.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (cab.realName != null) ...[
                const SizedBox(height: 2),
                Text(
                  cab.realName!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.w300,
                    color: PodColors.textSecondary.withValues(alpha: 0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
