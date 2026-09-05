import 'dart:io';

import 'package:everafter/data/japan_memory_collection.dart';
import 'package:everafter/services/memory_folder_browser.dart';

import 'external_memory_scanner.dart';

ExternalMemoryScanner createPlatformExternalMemoryScanner() =>
    const _IoExternalMemoryScanner();

class _IoExternalMemoryScanner implements ExternalMemoryScanner {
  const _IoExternalMemoryScanner();

  @override
  bool get isSupported => true;

  @override
  List<JapanMemoryLocation> scan({
    required String rootPath,
    required String memoriesFolder,
    required String tripName,
  }) {
    final tripDirectory = Directory(_join(rootPath, memoriesFolder));
    if (!tripDirectory.existsSync()) {
      return const <JapanMemoryLocation>[];
    }

    final entries = tripDirectory.listSync();
    final subfolders = entries.whereType<Directory>().toList(growable: false)
      ..sort((a, b) => a.path.compareTo(b.path));
    final looseFiles = entries.whereType<File>().toList(growable: false);

    final locations = <JapanMemoryLocation>[];

    if (looseFiles.any((file) => isRecognizedMemoryFile(file.path))) {
      final location = _locationFor(
        directory: tripDirectory,
        slug: '${_slugify(tripName)}-trip',
        label: tripName,
      );
      if (location.assetPaths.isNotEmpty) {
        locations.add(location);
      }
    }

    for (final subfolder in subfolders) {
      final name = _baseName(subfolder.path);
      final location = _locationFor(
        directory: subfolder,
        slug: _slugify(name),
        label: _titleCase(name),
      );
      if (location.assetPaths.isNotEmpty) {
        locations.add(location);
      }
    }

    return locations;
  }

  JapanMemoryLocation _locationFor({
    required Directory directory,
    required String slug,
    required String label,
  }) {
    final files =
        directory
            .listSync()
            .whereType<File>()
            .where((file) => isRecognizedMemoryFile(file.path))
            .toList(growable: false)
          ..sort((a, b) => a.path.compareTo(b.path));

    final assetPaths = <String>[];
    final videoPosterPaths = <String, String>{};
    final filesByName = <String, File>{
      for (final file in files) _baseName(file.path): file,
    };

    for (final file in files) {
      final path = file.path;
      assetPaths.add(path);
      if (!isVideoMemoryFile(path)) continue;

      final withoutExtension = _withoutExtension(_baseName(path));
      for (final posterExtension in const <String>['jpg', 'jpeg', 'png']) {
        final candidateName = '$withoutExtension-poster.$posterExtension';
        final candidate = filesByName[candidateName];
        if (candidate != null) {
          videoPosterPaths[path] = candidate.path;
          break;
        }
      }
    }

    return JapanMemoryLocation(
      slug: slug,
      label: label,
      assetPaths: assetPaths,
      videoPosterPaths: videoPosterPaths,
    );
  }
}

String _join(String root, String child) {
  final trimmedRoot = root.endsWith('/') || root.endsWith('\\')
      ? root.substring(0, root.length - 1)
      : root;
  return '$trimmedRoot/$child';
}

String _baseName(String path) {
  final normalized = path.replaceAll('\\', '/');
  final lastSlash = normalized.lastIndexOf('/');
  return lastSlash == -1 ? normalized : normalized.substring(lastSlash + 1);
}

String _withoutExtension(String fileName) {
  final dotIndex = fileName.lastIndexOf('.');
  return dotIndex == -1 ? fileName : fileName.substring(0, dotIndex);
}

String _slugify(String value) {
  final slug = value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return slug.isEmpty ? 'location' : slug;
}

String _titleCase(String value) {
  final words = value
      .replaceAll('_', ' ')
      .replaceAll('-', ' ')
      .split(' ')
      .where((word) => word.isNotEmpty);
  return words
      .map((word) => word[0].toUpperCase() + word.substring(1))
      .join(' ');
}
