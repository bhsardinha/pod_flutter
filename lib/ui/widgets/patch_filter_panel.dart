/// Filter and sort panel for local library

library;

import 'package:flutter/material.dart';
import '../../models/local_patch.dart';
import '../../models/patch_filter.dart';
import '../theme/pod_theme.dart';

/// Filter panel for local library
class PatchFilterPanel extends StatefulWidget {
  final FilterCriteria criteria;
  final SortOrder sortOrder;
  final ValueChanged<FilterCriteria> onCriteriaChanged;
  final ValueChanged<SortOrder> onSortOrderChanged;
  final List<String> availableTags;

  const PatchFilterPanel({
    super.key,
    required this.criteria,
    required this.sortOrder,
    required this.onCriteriaChanged,
    required this.onSortOrderChanged,
    required this.availableTags,
  });

  @override
  State<PatchFilterPanel> createState() => _PatchFilterPanelState();
}

class _PatchFilterPanelState extends State<PatchFilterPanel> {
  bool _expanded = false;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.criteria.searchText);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateCriteria(FilterCriteria newCriteria) {
    widget.onCriteriaChanged(newCriteria);
  }

  void _clearFilters() {
    _searchController.clear();
    _updateCriteria(const FilterCriteria());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PodColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: PodColors.knobBase),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with expand/collapse
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.filter_list,
                    color: PodColors.textLabel,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Filter & Sort',
                    style: TextStyle(
                      fontFamily: 'Copperplate',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: PodColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  if (widget.criteria.hasActiveFilters)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: PodColors.accent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'ACTIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: PodColors.textSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // Expanded content
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Compact row: Search and Sort
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: PodColors.textPrimary, fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'Search',
                            labelStyle: const TextStyle(fontSize: 12),
                            hintText: 'Name, author...',
                            hintStyle: const TextStyle(fontSize: 12),
                            prefixIcon: const Icon(Icons.search, color: PodColors.textSecondary, size: 18),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, color: PodColors.textSecondary, size: 18),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      _searchController.clear();
                                      _updateCriteria(widget.criteria.copyWith(searchText: ''));
                                    },
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(vertical: 8),
                            isDense: true,
                          ),
                          onChanged: (value) {
                            _updateCriteria(widget.criteria.copyWith(searchText: value));
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<SortOrder>(
                          initialValue: widget.sortOrder,
                          decoration: const InputDecoration(
                            labelText: 'Sort',
                            labelStyle: TextStyle(fontSize: 12),
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            isDense: true,
                          ),
                          dropdownColor: PodColors.surface,
                          style: const TextStyle(color: PodColors.textPrimary, fontSize: 12),
                          items: SortOrder.values.map((order) {
                            return DropdownMenuItem(
                              value: order,
                              child: Text(order.displayName, style: const TextStyle(fontSize: 12)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              widget.onSortOrderChanged(value);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Compact row: Filters
                  Row(
                    children: [
                      // Favorite checkbox
                      InkWell(
                        onTap: () {
                          _updateCriteria(
                            widget.criteria.copyWith(
                              favoriteOnly: widget.criteria.favoriteOnly == true ? false : true,
                            ),
                          );
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: widget.criteria.favoriteOnly == true,
                              onChanged: (value) {
                                _updateCriteria(
                                  widget.criteria.copyWith(
                                    favoriteOnly: value == true ? true : false,
                                  ),
                                );
                              },
                              activeColor: PodColors.accent,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                            const Text(
                              'Favorites',
                              style: TextStyle(
                                fontFamily: 'Copperplate',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: PodColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Genre
                      Expanded(
                        child: DropdownButtonFormField<PatchGenre?>(
                          initialValue: widget.criteria.genre,
                          decoration: const InputDecoration(
                            labelText: 'Genre',
                            labelStyle: TextStyle(fontSize: 12),
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            isDense: true,
                          ),
                          dropdownColor: PodColors.surface,
                          style: const TextStyle(color: PodColors.textPrimary, fontSize: 12),
                          items: [
                            const DropdownMenuItem<PatchGenre?>(
                              value: null,
                              child: Text('All', style: TextStyle(fontSize: 12)),
                            ),
                            ...PatchGenre.values.where((g) => g != PatchGenre.unspecified).map((genre) {
                              return DropdownMenuItem<PatchGenre?>(
                                value: genre,
                                child: Text(genre.displayName, style: const TextStyle(fontSize: 12)),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            _updateCriteria(widget.criteria.copyWith(genre: value));
                          },
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Use case
                      Expanded(
                        child: DropdownButtonFormField<PatchUseCase?>(
                          initialValue: widget.criteria.useCase,
                          decoration: const InputDecoration(
                            labelText: 'Use Case',
                            labelStyle: TextStyle(fontSize: 12),
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            isDense: true,
                          ),
                          dropdownColor: PodColors.surface,
                          style: const TextStyle(color: PodColors.textPrimary, fontSize: 12),
                          items: [
                            const DropdownMenuItem<PatchUseCase?>(
                              value: null,
                              child: Text('All', style: TextStyle(fontSize: 12)),
                            ),
                            ...PatchUseCase.values.where((u) => u != PatchUseCase.general).map((useCase) {
                              return DropdownMenuItem<PatchUseCase?>(
                                value: useCase,
                                child: Text(useCase.displayName, style: const TextStyle(fontSize: 12)),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            _updateCriteria(widget.criteria.copyWith(useCase: value));
                          },
                        ),
                      ),
                    ],
                  ),

                  // Clear filters button
                  if (widget.criteria.hasActiveFilters) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _clearFilters,
                      icon: const Icon(Icons.clear_all, size: 14),
                      label: const Text('CLEAR', style: TextStyle(fontSize: 11)),
                      style: TextButton.styleFrom(
                        foregroundColor: PodColors.accent,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
