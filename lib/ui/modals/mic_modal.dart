import 'package:flutter/material.dart';
import '../../services/pod_controller.dart';
import '../../models/cab_models.dart';
import '../theme/pod_theme.dart';

/// Microphone picker modal with room percentage control
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
    return SizedBox(
      height: 400,
      child: Column(
        children: [
          // Room percentage control
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('ROOM', style: PodTextStyles.labelMedium),
                    Text(
                      '${(_roomValue * 100 / 127).round()}%',
                      style: PodTextStyles.valueMedium.copyWith(
                        color: PodColors.accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Slider(
                  value: _roomValue.toDouble(),
                  min: 0,
                  max: 127,
                  divisions: 127,
                  onChanged: (value) {
                    setState(() => _roomValue = value.toInt());
                    if (widget.isConnected) {
                      widget.podController.setRoom(value.toInt());
                    }
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 8),
          // Microphone list
          Expanded(
            child: ListView.builder(
              itemCount: widget.availableMics.length,
              itemBuilder: (context, index) {
                final mic = widget.availableMics[index];
                final isSelected = mic.position == widget.currentMicPosition;

                return Padding(
                  padding: const EdgeInsets.only(
                    bottom: 8,
                    left: 16,
                    right: 16,
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      if (widget.isConnected) {
                        // Position is always 0-3
                        widget.podController.setMicModel(mic.position);
                      }
                      Navigator.of(context).pop();
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
                    child: Text(
                      mic.name,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
