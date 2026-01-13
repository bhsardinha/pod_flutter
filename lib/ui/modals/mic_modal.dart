import 'package:flutter/material.dart';
import '../../services/pod_controller.dart';
import '../../models/cab_models.dart';
import '../theme/pod_theme.dart';
import '../widgets/rotary_knob.dart';

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
          // Room knob control
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: RotaryKnob(
                label: 'ROOM',
                value: _roomValue,
                minValue: 0,
                maxValue: 127,
                onValueChanged: (value) {
                  setState(() => _roomValue = value);
                  if (widget.isConnected) {
                    widget.podController.setRoom(value);
                  }
                },
                valueFormatter: (value) => '${(value * 100 / 127).round()}%',
              ),
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 16),
          // Microphone grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 2.35,
                ),
                itemCount: widget.availableMics.length,
                itemBuilder: (context, index) {
                  final mic = widget.availableMics[index];
                  final isSelected = mic.position == widget.currentMicPosition;

                  return GestureDetector(
                    onTap: () async {
                      if (widget.isConnected) {
                        // Position is always 0-3
                        widget.podController.setMicModel(mic.position);
                        // Request edit buffer from hardware to get default parameter values
                        await widget.podController.refreshEditBuffer();
                      }
                      if (context.mounted) Navigator.of(context).pop();
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
                              mic.name,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 18,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: isSelected ? PodColors.accent : PodColors.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (mic.realName != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                mic.realName!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: PodColors.textSecondary.withValues(alpha: 0.8),
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
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
