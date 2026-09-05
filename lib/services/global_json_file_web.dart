@JS()
library;

import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'global_json_file.dart';

@JS()
extension type _SaveFilePickerOptions._(JSObject _) implements JSObject {
  external factory _SaveFilePickerOptions({String suggestedName});
}

@JS('showSaveFilePicker')
external JSPromise<web.FileSystemFileHandle> _showSaveFilePicker(
  _SaveFilePickerOptions options,
);

GlobalJsonFile createPlatformGlobalJsonFile(String suggestedName) =>
    _WebGlobalJsonFile(suggestedName);

class _WebGlobalJsonFile implements GlobalJsonFile {
  _WebGlobalJsonFile(this._suggestedName);

  final String _suggestedName;
  web.FileSystemFileHandle? _handle;

  @override
  String? get fileName => _handle?.name;

  @override
  Future<void> save(String contents) async {
    final handle =
        _handle ??
        await _showSaveFilePicker(
          _SaveFilePickerOptions(suggestedName: _suggestedName),
        ).toDart;
    _handle = handle;
    final writable = await handle.createWritable().toDart;
    await writable.write(contents.toJS).toDart;
    await writable.close().toDart;
  }
}
