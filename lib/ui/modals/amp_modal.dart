import 'package:flutter/material.dart';
import '../../services/pod_controller.dart';
import '../../models/app_settings.dart';
import '../../models/amp_models.dart';
import '../../protocol/cc_map.dart';
import '../theme/pod_theme.dart';

/// Amp picker modal with list and tiles view modes
class AmpModal extends StatefulWidget {
  final PodController podController;
  final AppSettings settings;
  final bool ampChainLinked;
  final bool initialTilesView;
  final double initialListScrollPosition;
  final double initialTilesScrollPosition;
  final ValueChanged<bool> onViewModeChanged;
  final void Function(double listPos, double tilesPos) onScrollPositionChanged;

  const AmpModal({
    super.key,
    required this.podController,
    required this.settings,
    required this.ampChainLinked,
    required this.initialTilesView,
    required this.initialListScrollPosition,
    required this.initialTilesScrollPosition,
    required this.onViewModeChanged,
    required this.onScrollPositionChanged,
  });

  @override
  State<AmpModal> createState() => _AmpModalState();
}

class _AmpModalState extends State<AmpModal> {
  late bool _isTilesView;
  late ScrollController _listScrollController;
  late ScrollController _gridScrollController;

  @override
  void initState() {
    super.initState();
    _isTilesView = widget.initialTilesView;

    // Initialize controllers with saved positions
    _listScrollController = ScrollController(
      initialScrollOffset: widget.initialListScrollPosition,
    );
    _gridScrollController = ScrollController(
      initialScrollOffset: widget.initialTilesScrollPosition,
    );
  }

  @override
  void dispose() {
    // Save current scroll positions before disposing
    final listPos = _listScrollController.hasClients
        ? _listScrollController.offset
        : widget.initialListScrollPosition;
    final tilesPos = _gridScrollController.hasClients
        ? _gridScrollController.offset
        : widget.initialTilesScrollPosition;

    // Schedule callback after dispose to avoid setState during dispose
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onScrollPositionChanged(listPos, tilesPos);
    });

    _listScrollController.dispose();
    _gridScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentAmpId = widget.podController.getParameter(PodXtCC.ampSelect);

    return Dialog(
      backgroundColor: PodColors.background,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header with title and view toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Amp Model',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: PodColors.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.view_list,
                        color: !_isTilesView
                            ? PodColors.accent
                            : PodColors.textSecondary,
                      ),
                      onPressed: () {
                        setState(() => _isTilesView = false);
                        widget.onViewModeChanged(false);
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.grid_view,
                        color: _isTilesView
                            ? PodColors.accent
                            : PodColors.textSecondary,
                      ),
                      onPressed: () {
                        setState(() => _isTilesView = true);
                        widget.onViewModeChanged(true);
                      },
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
              ],
            ),
            const SizedBox(height: 16),
            // Amp list/grid
            Expanded(
              child: _isTilesView
                  ? _buildTilesView(currentAmpId)
                  : _buildListView(currentAmpId),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView(int currentAmpId) {
    return ListView.builder(
      controller: _listScrollController,
      itemCount: AmpModels.all.length,
      itemBuilder: (context, index) {
        final amp = AmpModels.all[index];
        final isSelected = amp.id == currentAmpId;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ElevatedButton(
            onPressed: () async {
              // Use chain link setting to determine which method to use
              if (widget.ampChainLinked) {
                await widget.podController.setAmpModel(amp.id);
              } else {
                await widget.podController.setAmpModelNoDefaults(amp.id);
              }
              // Request updated parameters from POD
              await widget.podController.refreshEditBuffer();
              if (context.mounted) Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isSelected
                  ? PodColors.accent.withValues(alpha: 0.2)
                  : PodColors.surfaceLight,
              foregroundColor: isSelected
                  ? PodColors.accent
                  : PodColors.textPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style,
                      children: [
                        TextSpan(
                          text: '${amp.id.toString().padLeft(2, '0')} - ',
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? PodColors.accent : PodColors.textPrimary,
                          ),
                        ),
                        TextSpan(
                          text: amp.name,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? PodColors.accent : PodColors.textPrimary,
                          ),
                        ),
                        if (amp.realName != null) ...[
                          TextSpan(
                            text: ' - ${amp.realName}',
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
                if (amp.pack != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getPackColor(amp.pack!).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      amp.pack!,
                      style: TextStyle(
                        fontSize: 10,
                        color: _getPackColor(amp.pack!),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTilesView(int currentAmpId) {
    // Separate amps by pack
    final stockAmps = AmpModels.all.where((amp) => amp.pack == null).toList();
    final msAmps = AmpModels.all.where((amp) => amp.pack == 'MS').toList();
    final ccAmps = AmpModels.all.where((amp) => amp.pack == 'CC').toList();
    final bxAmps = AmpModels.all.where((amp) => amp.pack == 'BX').toList();

    return SingleChildScrollView(
      controller: _gridScrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stock Amps Section
          _buildPackSection(
            'STOCK MODELS',
            stockAmps,
            currentAmpId,
            PodColors.accent,
            null,
          ),

          // Metal Shop Section
          if (msAmps.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1, thickness: 2),
            const SizedBox(height: 16),
            _buildPackSection(
              'METAL SHOP',
              msAmps,
              currentAmpId,
              Colors.red,
              'MS',
            ),
          ],

          // Collector's Classic Section
          if (ccAmps.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1, thickness: 2),
            const SizedBox(height: 16),
            _buildPackSection(
              'COLLECTOR\'S CLASSIC',
              ccAmps,
              currentAmpId,
              Colors.blue,
              'CC',
            ),
          ],

          // Bass Expansion Section
          if (bxAmps.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1, thickness: 2),
            const SizedBox(height: 16),
            _buildPackSection(
              'BASS EXPANSION',
              bxAmps,
              currentAmpId,
              Colors.green,
              'BX',
            ),
          ],

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPackSection(
    String title,
    List<AmpModel> amps,
    int currentAmpId,
    Color packColor,
    String? packBadge,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Text(
                title,
                style: PodTextStyles.labelMedium.copyWith(color: packColor),
              ),
              if (packBadge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: packColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    packBadge,
                    style: TextStyle(fontSize: 10, color: packColor),
                  ),
                ),
              ],
            ],
          ),
        ),
        // Grid of amps
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2.35,
          ),
          itemCount: amps.length,
          itemBuilder: (context, index) {
            final amp = amps[index];
            final isSelected = amp.id == currentAmpId;

            return GestureDetector(
              onTap: () async {
                // Use chain link setting to determine which method to use
                if (widget.ampChainLinked) {
                  await widget.podController.setAmpModel(amp.id);
                } else {
                  await widget.podController.setAmpModelNoDefaults(amp.id);
                }
                // Request updated parameters from POD
                await widget.podController.refreshEditBuffer();
                if (context.mounted) Navigator.of(context).pop();
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? packColor.withValues(alpha: 0.3)
                      : PodColors.surfaceLight,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected ? packColor : PodColors.knobBase,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                padding: const EdgeInsets.all(6),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        amp.name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected ? packColor : PodColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (amp.realName != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          amp.realName!,
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
          },
        ),
      ],
    );
  }

  Color _getPackColor(String pack) {
    switch (pack) {
      case 'MS':
        return Colors.red;
      case 'CC':
        return Colors.blue;
      case 'BX':
        return Colors.green;
      case 'FX':
        return Colors.orange;
      default:
        return PodColors.accent;
    }
  }
}
