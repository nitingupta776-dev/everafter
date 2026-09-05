import 'global_json_file_stub.dart'
    if (dart.library.js_interop) 'global_json_file_web.dart';

abstract interface class GlobalJsonFile {
  String? get fileName;

  Future<void> save(String contents);
}

GlobalJsonFile createGlobalJsonFile(String suggestedName) =>
    createPlatformGlobalJsonFile(suggestedName);
