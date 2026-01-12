import 'package:flutter/material.dart';
import '../../models/effect_models.dart';
import '../../models/app_settings.dart';
import '../theme/pod_theme.dart';

/// Reusable effect model selector with arrows and dropdown picker.
///
/// Features:
/// - Left/right arrows to cycle through models
/// - Clickable center to show full model list in modal dialog
/// - Two-line display: model name + "based on" info
/// - List/Grid view toggle in modal
/// - Highlights currently selected model
class EffectModelSelector extends StatefulWidget {
  /// List of all available models
  final List<EffectModel> models;

  /// Currently selected model ID
  final int selectedId;

  /// Callback when model is changed
  final ValueChanged<int> onChanged;

  /// Whether the selector is enabled
  final bool isEnabled;

  /// Title for the picker modal (e.g., "Select Wah Model")
  final String pickerTitle;

  /// App settings for grid layout preferences
  final AppSettings settings;

  const EffectModelSelector({
    super.key,
    required this.models,
    required this.selectedId,
    required this.onChanged,
    required this.pickerTitle,
    required this.settings,
    this.isEnabled = true,
  });

  @override
  State<EffectModelSelector> createState() => _EffectModelSelectorState();
}

class _EffectModelSelectorState extends State<EffectModelSelector> {
  void _showModelPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _EffectPickerDialog(
        models: widget.models,
        selectedId: widget.selectedId,
        onChanged: widget.onChanged,
        pickerTitle: widget.pickerTitle,
        settings: widget.settings,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentModel = widget.models.firstWhere(
      (m) => m.id == widget.selectedId,
      orElse: () => widget.models.first,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: PodColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: PodColors.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous button
          IconButton(
            icon: const Icon(Icons.arrow_left, color: PodColors.accent),
            onPressed: widget.isEnabled
                ? () {
                    final currentIndex = widget.models.indexWhere((m) => m.id == widget.selectedId);
                    final newIndex = (currentIndex - 1) % widget.models.length;
                    final newId = newIndex < 0 ? widget.models.length - 1 : newIndex;
                    widget.onChanged(widget.models[newId].id);
                  }
                : null,
          ),
          // Current model name and based-on info (clickable to show picker)
          Expanded(
            child: InkWell(
              onTap: widget.isEnabled ? () => _showModelPicker(context) : null,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    currentModel.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: PodColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (currentModel.basedOn != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      currentModel.basedOn!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: PodColors.textSecondary.withValues(alpha: 0.7),
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Next button
          IconButton(
            icon: const Icon(Icons.arrow_right, color: PodColors.accent),
            onPressed: widget.isEnabled
                ? () {
                    final currentIndex = widget.models.indexWhere((m) => m.id == widget.selectedId);
                    final newIndex = (currentIndex + 1) % widget.models.length;
                    widget.onChanged(widget.models[newIndex].id);
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

/// Internal dialog widget for effect model picker
class _EffectPickerDialog extends StatefulWidget {
  final List<EffectModel> models;
  final int selectedId;
  final ValueChanged<int> onChanged;
  final String pickerTitle;
  final AppSettings settings;

  const _EffectPickerDialog({
    required this.models,
    required this.selectedId,
    required this.onChanged,
    required this.pickerTitle,
    required this.settings,
  });

  @override
  State<_EffectPickerDialog> createState() => _EffectPickerDialogState();
}

class _EffectPickerDialogState extends State<_EffectPickerDialog> {
  late bool _isTilesView;
  late ScrollController _listScrollController;
  late ScrollController _gridScrollController;

  @override
  void initState() {
    super.initState();
    _isTilesView = false;
    _listScrollController = ScrollController();
    _gridScrollController = ScrollController();
  }

  @override
  void dispose() {
    _listScrollController.dispose();
    _gridScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Dialog(
      backgroundColor: PodColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: screenWidth * 0.85,
        height: screenHeight * 0.8,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header with title and view toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.pickerTitle,
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
      itemCount: widget.models.length,
      itemBuilder: (context, index) {
        final model = widget.models[index];
        final isSelected = model.id == widget.selectedId;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ElevatedButton(
            onPressed: () {
              widget.onChanged(model.id);
              Navigator.of(context).pop();
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
                          text: model.name,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? PodColors.accent : PodColors.textPrimary,
                          ),
                        ),
                        if (model.basedOn != null)
                          TextSpan(
                            text: ' - ${model.basedOn}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w400,
                              color: PodColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (model.pack != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getPackColor(model.pack!).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      model.pack!,
                      style: TextStyle(
                        fontSize: 10,
                        color: _getPackColor(model.pack!),
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

  Widget _buildTilesView() {
    // Separate models by pack
    final stockModels = widget.models.where((m) => m.pack == null).toList();
    final fxModels = widget.models.where((m) => m.pack == 'FX').toList();
    final bxModels = widget.models.where((m) => m.pack == 'BX').toList();

    return SingleChildScrollView(
      controller: _gridScrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stock Models Section
          if (stockModels.isNotEmpty)
            _buildPackSection(
              'STOCK MODELS',
              stockModels,
              PodColors.accent,
              null,
            ),

          // FX Pack Section
          if (fxModels.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1, thickness: 2),
            const SizedBox(height: 16),
            _buildPackSection(
              'FX JUNKIE',
              fxModels,
              Colors.orange,
              'FX',
            ),
          ],

          // BX Pack Section
          if (bxModels.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1, thickness: 2),
            const SizedBox(height: 16),
            _buildPackSection(
              'BASS EXPANSION',
              bxModels,
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
    List<EffectModel> models,
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
            final isSelected = model.id == widget.selectedId;

            return GestureDetector(
              onTap: () {
                widget.onChanged(model.id);
                Navigator.of(context).pop();
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
                        model.name,
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
                      if (model.basedOn != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          model.basedOn!,
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
      ],
    );
  }

  Color _getPackColor(String pack) {
    switch (pack) {
      case 'FX':
        return Colors.orange;
      case 'BX':
        return Colors.green;
      default:
        return PodColors.accent;
    }
  }
}
