import 'global_json_file.dart';

GlobalJsonFile createPlatformGlobalJsonFile(String suggestedName) =>
    const _UnsupportedGlobalJsonFile();

class _UnsupportedGlobalJsonFile implements GlobalJsonFile {
  const _UnsupportedGlobalJsonFile();

  @override
  String? get fileName => null;

  @override
  Future<void> save(String contents) => throw UnsupportedError(
    'The global source file can only be edited in a supported browser.',
  );
}
