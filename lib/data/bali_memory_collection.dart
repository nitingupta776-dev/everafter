import 'package:everafter/data/japan_memory_collection.dart';
import 'package:everafter/data/public_demo_assets.dart';

JapanMemoryLocation _baliHighlightGroup({
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

final List<JapanMemoryLocation> baliMemoryLocations = <JapanMemoryLocation>[
  _baliHighlightGroup(
    slug: 'cliffs-temples-islands',
    label: 'Cliffs, Temples & Islands',
    sequences: <int>[2, 10, 18, 21],
  ),
  _baliHighlightGroup(
    slug: 'beaches-sunsets',
    label: 'Beaches & Sunsets',
    sequences: <int>[4, 7, 14, 15],
  ),
  _baliHighlightGroup(
    slug: 'villa-island-days',
    label: 'Villa & Island Days',
    sequences: <int>[6, 9, 11, 13, 16],
  ),
  _baliHighlightGroup(
    slug: 'food-beach-clubs-nights',
    label: 'Food, Beach Clubs & Nights',
    sequences: <int>[1, 3, 5, 8, 12, 17, 19, 20],
  ),
];
