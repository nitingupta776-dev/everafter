import 'package:everafter/data/japan_memory_collection.dart';

import 'external_memory_scanner_stub.dart'
    if (dart.library.io) 'external_memory_scanner_io.dart';

/// Reads a trip's photos/videos live off a real filesystem folder (e.g. an
/// SD card mounted on a deployed Linux kiosk) instead of requiring them to
/// be bundled Flutter assets and hand-registered in `memory_collections.json`.
///
/// Web builds have no filesystem access, so [scan] always returns an empty
/// list there; [ExternalMemoryScanner] on non-web platforms uses `dart:io`.
abstract interface class ExternalMemoryScanner {
  /// True on platforms that can actually read `rootPath` (i.e. not web).
  bool get isSupported;

  /// Scans `<rootPath>/<memoriesFolder>/` and returns its contents as one
  /// [JapanMemoryLocation] per subfolder, or a single location named after
  /// [tripName] if the folder holds files directly. Returns an empty list
  /// if the folder doesn't exist or [isSupported] is false.
  List<JapanMemoryLocation> scan({
    required String rootPath,
    required String memoriesFolder,
    required String tripName,
  });
}

ExternalMemoryScanner createExternalMemoryScanner() =>
    createPlatformExternalMemoryScanner();
