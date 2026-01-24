import 'package:flutter/material.dart';
import '../theme/pod_theme.dart';
import '../../models/app_settings.dart';

/// Common modal structure for model selection (Amp, Cab, Mic)
/// Provides list/tiles view toggle, scroll position persistence, and pack grouping
class PodModelSelectorModal<T> extends StatefulWidget {
  final String title;
  final List<T> allModels;
  final T currentModel;
  final AppSettings settings;

  // View mode state
  final bool initialTilesView;
  final double initialListScrollPosition;
  final double initialTilesScrollPosition;
  final ValueChanged<bool> onViewModeChanged;
  final void Function(double listPos, double tilesPos) onScrollPositionChanged;

  // Model accessors
  final String Function(T) getModelName;
  final String? Function(T) getModelRealName;
  final String? Function(T) getModelPack;
  final int Function(T) getModelId;
  final bool Function(T, T) isModelSelected;

  // Selection callback
  final Future<void> Function(T) onModelSelected;

  // Optional: Custom content above the list (e.g., Room knob for mics)
  final Widget? topContent;

  // Optional: List view builder (if different from default)
  final Widget Function(BuildContext, T, bool)? listItemBuilder;

  // Optional: Tiles view builder (if different from default)
  final Widget Function(BuildContext, T, bool)? tileItemBuilder;

  // Optional: Pack grouping configuration
  final Map<String?, PackConfig>? packConfigs;

  const PodModelSelectorModal({
    super.key,
    required this.title,
    required this.allModels,
    required this.currentModel,
    required this.settings,
    required this.initialTilesView,
    required this.initialListScrollPosition,
    required this.initialTilesScrollPosition,
    required this.onViewModeChanged,
    required this.onScrollPositionChanged,
    required this.getModelName,
    required this.getModelRealName,
    required this.getModelPack,
    required this.getModelId,
    required this.isModelSelected,
    required this.onModelSelected,
    this.topContent,
    this.listItemBuilder,
    this.tileItemBuilder,
    this.packConfigs,
  });

  @override
  State<PodModelSelectorModal<T>> createState() => _PodModelSelectorModalState<T>();
}

