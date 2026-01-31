/// Detail view for selected local patch

library;

import 'package:flutter/material.dart';
import '../../models/local_patch.dart';
import '../../models/amp_models.dart';
import '../../models/cab_models.dart';
import '../../protocol/cc_map.dart';
import '../theme/pod_theme.dart';
import '../utils/value_formatters.dart';
import 'package:intl/intl.dart';

/// Detail card showing patch information
class PatchDetailCard extends StatelessWidget {
  final LocalPatch? patch;
  final VoidCallback? onLoadToEditBuffer;
  final VoidCallback? onExportToSlot;
  final VoidCallback? onEditMetadata;

  const PatchDetailCard({
    super.key,
    this.patch,
    this.onLoadToEditBuffer,
    this.onExportToSlot,
    this.onEditMetadata,
  });

  @override
  Widget build(BuildContext context) {
    if (patch == null) {
      return Container(
        decoration: BoxDecoration(
          color: PodColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: PodColors.knobBase),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.music_note_outlined,
                size: 64,
                color: PodColors.textSecondary,
              ),
              SizedBox(height: 16),
              Text(
                'Select a patch from the list',
                style: PodTextStyles.valueMedium,
              ),
            ],
          ),
        ),
      );
    }

    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');

    return Container(
      decoration: BoxDecoration(
        color: PodColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: PodColors.knobBase),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Patch header: name/author on left, favorite/genre/use case on right
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Patch name
                      Text(
                        patch!.patch.name,
                        style: PodTextStyles.header,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Author below name
                      if (patch!.metadata.author.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'by ${patch!.metadata.author}',
                          style: PodTextStyles.labelMedium.copyWith(
                            color: PodColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Favorite star (if favorited)
                    if (patch!.metadata.favorite)
                      const Icon(
                        Icons.star,
                        color: PodColors.accent,
                        size: 24,
                      ),
                    // Genre and Use Case
                    if (patch!.metadata.genre != PatchGenre.unspecified) ...[
                      if (patch!.metadata.favorite) const SizedBox(height: 4),
                      Text(
                        patch!.metadata.genre.displayName,
                        style: const TextStyle(
                          fontFamily: 'Copperplate',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: PodColors.textSecondary,
                        ),
                      ),
                    ],
                    if (patch!.metadata.useCase != PatchUseCase.general) ...[
                      const SizedBox(height: 2),
                      Text(
                        patch!.metadata.useCase.displayName,
                        style: const TextStyle(
                          fontFamily: 'Copperplate',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: PodColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Action buttons (single row)
            Row(
              children: [
                // Edit metadata (remaining width)
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: onEditMetadata,
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('EDIT METADATA', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PodColors.surfaceLight,
                        foregroundColor: PodColors.textPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Load button (square icon only)
                SizedBox(
                  width: 44,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: onLoadToEditBuffer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PodColors.accent,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Icon(Icons.download, size: 20),
                  ),
                ),
                const SizedBox(width: 8),
                // Export button (square icon only)
                SizedBox(
                  width: 44,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: onExportToSlot,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PodColors.surfaceLight,
                      foregroundColor: PodColors.textPrimary,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Icon(Icons.upload, size: 20),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Patch Parameters Section (no label)
            _buildPatchParameters(patch!.patch),

            // Description (no label)
            if (patch!.metadata.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                patch!.metadata.description,
                style: PodTextStyles.valueMedium.copyWith(
                  color: PodColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],

            // Tags (no label)
            if (patch!.metadata.tags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: patch!.metadata.tags.map((tag) {
                  return Chip(
                    label: Text(tag, style: const TextStyle(fontSize: 9)),
                    labelStyle: const TextStyle(fontSize: 9),
                    backgroundColor: PodColors.surfaceLight,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 12),

            // Timestamps
            _buildMetadataRow('Created', dateFormat.format(patch!.metadata.createdAt)),
            const SizedBox(height: 6),
            _buildMetadataRow('Modified', dateFormat.format(patch!.metadata.modifiedAt)),

            if (patch!.metadata.importSource != null) ...[
              const SizedBox(height: 6),
              _buildMetadataRow('Source', patch!.metadata.importSource!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Copperplate',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: PodColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'Copperplate',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: PodColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPatchParameters(dynamic patch) {
    // Get key parameters
    final ampId = patch.getValue(PodXtCC.ampSelect);
    final cabId = patch.getValue(PodXtCC.cabSelect);
    final micPos = patch.getValue(PodXtCC.micSelect);
    final drive = patch.getValue(PodXtCC.drive);
    final bass = patch.getValue(PodXtCC.bass);
    final mid = patch.getValue(PodXtCC.mid);
    final treble = patch.getValue(PodXtCC.treble);
    final presence = patch.getValue(PodXtCC.presence);
    final chanVolume = patch.getValue(PodXtCC.chanVolume);

    final ampName = AmpModels.byId(ampId)?.name ?? 'Unknown';
    final cabName = CabModels.byId(cabId)?.name ?? 'Unknown';
    // Mic position 0-3 corresponds to guitar mics (simplify for now)
    final micNames = ['57 On', '57 Off', '421', '67'];
    final micName = micPos >= 0 && micPos < micNames.length ? micNames[micPos] : 'Mic $micPos';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PodColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Amp - Cab - Mic (single line, centered)
          Center(
            child: Text(
              '$ampName - $cabName - $micName',
              style: const TextStyle(
                fontFamily: 'Copperplate',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: PodColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
          // Tone stack + Volume (6 params in one row)
          Row(
            children: [
              Expanded(child: _buildParamValue('Drive', drive)),
              Expanded(child: _buildParamValue('Bass', bass)),
              Expanded(child: _buildParamValue('Mid', mid)),
              Expanded(child: _buildParamValue('Treble', treble)),
              Expanded(child: _buildParamValue('Pres', presence)),
              Expanded(child: _buildParamValue('Vol', chanVolume)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParamValue(String label, int value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Copperplate',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: PodColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          formatKnobValue(value),
          style: const TextStyle(
            fontFamily: 'Copperplate',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: PodColors.accent,
          ),
        ),
      ],
    );
  }
}
