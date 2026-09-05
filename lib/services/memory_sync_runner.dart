import 'memory_sync_runner_stub.dart'
    if (dart.library.io) 'memory_sync_runner_io.dart';

/// Result of running the memory-folder sync.
class MemorySyncResult {
  const MemorySyncResult({required this.output, required this.success});
  final String output;
  final bool success;
}

abstract interface class MemorySyncRunner {
  /// Whether this platform can actually execute the sync script.
  bool get isSupported;

  /// Runs the sync and returns its output.
  Future<MemorySyncResult> run();
}

MemorySyncRunner createMemorySyncRunner() => createPlatformMemorySyncRunner();
