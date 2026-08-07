import 'global_gallery_layout_file.dart';

GlobalGalleryLayoutFile createPlatformGlobalGalleryLayoutFile() =>
    const _UnsupportedGlobalGalleryLayoutFile();

class _UnsupportedGlobalGalleryLayoutFile implements GlobalGalleryLayoutFile {
  const _UnsupportedGlobalGalleryLayoutFile();

  @override
  String? get fileName => null;

  @override
  Future<void> save(String contents) => throw UnsupportedError(
    'The global layout source file can only be edited in a supported browser.',
  );
}
