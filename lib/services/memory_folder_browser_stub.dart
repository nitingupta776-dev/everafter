import 'memory_folder_browser.dart';

MemoryFolderBrowser createPlatformMemoryFolderBrowser() =>
    const _UnsupportedMemoryFolderBrowser();

class _UnsupportedMemoryFolderBrowser implements MemoryFolderBrowser {
  const _UnsupportedMemoryFolderBrowser();

  @override
  bool get isSupported => false;

  @override
  Future<List<MemoryFolderFile>> choosePhotos() => throw UnsupportedError(
    'Choosing photos from disk is only available in the web admin build.',
  );
}
