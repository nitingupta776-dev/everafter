import 'package:everafter/data/public_demo_assets.dart';

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

JapanMemoryLocation _demoLocation({
  required String slug,
  required String label,
  required int itemCount,
}) {
  return JapanMemoryLocation(
    slug: slug,
    label: label,
    assetPaths: publicMemoryPlaceholders(itemCount),
  );
}

final List<JapanMemoryLocation> japanMemoryLocations = <JapanMemoryLocation>[
  _demoLocation(slug: 'tokyo', label: 'Tokyo', itemCount: 66),
  _demoLocation(slug: 'kyoto', label: 'Kyoto', itemCount: 38),
  _demoLocation(slug: 'osaka', label: 'Osaka', itemCount: 9),
  _demoLocation(slug: 'nara', label: 'Nara', itemCount: 10),
  _demoLocation(slug: 'hiroshima', label: 'Hiroshima', itemCount: 11),
  _demoLocation(slug: 'ueno-park', label: 'Ueno Park', itemCount: 5),
  _demoLocation(slug: 'akihabara', label: 'Akihabara', itemCount: 1),
  _demoLocation(slug: 'nezu-shrine', label: 'Nezu Shrine', itemCount: 5),
  _demoLocation(
    slug: 'asakusa-sumida',
    label: 'Asakusa & Sumida River',
    itemCount: 6,
  ),
  _demoLocation(slug: 'kiyomizu-dera', label: 'Kiyomizu-dera', itemCount: 10),
  _demoLocation(slug: 'arashiyama', label: 'Arashiyama', itemCount: 11),
  _demoLocation(slug: 'midosuji', label: 'Midosuji', itemCount: 2),
  _demoLocation(slug: 'osaka-castle', label: 'Osaka Castle', itemCount: 4),
  _demoLocation(slug: 'takayama', label: 'Takayama', itemCount: 7),
  _demoLocation(slug: 'shirakawa-go', label: 'Shirakawa-go', itemCount: 6),
  _demoLocation(
    slug: 'tokyo-disney-resort',
    label: 'Tokyo Disney Resort',
    itemCount: 6,
  ),
];
