import 'package:everafter/data/japan_memory_collection.dart';
import 'package:everafter/data/public_demo_assets.dart';

JapanMemoryLocation _taiwanHighlightLocation({
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

final List<JapanMemoryLocation> taiwanMemoryLocations = <JapanMemoryLocation>[
  _taiwanHighlightLocation(
    slug: 'taipei-arrival-city',
    label: 'Taipei Arrival & City',
    sequences: <int>[1, 2, 3, 4, 5, 6, 7, 13, 20, 21, 22],
  ),
  _taiwanHighlightLocation(
    slug: 'jiufen',
    label: 'Jiufen',
    sequences: <int>[8, 9, 10, 11, 12],
  ),
  _taiwanHighlightLocation(
    slug: 'cingjing-farm',
    label: 'Cingjing Farm',
    sequences: <int>[14, 15, 16, 17],
  ),
  _taiwanHighlightLocation(
    slug: 'sun-moon-lake',
    label: 'Sun Moon Lake',
    sequences: <int>[18, 19],
  ),
  _taiwanHighlightLocation(
    slug: 'grand-hotel-taipei',
    label: 'Grand Hotel Taipei',
    sequences: <int>[23, 24, 25],
  ),
  _taiwanHighlightLocation(
    slug: 'kaohsiung-qijin',
    label: 'Kaohsiung & Qijin',
    sequences: <int>[26, 27, 28, 29, 30, 31],
  ),
];
