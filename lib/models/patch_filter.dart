/// Filter and sort criteria for local patch library

library;

import 'local_patch.dart';

/// Sort order for patch list
enum SortOrder {
  nameAsc('Name (A-Z)'),
  nameDesc('Name (Z-A)'),
  dateCreatedDesc('Date Created (Newest)'),
  dateCreatedAsc('Date Created (Oldest)'),
  dateModifiedDesc('Date Modified (Newest)'),
  dateModifiedAsc('Date Modified (Oldest)'),
  authorAsc('Author (A-Z)'),
  authorDesc('Author (Z-A)');

  final String displayName;
  const SortOrder(this.displayName);
}

/// Filter criteria for local library
class FilterCriteria {
  final PatchGenre? genre;
  final PatchUseCase? useCase;
  final bool? favoriteOnly;
  final List<String> tags;
  final String searchText;

  const FilterCriteria({
    this.genre,
    this.useCase,
    this.favoriteOnly,
    this.tags = const [],
    this.searchText = '',
  });

  /// Check if any filters are active
  bool get hasActiveFilters =>
      genre != null ||
      useCase != null ||
      favoriteOnly == true ||
      tags.isNotEmpty ||
      searchText.isNotEmpty;

  /// Clear all filters
  FilterCriteria clear() {
    return const FilterCriteria();
  }

  /// Apply filter to a patch
  bool matches(LocalPatch patch) {
    // Genre filter
    if (genre != null && patch.metadata.genre != genre) {
      return false;
    }

    // Use case filter
    if (useCase != null && patch.metadata.useCase != useCase) {
      return false;
    }

    // Favorite filter
    if (favoriteOnly == true && !patch.metadata.favorite) {
      return false;
    }

    // Tags filter (patch must have ALL specified tags)
    if (tags.isNotEmpty) {
      for (final tag in tags) {
        if (!patch.metadata.tags.contains(tag)) {
          return false;
        }
      }
    }

    // Search text filter (case-insensitive, searches name, author, description, tags)
    if (searchText.isNotEmpty) {
      final searchLower = searchText.toLowerCase();
      final matchesName = patch.patch.name.toLowerCase().contains(searchLower);
      final matchesAuthor = patch.metadata.author.toLowerCase().contains(searchLower);
      final matchesDescription = patch.metadata.description.toLowerCase().contains(searchLower);
      final matchesTags = patch.metadata.tags.any((tag) => tag.toLowerCase().contains(searchLower));

      if (!matchesName && !matchesAuthor && !matchesDescription && !matchesTags) {
        return false;
      }
    }

    return true;
  }

  /// Create a copy with updated values
  FilterCriteria copyWith({
    PatchGenre? genre,
    PatchUseCase? useCase,
    bool? favoriteOnly,
    List<String>? tags,
    String? searchText,
  }) {
    return FilterCriteria(
      genre: genre ?? this.genre,
      useCase: useCase ?? this.useCase,
      favoriteOnly: favoriteOnly ?? this.favoriteOnly,
      tags: tags ?? this.tags,
      searchText: searchText ?? this.searchText,
    );
  }
}

/// Apply sorting to patch list
List<LocalPatch> applySorting(List<LocalPatch> patches, SortOrder order) {
  final sorted = List<LocalPatch>.from(patches);

  switch (order) {
    case SortOrder.nameAsc:
      sorted.sort((a, b) => a.patch.name.compareTo(b.patch.name));
    case SortOrder.nameDesc:
      sorted.sort((a, b) => b.patch.name.compareTo(a.patch.name));
    case SortOrder.dateCreatedDesc:
      sorted.sort((a, b) => b.metadata.createdAt.compareTo(a.metadata.createdAt));
    case SortOrder.dateCreatedAsc:
      sorted.sort((a, b) => a.metadata.createdAt.compareTo(b.metadata.createdAt));
    case SortOrder.dateModifiedDesc:
      sorted.sort((a, b) => b.metadata.modifiedAt.compareTo(a.metadata.modifiedAt));
    case SortOrder.dateModifiedAsc:
      sorted.sort((a, b) => a.metadata.modifiedAt.compareTo(b.metadata.modifiedAt));
    case SortOrder.authorAsc:
      sorted.sort((a, b) => a.metadata.author.compareTo(b.metadata.author));
    case SortOrder.authorDesc:
      sorted.sort((a, b) => b.metadata.author.compareTo(a.metadata.author));
  }

  return sorted;
}

/// Apply filtering to patch list
List<LocalPatch> applyFiltering(List<LocalPatch> patches, FilterCriteria criteria) {
  if (!criteria.hasActiveFilters) {
    return patches;
  }

  return patches.where((patch) => criteria.matches(patch)).toList();
}

/// Apply both filtering and sorting
List<LocalPatch> applyFilterAndSort(
  List<LocalPatch> patches,
  FilterCriteria criteria,
  SortOrder order,
) {
  final filtered = applyFiltering(patches, criteria);
  return applySorting(filtered, order);
}
