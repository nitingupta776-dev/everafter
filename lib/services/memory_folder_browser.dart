import 'memory_folder_browser_stub.dart'
    if (dart.library.js_interop) 'memory_folder_browser_web.dart';

/// A photo or video file picked from the user's real file system, used by
/// the trip admin screen to register memories without hand-typing paths.
class MemoryFolderFile {
  const MemoryFolderFile({
    required this.fileName,
    required this.previewUrl,
    required this.isVideo,
  });

  final String fileName;

  /// A URL the current platform can render directly (e.g. a blob: URL on
  /// web). Not a bundled asset path.
  final String previewUrl;
  final bool isVideo;
}

abstract interface class MemoryFolderBrowser {
  bool get isSupported;

  /// Opens the platform's native file picker and returns the photo/video
  /// files the user selected, or an empty list if they cancelled.
  Future<List<MemoryFolderFile>> choosePhotos();
}

MemoryFolderBrowser createMemoryFolderBrowser() =>
    createPlatformMemoryFolderBrowser();

const memoryFileExtensions = <String>{
  'jpg',
  'jpeg',
  'png',
  'heic',
  'gif',
  'webp',
  'mp4',
  'mov',
};

const memoryVideoExtensions = <String>{'mp4', 'mov'};

bool isRecognizedMemoryFile(String fileName) {
  final extension = _extensionOf(fileName);
  return memoryFileExtensions.contains(extension);
}

bool isVideoMemoryFile(String fileName) {
  return memoryVideoExtensions.contains(_extensionOf(fileName));
}

String _extensionOf(String fileName) {
  final dotIndex = fileName.lastIndexOf('.');
  if (dotIndex == -1 || dotIndex == fileName.length - 1) {
    return '';
  }
  return fileName.substring(dotIndex + 1).toLowerCase();
}
