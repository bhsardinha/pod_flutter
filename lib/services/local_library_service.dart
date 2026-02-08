/// Local patch library persistence service
/// Handles file I/O for .podpatch and .podlibrary formats

library;

import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../models/local_patch.dart';
import '../models/patch.dart';

/// Service for managing local patch library storage
class LocalLibraryService {
  static const String _libraryDirName = 'pod_flutter';
  static const String _localLibraryDirName = 'local_library';
  static const String _patchesDirName = 'patches';
  static const String _indexFileName = 'index.json';

  Directory? _appDir;
  Directory? _libraryDir;
  Directory? _patchesDir;

  // Cache for loaded patches
  List<LocalPatch>? _cachedPatches;
  bool _cacheValid = false;

  /// Initialize storage directories
  Future<void> initialize() async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      _appDir = Directory(path.join(appDocDir.path, _libraryDirName));
      _libraryDir = Directory(path.join(_appDir!.path, _localLibraryDirName));
      _patchesDir = Directory(path.join(_libraryDir!.path, _patchesDirName));

      // Create directories if they don't exist
      if (!await _appDir!.exists()) {
        await _appDir!.create(recursive: true);
      }
      if (!await _libraryDir!.exists()) {
        await _libraryDir!.create(recursive: true);
      }
      if (!await _patchesDir!.exists()) {
        await _patchesDir!.create(recursive: true);
      }
    } catch (e) {
      throw LocalLibraryException('Failed to initialize storage: $e');
    }
  }

  /// Ensure initialization has been called
  void _ensureInitialized() {
    if (_patchesDir == null) {
      throw LocalLibraryException('Service not initialized. Call initialize() first.');
    }
  }

  /// Save a single patch to local library
  Future<void> savePatch(LocalPatch patch) async {
    _ensureInitialized();

    try {
      // Save binary patch data
      final binFile = File(path.join(_patchesDir!.path, '${patch.id}.bin'));
      await binFile.writeAsBytes(patch.patch.data);

      // Save JSON metadata
      final jsonFile = File(path.join(_patchesDir!.path, '${patch.id}.json'));
      await jsonFile.writeAsString(jsonEncode(patch.toJson()));

      // Invalidate cache since data changed
      _cacheValid = false;

      // Update index
      await _updateIndex();
    } catch (e) {
      throw LocalLibraryException('Failed to save patch "${patch.patch.name}": $e');
    }
  }

  /// Load a single patch by ID
  Future<LocalPatch?> loadPatch(String id) async {
    _ensureInitialized();

    try {
      final binFile = File(path.join(_patchesDir!.path, '$id.bin'));
      final jsonFile = File(path.join(_patchesDir!.path, '$id.json'));

      if (!await binFile.exists() || !await jsonFile.exists()) {
        return null;
      }

      // Load binary patch data
      final patchData = await binFile.readAsBytes();
      final patch = Patch.fromData(patchData);

      // Load JSON metadata
      final jsonData = await jsonFile.readAsString();
      final json = jsonDecode(jsonData) as Map<String, dynamic>;

      return LocalPatch.fromJson(json, patch);
    } catch (e) {
      throw LocalLibraryException('Failed to load patch (ID: $id): $e');
    }
  }

  /// Load all patches from local library (cached)
  Future<List<LocalPatch>> loadAllPatches({bool forceRefresh = false}) async {
    _ensureInitialized();

    // Return cached data if valid and not forcing refresh
    if (_cacheValid && !forceRefresh && _cachedPatches != null) {
      return List<LocalPatch>.from(_cachedPatches!);
    }

    try {
      final patches = <LocalPatch>[];
      final patchFiles = await _patchesDir!.list().toList();

      // Get all .json files (one per patch)
      final jsonFiles = patchFiles
          .whereType<File>()
          .where((f) => f.path.endsWith('.json') && !f.path.endsWith('index.json'))
          .toList();

      for (final jsonFile in jsonFiles) {
        final id = jsonFile.path.split('/').last.replaceAll('.json', '');
        final patch = await loadPatch(id);
        if (patch != null) {
          patches.add(patch);
        }
      }

      // Update cache
      _cachedPatches = patches;
      _cacheValid = true;

      return List<LocalPatch>.from(patches);
    } catch (e) {
      throw LocalLibraryException('Failed to load library: $e');
    }
  }

  /// Delete a patch from local library
  Future<void> deletePatch(String id) async {
    _ensureInitialized();

    try {
      final binFile = File(path.join(_patchesDir!.path, '$id.bin'));
      final jsonFile = File(path.join(_patchesDir!.path, '$id.json'));

      if (await binFile.exists()) {
        await binFile.delete();
      }
      if (await jsonFile.exists()) {
        await jsonFile.delete();
      }

      // Invalidate cache since data changed
      _cacheValid = false;

      // Update index
      await _updateIndex();
    } catch (e) {
      throw LocalLibraryException('Failed to delete patch (ID: $id): $e');
    }
  }

  /// Export a single patch to .podpatch file
  Future<void> exportPatchToFile(LocalPatch patch, String filePath) async {
    try {
      // Create a combined JSON+binary format
      final exportData = {
        'format': 'podpatch',
        'version': 1,
        'patch': patch.toJson(),
        'patchData': base64Encode(patch.patch.data),
      };

      final file = File(filePath);
      await file.writeAsString(jsonEncode(exportData));
    } catch (e) {
      throw LocalLibraryException('Failed to export patch "${patch.patch.name}": $e');
    }
  }

  /// Import a single patch from .podpatch file
  Future<LocalPatch> importPatchFromFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw LocalLibraryException('File not found: $filePath');
      }

      final jsonData = await file.readAsString();
      final data = jsonDecode(jsonData) as Map<String, dynamic>;

      if (data['format'] != 'podpatch') {
        throw LocalLibraryException('Invalid file format');
      }

      final patchData = base64Decode(data['patchData'] as String);
      final patch = Patch.fromData(patchData);

      return LocalPatch.fromJson(data['patch'] as Map<String, dynamic>, patch);
    } catch (e) {
      throw LocalLibraryException('Failed to import patch from file: $e');
    }
  }

  /// Export multiple patches to .podlibrary file
  Future<void> exportLibraryToFile(List<LocalPatch> patches, String filePath) async {
    try {
      final exportData = {
        'format': 'podlibrary',
        'version': 1,
        'patchCount': patches.length,
        'exportedAt': DateTime.now().toIso8601String(),
        'patches': patches.map((p) {
          return {
            'metadata': p.toJson(),
            'patchData': base64Encode(p.patch.data),
          };
        }).toList(),
      };

      final file = File(filePath);
      await file.writeAsString(jsonEncode(exportData));
    } catch (e) {
      throw LocalLibraryException('Failed to export library: $e');
    }
  }

  /// Import multiple patches from .podlibrary file
  Future<List<LocalPatch>> importLibraryFromFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw LocalLibraryException('File not found: $filePath');
      }

      final jsonData = await file.readAsString();
      final data = jsonDecode(jsonData) as Map<String, dynamic>;

      if (data['format'] != 'podlibrary') {
        throw LocalLibraryException('Invalid file format');
      }

      final patchesData = data['patches'] as List<dynamic>;
      final patches = <LocalPatch>[];

      for (final patchData in patchesData) {
        final patchMap = patchData as Map<String, dynamic>;
        final binaryData = base64Decode(patchMap['patchData'] as String);
        final patch = Patch.fromData(binaryData);
        final metadata = patchMap['metadata'] as Map<String, dynamic>;

        patches.add(LocalPatch.fromJson(metadata, patch));
      }

      return patches;
    } catch (e) {
      throw LocalLibraryException('Failed to import library from file: $e');
    }
  }

  /// Update the library index file
  Future<void> _updateIndex() async {
    _ensureInitialized();

    try {
      final patches = await loadAllPatches();

      final indexData = {
        'version': 1,
        'updatedAt': DateTime.now().toIso8601String(),
        'patchCount': patches.length,
        'patches': patches.map((p) => {
          'id': p.id,
          'name': p.patch.name,
        }).toList(),
      };

      final indexFile = File('${_libraryDir!.path}/$_indexFileName');
      await indexFile.writeAsString(jsonEncode(indexData));
    } catch (e) {
      // Index update is non-critical, silently ignore errors
    }
  }

  /// Get library statistics
  Future<LibraryStats> getStats() async {
    _ensureInitialized();

    try {
      final patches = await loadAllPatches();
      int totalSize = 0;

      // Calculate total storage size
      final patchFiles = await _patchesDir!.list().toList();
      for (final file in patchFiles.whereType<File>()) {
        totalSize += await file.length();
      }

      return LibraryStats(
        patchCount: patches.length,
        totalSizeBytes: totalSize,
        favoriteCount: patches.where((p) => p.metadata.favorite).length,
      );
    } catch (e) {
      throw LocalLibraryException('Failed to get library stats: $e');
    }
  }

  /// Clear all patches from local library
  Future<void> clearLibrary() async {
    _ensureInitialized();

    try {
      final patchFiles = await _patchesDir!.list().toList();
      for (final file in patchFiles) {
        await file.delete();
      }

      // Invalidate cache since data changed
      _cacheValid = false;

      await _updateIndex();
    } catch (e) {
      throw LocalLibraryException('Failed to clear library: $e');
    }
  }

  /// Invalidate the cache to force reload on next loadAllPatches()
  void invalidateCache() {
    _cacheValid = false;
  }
}

/// Library statistics
class LibraryStats {
  final int patchCount;
  final int totalSizeBytes;
  final int favoriteCount;

  LibraryStats({
    required this.patchCount,
    required this.totalSizeBytes,
    required this.favoriteCount,
  });

  /// Get human-readable size
  String get sizeFormatted {
    if (totalSizeBytes < 1024) {
      return '$totalSizeBytes B';
    } else if (totalSizeBytes < 1024 * 1024) {
      return '${(totalSizeBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(totalSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}

/// Custom exception for library operations
class LocalLibraryException implements Exception {
  final String message;
  LocalLibraryException(this.message);

  @override
  String toString() => 'LocalLibraryException: $message';
}
