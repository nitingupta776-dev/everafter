import 'package:flutter/widgets.dart';

/// Web has no filesystem access; the live SD-card scan never runs there, so
/// this should never actually be reached, but return a harmless fallback
/// asset rather than crash if it somehow is.
ImageProvider createExternalFileImageProvider(String path) {
  return const AssetImage('assets/images/experience/earth-globe-fallback.png');
}
