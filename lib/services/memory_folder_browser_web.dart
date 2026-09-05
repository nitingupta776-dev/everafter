@JS()
library;

import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'memory_folder_browser.dart';

@JS()
extension type _OpenFilePickerOptions._(JSObject _) implements JSObject {
  external factory _OpenFilePickerOptions({bool multiple});
}

@JS('showOpenFilePicker')
external JSPromise<JSArray<web.FileSystemFileHandle>> _showOpenFilePicker(
  _OpenFilePickerOptions options,
);

MemoryFolderBrowser createPlatformMemoryFolderBrowser() =>
    const _WebMemoryFolderBrowser();

class _WebMemoryFolderBrowser implements MemoryFolderBrowser {
  const _WebMemoryFolderBrowser();

  @override
  bool get isSupported => true;

  @override
  Future<List<MemoryFolderFile>> choosePhotos() async {
    final JSArray<web.FileSystemFileHandle> handles;
    try {
      handles = await _showOpenFilePicker(
        _OpenFilePickerOptions(multiple: true),
      ).toDart;
    } on Object {
      // The user cancelled the picker.
      return const <MemoryFolderFile>[];
    }

    final files = <MemoryFolderFile>[];
    for (final handle in handles.toDart) {
      final file = await handle.getFile().toDart;
      if (!isRecognizedMemoryFile(file.name)) {
        continue;
      }
      files.add(
        MemoryFolderFile(
          fileName: file.name,
          previewUrl: web.URL.createObjectURL(file),
          isVideo: isVideoMemoryFile(file.name),
        ),
      );
    }
    return files;
  }
}
