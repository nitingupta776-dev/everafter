import 'package:everafter/data/japan_memory_collection.dart';
import 'package:everafter/data/public_demo_assets.dart';

JapanMemoryLocation _hongKongHighlightLocation({
  required String slug,
  required String label,
  required List<int> sequences,
}) {
  return JapanMemoryLocation(
    slug: slug,
    label: label,
    assetPaths: publicMemoryPlaceholders(sequences.length),
  );
}

final List<JapanMemoryLocation> hongKongMemoryLocations = <JapanMemoryLocation>[
  _hongKongHighlightLocation(
    slug: 'arrival-lantau',
    label: 'Arrival & Lantau',
    sequences: <int>[1, 2, 3, 4],
  ),
  _hongKongHighlightLocation(
    slug: 'central-wan-chai',
    label: 'Central & Wan Chai',
    sequences: <int>[5, 6, 7, 8, 9, 18, 19, 20],
  ),
  _hongKongHighlightLocation(
    slug: 'victoria-peak-high-west',
    label: 'Victoria Peak & High West',
    sequences: <int>[10, 11, 12, 13, 14, 15, 16, 17],
  ),
  _hongKongHighlightLocation(
    slug: 'victoria-harbour',
    label: 'Victoria Harbour',
    sequences: <int>[21, 22, 23, 24, 25],
  ),
  _hongKongHighlightLocation(
    slug: 'dragons-back-big-wave-bay',
    label: "Dragon's Back & Big Wave Bay",
    sequences: <int>[26, 27, 28, 29, 30, 31, 32, 33, 34],
  ),
  _hongKongHighlightLocation(
    slug: 'city-stay-dining',
    label: 'City Stay & Dining',
    sequences: <int>[35, 36, 37, 41],
  ),
  _hongKongHighlightLocation(
    slug: 'hong-kong-disneyland',
    label: 'Hong Kong Disneyland',
    sequences: <int>[38, 39, 40],
  ),
];
