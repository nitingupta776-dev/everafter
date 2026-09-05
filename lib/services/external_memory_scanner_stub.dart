import 'package:everafter/data/japan_memory_collection.dart';

import 'external_memory_scanner.dart';

ExternalMemoryScanner createPlatformExternalMemoryScanner() =>
    const _UnsupportedExternalMemoryScanner();

class _UnsupportedExternalMemoryScanner implements ExternalMemoryScanner {
  const _UnsupportedExternalMemoryScanner();

  @override
  bool get isSupported => false;

  @override
  List<JapanMemoryLocation> scan({
    required String rootPath,
    required String memoriesFolder,
    required String tripName,
  }) => const <JapanMemoryLocation>[];
}
