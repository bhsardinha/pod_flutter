import 'package:flutter/material.dart';
import '../theme/pod_theme.dart';
import '../widgets/effect_button.dart';

/// Effects columns section widget.
///
/// Displays three columns:
/// - Left: STOMP, EQ, COMP buttons
/// - Center: EQ section (passed as child)
/// - Right: MOD, DELAY, REVERB buttons
///
/// This is a drop-in replacement for _buildRow3() from main_screen_backup.dart.
class EffectsColumnsSection extends StatelessWidget {
  // Effect states
  final bool stompEnabled;
  final bool eqEnabled;
  final bool compEnabled;
  final bool modEnabled;
  final bool delayEnabled;
  final bool reverbEnabled;

  // Model names
  final String? stompModel;
  final String? modModel;
  final String? delayModel;
  final String? reverbModel;

  // Callbacks for STOMP
  final VoidCallback onStompToggle;
  final VoidCallback onStompLongPress;

  // Callbacks for EQ
  final VoidCallback onEqToggle;
  final VoidCallback onEqLongPress;

  // Callbacks for COMP
  final VoidCallback onCompToggle;
  final VoidCallback onCompLongPress;

  // Callbacks for MOD
  final VoidCallback onModToggle;
  final VoidCallback onModLongPress;

  // Callbacks for DELAY
  final VoidCallback onDelayToggle;
  final VoidCallback onDelayLongPress;

  // Callbacks for REVERB
  final VoidCallback onReverbToggle;
  final VoidCallback onReverbLongPress;

  // EQ section widget (composed as child)
  final Widget eqSection;

  const EffectsColumnsSection({
    super.key,
    required this.stompEnabled,
    required this.eqEnabled,
    required this.compEnabled,
    required this.modEnabled,
    required this.delayEnabled,
    required this.reverbEnabled,
    this.stompModel,
    this.modModel,
    this.delayModel,
    this.reverbModel,
    required this.onStompToggle,
    required this.onStompLongPress,
    required this.onEqToggle,
    required this.onEqLongPress,
    required this.onCompToggle,
    required this.onCompLongPress,
    required this.onModToggle,
    required this.onModLongPress,
    required this.onDelayToggle,
    required this.onDelayLongPress,
    required this.onReverbToggle,
    required this.onReverbLongPress,
    required this.eqSection,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left effects column (flex 4)
        Expanded(
          flex: 4,
          child: Column(
            children: [
              Expanded(
                child: EffectButton(
                  label: 'STOMP',
                  modelName: stompModel,
                  isOn: stompEnabled,
                  onTap: onStompToggle,
                  onLongPress: onStompLongPress,
                  color: PodColors.buttonOnGreen,
                  labelFontSize: 16,
                  useDynamicLabelSize: true,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: EffectButton(
                  label: 'EQ',
                  isOn: eqEnabled,
                  onTap: onEqToggle,
                  onLongPress: onEqLongPress,
                  color: PodColors.buttonOnAmber,
                  labelFontSize: 16,
                  useDynamicLabelSize: true,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: EffectButton(
                  label: 'COMP',
                  isOn: compEnabled,
                  onTap: onCompToggle,
                  onLongPress: onCompLongPress,
                  color: PodColors.buttonOnGreen,
                  labelFontSize: 16,
                  useDynamicLabelSize: true,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),

        // Center EQ section (flex 8)
        Expanded(flex: 8, child: eqSection),
        const SizedBox(width: 12),

        // Right effects column (flex 4)
        Expanded(
          flex: 4,
          child: Column(
            children: [
              Expanded(
                child: EffectButton(
                  label: 'MOD',
                  modelName: modModel,
                  isOn: modEnabled,
                  onTap: onModToggle,
                  onLongPress: onModLongPress,
                  color: PodColors.buttonOnGreen,
                  labelFontSize: 16,
                  useDynamicLabelSize: true,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: EffectButton(
                  label: 'DELAY',
                  modelName: delayModel,
                  isOn: delayEnabled,
                  onTap: onDelayToggle,
                  onLongPress: onDelayLongPress,
                  color: PodColors.buttonOnGreen,
                  labelFontSize: 16,
                  useDynamicLabelSize: true,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: EffectButton(
                  label: 'REVERB',
                  modelName: reverbModel,
                  isOn: reverbEnabled,
                  onTap: onReverbToggle,
                  onLongPress: onReverbLongPress,
                  color: PodColors.buttonOnGreen,
                  labelFontSize: 16,
                  useDynamicLabelSize: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
