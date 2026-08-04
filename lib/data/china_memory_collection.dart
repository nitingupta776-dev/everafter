import 'package:everafter/data/japan_memory_collection.dart';
import 'package:everafter/data/public_demo_assets.dart';

JapanMemoryLocation _chinaHighlightLocation({
  required String slug,
  required String label,
  required String timeline,
}) {
  return JapanMemoryLocation(
    slug: slug,
    label: label,
    assetPaths: publicMemoryPlaceholders(timeline.length),
  );
}

final List<JapanMemoryLocation> chinaMemoryLocations = <JapanMemoryLocation>[
  _chinaHighlightLocation(
    slug: 'great-wall',
    label: 'Great Wall of China',
    timeline: 'pppvvvvv',
  ),
  _chinaHighlightLocation(
    slug: 'beijing',
    label: 'Beijing',
    timeline: 'pvppppp',
  ),
  _chinaHighlightLocation(
    slug: 'shanghai',
    label: 'Shanghai',
    timeline: 'pppppvppppppppp',
  ),
  _chinaHighlightLocation(
    slug: 'chongqing',
    label: 'Chongqing',
    timeline: 'vppppppvpppvvppvpppppppppppvpv',
  ),
];
