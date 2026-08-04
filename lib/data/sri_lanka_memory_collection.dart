import 'package:everafter/data/japan_memory_collection.dart';
import 'package:everafter/data/public_demo_assets.dart';

JapanMemoryLocation _sriLankaHighlightLocation({
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

final List<JapanMemoryLocation> sriLankaMemoryLocations = <JapanMemoryLocation>[
  _sriLankaHighlightLocation(
    slug: 'galle-fort',
    label: 'Galle Fort',
    sequences: <int>[1, 2, 3, 4, 5, 6, 7],
  ),
  _sriLankaHighlightLocation(
    slug: 'unawatuna-coast',
    label: 'Unawatuna Coast',
    sequences: <int>[8, 9, 10, 11, 12, 13, 14, 15, 16],
  ),
  _sriLankaHighlightLocation(
    slug: 'mirissa-weligama',
    label: 'Mirissa & Weligama',
    sequences: <int>[17, 18, 19, 20, 21, 22, 23, 24],
  ),
  _sriLankaHighlightLocation(
    slug: 'ahangama-koggala',
    label: 'Ahangama & Koggala',
    sequences: <int>[25, 26, 27, 28, 29],
  ),
];
