/// Extended patch model with metadata for local library
/// Wraps core Patch with additional information for organization and search

library;

import 'patch.dart';

/// Patch genre categories
enum PatchGenre {
  unspecified('Unspecified'),
  rock('Rock'),
  metal('Metal'),
  blues('Blues'),
  jazz('Jazz'),
  country('Country'),
  funk('Funk'),
  punk('Punk'),
  progressive('Progressive'),
  ambient('Ambient'),
  other('Other');

  final String displayName;
  const PatchGenre(this.displayName);
}

/// Patch use case categories
enum PatchUseCase {
  general('General'),
  live('Live Performance'),
  studio('Studio Recording'),
  practice('Practice'),
  recording('Recording');

  final String displayName;
  const PatchUseCase(this.displayName);
}

/// Extended metadata for local library patches
class PatchMetadata {
  String author;
  String description;
  bool favorite;
  PatchGenre genre;
  PatchUseCase useCase;
  List<String> tags;
  DateTime createdAt;
  DateTime modifiedAt;
  String? importSource; // 'hardware', 'file', 'user'

  PatchMetadata({
    this.author = '',
    this.description = '',
    this.favorite = false,
    this.genre = PatchGenre.unspecified,
    this.useCase = PatchUseCase.general,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? modifiedAt,
    this.importSource,
  })  : tags = tags ?? [],
        createdAt = createdAt ?? DateTime.now(),
        modifiedAt = modifiedAt ?? DateTime.now();

  /// Create metadata from JSON
  factory PatchMetadata.fromJson(Map<String, dynamic> json) {
    return PatchMetadata(
      author: json['author'] as String? ?? '',
      description: json['description'] as String? ?? '',
      favorite: json['favorite'] as bool? ?? false,
      genre: PatchGenre.values.firstWhere(
        (e) => e.name == json['genre'],
        orElse: () => PatchGenre.unspecified,
      ),
      useCase: PatchUseCase.values.firstWhere(
        (e) => e.name == json['useCase'],
        orElse: () => PatchUseCase.general,
      ),
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      modifiedAt: json['modifiedAt'] != null
          ? DateTime.parse(json['modifiedAt'] as String)
          : DateTime.now(),
      importSource: json['importSource'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'author': author,
      'description': description,
      'favorite': favorite,
      'genre': genre.name,
      'useCase': useCase.name,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
      'importSource': importSource,
    };
  }

  /// Create a copy with updated modified timestamp
  PatchMetadata copyWithUpdate({
    String? author,
    String? description,
    bool? favorite,
    PatchGenre? genre,
    PatchUseCase? useCase,
    List<String>? tags,
    String? importSource,
  }) {
    return PatchMetadata(
      author: author ?? this.author,
      description: description ?? this.description,
      favorite: favorite ?? this.favorite,
      genre: genre ?? this.genre,
      useCase: useCase ?? this.useCase,
      tags: tags ?? this.tags,
      createdAt: createdAt,
      modifiedAt: DateTime.now(),
      importSource: importSource ?? this.importSource,
    );
  }
}

/// Local library patch with extended metadata
class LocalPatch {
  final String id; // UUID
  final Patch patch; // Core 160-byte POD patch
  final PatchMetadata metadata;

  LocalPatch({
    required this.id,
    required this.patch,
    required this.metadata,
  });

  /// Create from JSON with binary patch data
  factory LocalPatch.fromJson(Map<String, dynamic> json, Patch patch) {
    return LocalPatch(
      id: json['id'] as String,
      patch: patch,
      metadata: PatchMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
    );
  }

  /// Convert to JSON (patch data stored separately as .bin)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patchName': patch.name, // Redundant but useful for quick display
      'metadata': metadata.toJson(),
    };
  }

  /// Create a copy with updated metadata
  LocalPatch copyWith({
    String? id,
    Patch? patch,
    PatchMetadata? metadata,
  }) {
    return LocalPatch(
      id: id ?? this.id,
      patch: patch ?? this.patch,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Create a clone with new ID and updated name
  LocalPatch clone(String newId, String newName) {
    final clonedPatch = patch.copy();
    clonedPatch.name = newName;

    return LocalPatch(
      id: newId,
      patch: clonedPatch,
      metadata: PatchMetadata(
        author: metadata.author,
        description: '${metadata.description} (Clone)',
        favorite: false,
        genre: metadata.genre,
        useCase: metadata.useCase,
        tags: List.from(metadata.tags),
        importSource: 'clone',
      ),
    );
  }

  @override
  String toString() => 'LocalPatch("${patch.name}", id: $id)';
}
