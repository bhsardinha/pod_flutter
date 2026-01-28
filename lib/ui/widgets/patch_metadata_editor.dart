/// Modal dialog for editing patch metadata

library;

import 'package:flutter/material.dart';
import '../../models/local_patch.dart';
import '../theme/pod_theme.dart';

/// Show metadata editor dialog
Future<PatchMetadata?> showPatchMetadataEditor({
  required BuildContext context,
  required PatchMetadata initialMetadata,
}) async {
  return await showDialog<PatchMetadata>(
    context: context,
    builder: (context) => _PatchMetadataEditorDialog(
      initialMetadata: initialMetadata,
    ),
  );
}

class _PatchMetadataEditorDialog extends StatefulWidget {
  final PatchMetadata initialMetadata;

  const _PatchMetadataEditorDialog({
    required this.initialMetadata,
  });

  @override
  State<_PatchMetadataEditorDialog> createState() =>
      _PatchMetadataEditorDialogState();
}

class _PatchMetadataEditorDialogState
    extends State<_PatchMetadataEditorDialog> {
  late TextEditingController _authorController;
  late TextEditingController _descriptionController;
  late TextEditingController _tagInputController;
  late bool _favorite;
  late PatchGenre _genre;
  late PatchUseCase _useCase;
  late List<String> _tags;

  @override
  void initState() {
    super.initState();
    _authorController = TextEditingController(text: widget.initialMetadata.author);
    _descriptionController = TextEditingController(text: widget.initialMetadata.description);
    _tagInputController = TextEditingController();
    _favorite = widget.initialMetadata.favorite;
    _genre = widget.initialMetadata.genre;
    _useCase = widget.initialMetadata.useCase;
    _tags = List.from(widget.initialMetadata.tags);
  }

  @override
  void dispose() {
    _authorController.dispose();
    _descriptionController.dispose();
    _tagInputController.dispose();
    super.dispose();
  }

  void _addTag() {
    final tag = _tagInputController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagInputController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _save() {
    final updatedMetadata = widget.initialMetadata.copyWithUpdate(
      author: _authorController.text.trim(),
      description: _descriptionController.text.trim(),
      favorite: _favorite,
      genre: _genre,
      useCase: _useCase,
      tags: _tags,
    );

    Navigator.pop(context, updatedMetadata);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: PodColors.background,
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Edit Metadata',
                  style: PodTextStyles.header,
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: PodColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Author
                    TextField(
                      controller: _authorController,
                      style: const TextStyle(color: PodColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Author',
                        hintText: 'Your name or band',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextField(
                      controller: _descriptionController,
                      style: const TextStyle(color: PodColors.textPrimary),
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Brief description of the patch',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Favorite
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Favorite',
                          style: PodTextStyles.valueMedium,
                        ),
                        Switch(
                          value: _favorite,
                          onChanged: (value) => setState(() => _favorite = value),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Genre
                    DropdownButtonFormField<PatchGenre>(
                      value: _genre,
                      decoration: const InputDecoration(
                        labelText: 'Genre',
                      ),
                      dropdownColor: PodColors.surface,
                      style: const TextStyle(color: PodColors.textPrimary),
                      items: PatchGenre.values.map((genre) {
                        return DropdownMenuItem(
                          value: genre,
                          child: Text(genre.displayName),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _genre = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Use Case
                    DropdownButtonFormField<PatchUseCase>(
                      value: _useCase,
                      decoration: const InputDecoration(
                        labelText: 'Use Case',
                      ),
                      dropdownColor: PodColors.surface,
                      style: const TextStyle(color: PodColors.textPrimary),
                      items: PatchUseCase.values.map((useCase) {
                        return DropdownMenuItem(
                          value: useCase,
                          child: Text(useCase.displayName),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _useCase = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Tags
                    const Text(
                      'Tags',
                      style: PodTextStyles.valueMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _tagInputController,
                            style: const TextStyle(color: PodColors.textPrimary),
                            decoration: const InputDecoration(
                              hintText: 'Add a tag',
                              isDense: true,
                            ),
                            onSubmitted: (_) => _addTag(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.add, color: PodColors.accent),
                          onPressed: _addTag,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _tags.map((tag) {
                        return Chip(
                          label: Text(tag),
                          labelStyle: PodTextStyles.labelSmall,
                          backgroundColor: PodColors.surfaceLight,
                          deleteIcon: const Icon(
                            Icons.close,
                            size: 16,
                            color: PodColors.textSecondary,
                          ),
                          onDeleted: () => _removeTag(tag),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PodColors.accent,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('SAVE'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
