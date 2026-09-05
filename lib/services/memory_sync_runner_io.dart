import 'dart:io';

import 'memory_sync_runner.dart';

MemorySyncRunner createPlatformMemorySyncRunner() => const _IoRunner();

class _IoRunner implements MemorySyncRunner {
  const _IoRunner();

  @override
  bool get isSupported => true;

  @override
  Future<MemorySyncResult> run() async {
    final projectRoot = Directory.current.path;
    final scriptPath = '$projectRoot/tool/sync_memory_collections.py';

    if (!File(scriptPath).existsSync()) {
      return MemorySyncResult(
        output: 'Script not found at $scriptPath',
        success: false,
      );
    }

    final result = await Process.run(
      'python3',
      [scriptPath],
      workingDirectory: projectRoot,
      runInShell: true,
    );

    final output =
        (result.stdout as String).trim().isNotEmpty
        ? (result.stdout as String).trim()
        : (result.stderr as String).trim();

    return MemorySyncResult(output: output, success: result.exitCode == 0);
  }
}
