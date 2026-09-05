import 'package:flutter/widgets.dart';

import 'memory_image_stub.dart' if (dart.library.io) 'memory_image_io.dart';

/// Whether [path] is a Flutter bundled asset (`assets/...`) rather than a
/// real filesystem path (e.g. a photo read live off an SD card).
bool isBundledAssetPath(String path) => path.startsWith('assets/');

/// An [ImageProvider] for a memory photo path, whichever kind it is.
ImageProvider memoryImageProvider(String path) => isBundledAssetPath(path)
    ? AssetImage(path)
    : createExternalFileImageProvider(path);

/// An [Image] widget for a memory photo path, whichever kind it is.
Image memoryImage(
  String path, {
  BoxFit? fit,
  AlignmentGeometry alignment = Alignment.center,
  FilterQuality filterQuality = FilterQuality.low,
  bool excludeFromSemantics = false,
  double? width,
  double? height,
  Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
}) {
  return Image(
    image: memoryImageProvider(path),
    fit: fit,
    alignment: alignment,
    filterQuality: filterQuality,
    excludeFromSemantics: excludeFromSemantics,
    width: width,
    height: height,
    errorBuilder: errorBuilder,
  );
}
