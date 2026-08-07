import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

class GalleryTrinketImage extends StatelessWidget {
  const GalleryTrinketImage({
    required this.source,
    this.fit = BoxFit.contain,
    this.filterQuality = FilterQuality.medium,
    this.isAntiAlias = false,
    this.excludeFromSemantics = false,
    super.key,
  });

  final String source;
  final BoxFit fit;
  final FilterQuality filterQuality;
  final bool isAntiAlias;
  final bool excludeFromSemantics;

  @override
  Widget build(BuildContext context) {
    if (source.startsWith('data:image/')) {
      return Image.memory(
        _decodeDataImage(source),
        fit: fit,
        filterQuality: filterQuality,
        isAntiAlias: isAntiAlias,
        excludeFromSemantics: excludeFromSemantics,
        gaplessPlayback: true,
      );
    }
    if (source.startsWith('assets/')) {
      return Image.asset(
        source,
        fit: fit,
        filterQuality: filterQuality,
        isAntiAlias: isAntiAlias,
        excludeFromSemantics: excludeFromSemantics,
      );
    }
    return const SizedBox.shrink();
  }
}

Uint8List _decodeDataImage(String source) {
  final separator = source.indexOf(',');
  if (separator < 0) {
    return Uint8List(0);
  }
  return base64Decode(source.substring(separator + 1));
}
