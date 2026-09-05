enum JapanMemoryKind { photo, video }

class JapanMemoryAsset {
  const JapanMemoryAsset({
    required this.assetPath,
    required this.kind,
    this.posterAssetPath,
    this.alignmentX,
    this.alignmentY,
    this.zoom = 1,
  });

  final String assetPath;
  final JapanMemoryKind kind;
  final String? posterAssetPath;
  final double? alignmentX;
  final double? alignmentY;
  final double zoom;

  bool get isVideo => kind == JapanMemoryKind.video;
  String get displayAssetPath => posterAssetPath ?? assetPath;
}

class JapanMemoryLocation {
  const JapanMemoryLocation({
    required this.slug,
    required this.label,
    required this.assetPaths,
    this.videoPosterPaths = const <String, String>{},
  });

  final String slug;
  final String label;
  final List<String> assetPaths;
  final Map<String, String> videoPosterPaths;

  Map<String, Object?> toJson() => <String, Object?>{
    'slug': slug,
    'label': label,
    'assetPaths': assetPaths,
    'videoPosterPaths': videoPosterPaths,
  };

  factory JapanMemoryLocation.fromJson(Map<String, dynamic> json) {
    return JapanMemoryLocation(
      slug: json['slug'] as String,
      label: json['label'] as String,
      assetPaths: (json['assetPaths'] as List<dynamic>).cast<String>(),
      videoPosterPaths:
          (json['videoPosterPaths'] as Map<dynamic, dynamic>? ??
                  const <dynamic, dynamic>{})
              .map((key, value) => MapEntry(key as String, value as String)),
    );
  }

  List<JapanMemoryAsset> get media => assetPaths
      .map(
        (assetPath) => JapanMemoryAsset(
          assetPath: assetPath,
          kind: videoPosterPaths.containsKey(assetPath)
              ? JapanMemoryKind.video
              : JapanMemoryKind.photo,
          posterAssetPath: videoPosterPaths[assetPath],
        ),
      )
      .toList(growable: false);

  int get photoCount => assetPaths.length - videoPosterPaths.length;
  int get videoCount => videoPosterPaths.length;
}
