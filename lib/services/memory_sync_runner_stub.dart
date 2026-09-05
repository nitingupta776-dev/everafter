import 'memory_sync_runner.dart';

MemorySyncRunner createPlatformMemorySyncRunner() => const _StubRunner();

class _StubRunner implements MemorySyncRunner {
  const _StubRunner();

  @override
  bool get isSupported => false;

  @override
  Future<MemorySyncResult> run() async =>
      const MemorySyncResult(output: '', success: false);
}
