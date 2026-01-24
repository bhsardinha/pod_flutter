import 'package:flutter/material.dart';
import '../../services/pod_controller.dart';
import '../../models/cab_models.dart';
import '../../models/app_settings.dart';
import 'pod_model_selector_modal.dart';

/// Cabinet picker modal with list and tiles view modes
class CabModal extends StatelessWidget {
  final int currentCabId;
  final PodController podController;
  final bool isConnected;
  final AppSettings settings;
  final bool initialTilesView;
  final double initialListScrollPosition;
  final double initialTilesScrollPosition;
  final ValueChanged<bool> onViewModeChanged;
  final void Function(double listPos, double tilesPos) onScrollPositionChanged;

  const CabModal({
    super.key,
    required this.currentCabId,
    required this.podController,
    required this.isConnected,
    required this.settings,
    required this.initialTilesView,
    required this.initialListScrollPosition,
    required this.initialTilesScrollPosition,
    required this.onViewModeChanged,
    required this.onScrollPositionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final currentCab = CabModels.byId(currentCabId) ?? CabModels.all.first;

    return PodModelSelectorModal<CabModel>(
      title: 'Select Cabinet',
      allModels: CabModels.all,
      currentModel: currentCab,
      settings: settings,
      initialTilesView: initialTilesView,
      initialListScrollPosition: initialListScrollPosition,
      initialTilesScrollPosition: initialTilesScrollPosition,
      onViewModeChanged: onViewModeChanged,
      onScrollPositionChanged: onScrollPositionChanged,
      getModelName: (cab) => cab.name,
      getModelRealName: (cab) => cab.realName,
      getModelPack: (cab) => cab.pack,
      getModelId: (cab) => cab.id,
      isModelSelected: (cab, current) => cab.id == current.id,
      onModelSelected: (cab) async {
        if (isConnected) {
          podController.setCabModel(cab.id);
          await podController.refreshEditBuffer();
        }
      },
      packConfigs: const {
        null: PackConfig(
          title: 'GUITAR CABINETS',
          color: Colors.amber,
        ),
        'BX': PackConfig(
          title: 'BASS CABINETS',
          color: Colors.green,
          badge: 'BX',
        ),
      },
    );
  }
}
