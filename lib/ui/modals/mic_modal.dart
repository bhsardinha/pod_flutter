import 'package:flutter/material.dart';
import '../../services/pod_controller.dart';
import '../../models/cab_models.dart';
import '../theme/pod_theme.dart';

/// Simple microphone picker modal with list view and horizontal room bar
/// POD always uses positions 0-3, mic names differ based on cab type
class MicModal extends StatefulWidget {
  final List<MicModel> availableMics;
  final int currentMicPosition; // Always 0-3
  final int currentRoomValue;
  final PodController podController;
  final bool isConnected;

  const MicModal({
    super.key,
    required this.availableMics,
    required this.currentMicPosition,
    required this.currentRoomValue,
    required this.podController,
    required this.isConnected,
  });

  @override
  State<MicModal> createState() => _MicModalState();
}

class _MicModalState extends State<MicModal> {
  late int _roomValue;

  @override
  void initState() {
    super.initState();
    _roomValue = widget.currentRoomValue;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Room control section
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ROOM',
                style: PodTextStyles.labelMedium.copyWith(
                  color: PodColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              _buildRoomBar(),
            ],
          ),
        ),
        const Divider(height: 1),
        const SizedBox(height: 16),

        // Microphone list
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: widget.availableMics.length,
            itemBuilder: (context, index) {
              final mic = widget.availableMics[index];
              final isSelected = mic.position == widget.currentMicPosition;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ElevatedButton(
                  onPressed: () async {
                    // Close modal immediately
                    Navigator.of(context).pop();

                    // Then update hardware in background
                    if (widget.isConnected) {
                      widget.podController.setMicModel(mic.position);
                      await widget.podController.refreshEditBuffer();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSelected
                        ? PodColors.accent.withValues(alpha: 0.2)
                        : PodColors.surfaceLight,
                    foregroundColor: isSelected
                        ? PodColors.accent
                        : PodColors.textPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: DefaultTextStyle.of(context).style,
                            children: [
                              TextSpan(
                                text: '${mic.position.toString().padLeft(2, '0')} - ',
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: isSelected
                                      ? PodColors.accent
                                      : PodColors.textPrimary,
                                ),
                              ),
                              TextSpan(
                                text: mic.name,
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: isSelected
                                      ? PodColors.accent
                                      : PodColors.textPrimary,
                                ),
                              ),
                              if (mic.realName != null) ...[
                                TextSpan(
                                  text: ' - ${mic.realName}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w400,
                                    color: PodColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRoomBar() {
    final percentage = (_roomValue * 100 / 127).round();

    return GestureDetector(
      onTapDown: (details) => _updateRoomFromPosition(details.localPosition.dx),
      onHorizontalDragUpdate: (details) =>
          _updateRoomFromPosition(details.localPosition.dx),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: PodColors.surfaceLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: PodColors.knobBase,
            width: 1,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final fillWidth = constraints.maxWidth * (_roomValue / 127);

            return Stack(
              children: [
                // Filled portion (triangular gradient)
                ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: Container(
                    width: fillWidth,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          PodColors.accent.withValues(alpha: 0.3),
                          PodColors.accent.withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                  ),
                ),
                // Percentage text
                Center(
                  child: Text(
                    '$percentage%',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: percentage > 50
                          ? PodColors.textPrimary
                          : PodColors.textSecondary,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _updateRoomFromPosition(double x) {
    setState(() {
      // Get the render box to calculate width
      final box = context.findRenderObject() as RenderBox?;
      if (box == null) return;

      final width = box.size.width;
      final clampedX = x.clamp(0.0, width);
      final newValue = ((clampedX / width) * 127).round().clamp(0, 127);

      _roomValue = newValue;

      if (widget.isConnected) {
        widget.podController.setRoom(newValue);
      }
    });
  }
}
