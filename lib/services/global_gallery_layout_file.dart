import 'global_gallery_layout_file_stub.dart'
    if (dart.library.js_interop) 'global_gallery_layout_file_web.dart';

abstract interface class GlobalGalleryLayoutFile {
  String? get fileName;

  Future<void> save(String contents);
}

GlobalGalleryLayoutFile createGlobalGalleryLayoutFile() =>
    createPlatformGlobalGalleryLayoutFile();
