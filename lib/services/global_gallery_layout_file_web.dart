@JS()
library;

import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'global_gallery_layout_file.dart';

@JS()
extension type _SaveFilePickerOptions._(JSObject _) implements JSObject {
  external factory _SaveFilePickerOptions({String suggestedName});
}

@JS('showSaveFilePicker')
external JSPromise<web.FileSystemFileHandle> _showSaveFilePicker(
  _SaveFilePickerOptions options,
);

GlobalGalleryLayoutFile createPlatformGlobalGalleryLayoutFile() =>
    _WebGlobalGalleryLayoutFile();

class _WebGlobalGalleryLayoutFile implements GlobalGalleryLayoutFile {
  web.FileSystemFileHandle? _handle;

  @override
  String? get fileName => _handle?.name;

  @override
  Future<void> save(String contents) async {
    final handle =
        _handle ??
        await _showSaveFilePicker(
          _SaveFilePickerOptions(suggestedName: 'gallery_layouts.json'),
        ).toDart;
    _handle = handle;
    final writable = await handle.createWritable().toDart;
    await writable.write(contents.toJS).toDart;
    await writable.close().toDart;
  }
}