class _PodModelSelectorModalState<T> extends State<PodModelSelectorModal<T>> {
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
                Text(
                  widget.title,
                  style: const TextStyle(
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

            // Optional top content
            if (widget.topContent != null) ...[
              widget.topContent!,
              const SizedBox(height: 16),
            ],

            // Model list/grid
            Expanded(
              child: _isTilesView
                  ? _buildTilesView()
                  : _buildListView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      controller: _listScrollController,
      itemCount: widget.allModels.length,
      itemBuilder: (context, index) {
        final model = widget.allModels[index];
        final isSelected = widget.isModelSelected(model, widget.currentModel);

        if (widget.listItemBuilder != null) {
          return widget.listItemBuilder!(context, model, isSelected);
        }

        return _buildDefaultListItem(model, isSelected);
      },
    );
  }

  Widget _buildDefaultListItem(T model, bool isSelected) {
    final pack = widget.getModelPack(model);
    final packColor = pack != null && widget.packConfigs != null
        ? (widget.packConfigs![pack]?.color ?? PodColors.accent)
        : PodColors.accent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton(
        onPressed: () async {
          await widget.onModelSelected(model);
          if (mounted) Navigator.of(context).pop();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected
              ? packColor.withValues(alpha: 0.2)
              : PodColors.surfaceLight,
          foregroundColor: isSelected
              ? packColor
              : PodColors.textPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        child: Row(
          children: [
            Expanded(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${widget.getModelId(model).toString().padLeft(2, '0')} - ',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? packColor : PodColors.textPrimary,
                      ),
                    ),
                    TextSpan(
                      text: widget.getModelName(model),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? packColor : PodColors.textPrimary,
                      ),
                    ),
                    if (widget.getModelRealName(model) != null) ...[
                      TextSpan(
                        text: ' - ${widget.getModelRealName(model)}',
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
            if (pack != null && widget.packConfigs != null)
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
                  widget.packConfigs![pack]?.badge ?? pack,
                  style: TextStyle(
                    fontSize: 10,
                    color: packColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTilesView() {
    // Group models by pack if pack configs are provided
    if (widget.packConfigs != null) {
      return SingleChildScrollView(
        controller: _gridScrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _buildPackSections(),
        ),
      );
    }

    // No grouping, just display all in a grid
    return GridView.builder(
      controller: _gridScrollController,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.settings.gridItemsPerRow,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 2.35,
      ),
      itemCount: widget.allModels.length,
      itemBuilder: (context, index) {
        final model = widget.allModels[index];
        final isSelected = widget.isModelSelected(model, widget.currentModel);

        if (widget.tileItemBuilder != null) {
          return widget.tileItemBuilder!(context, model, isSelected);
        }

        return _buildDefaultTile(model, isSelected, PodColors.accent);
      },
    );
  }

  List<Widget> _buildPackSections() {
    final sections = <Widget>[];

    // Group models by pack
    final grouped = <String?, List<T>>{};
    for (final model in widget.allModels) {
      final pack = widget.getModelPack(model);
      grouped.putIfAbsent(pack, () => []).add(model);
    }

    // Sort by pack config order
    final sortedPacks = grouped.keys.toList();
    if (widget.packConfigs != null) {
      // Put null (stock) first, then sort others by config order
      sortedPacks.sort((a, b) {
        if (a == null) return -1;
        if (b == null) return 1;
        final aIndex = widget.packConfigs!.keys.toList().indexOf(a);
        final bIndex = widget.packConfigs!.keys.toList().indexOf(b);
        return aIndex.compareTo(bIndex);
      });
    }

    for (int i = 0; i < sortedPacks.length; i++) {
      final pack = sortedPacks[i];
      final models = grouped[pack]!;
      final packConfig = pack != null && widget.packConfigs != null
          ? widget.packConfigs![pack]
          : null;

      if (i > 0) {
        sections.addAll([
          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 2),
          const SizedBox(height: 16),
        ]);
      }

      sections.add(_buildPackSection(
        packConfig?.title ?? 'MODELS',
        models,
        packConfig?.color ?? PodColors.accent,
        packConfig?.badge,
      ));
    }

    sections.add(const SizedBox(height: 16));

    return sections;
  }

  Widget _buildPackSection(
    String title,
    List<T> models,
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
        // Grid of models
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: widget.settings.gridItemsPerRow,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2.35,
          ),
          itemCount: models.length,
          itemBuilder: (context, index) {
            final model = models[index];
            final isSelected = widget.isModelSelected(model, widget.currentModel);

            if (widget.tileItemBuilder != null) {
              return widget.tileItemBuilder!(context, model, isSelected);
            }

            return _buildDefaultTile(model, isSelected, packColor);
          },
        ),
      ],
    );
  }

  Widget _buildDefaultTile(T model, bool isSelected, Color packColor) {
    return GestureDetector(
      onTap: () async {
        await widget.onModelSelected(model);
        if (mounted) Navigator.of(context).pop();
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? packColor.withValues(alpha: 0.3)
              : PodColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
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
                widget.getModelName(model),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 18,
                  fontWeight: isSelected
                      ? FontWeight.w600
                      : FontWeight.w500,
                  color: isSelected ? packColor : PodColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (widget.getModelRealName(model) != null) ...[
                const SizedBox(height: 2),
                Text(
                  widget.getModelRealName(model)!,
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
  }
}

/// Pack configuration for grouped tile view
class PackConfig {
  final String title;  // Display title (e.g., "STOCK MODELS", "METAL SHOP")
  final Color color;   // Pack accent color
  final String? badge; // Optional badge text (e.g., "MS", "CC", "BX")

  const PackConfig({
    required this.title,
    required this.color,
    this.badge,
  });
}
