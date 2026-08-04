import 'package:everafter/data/japan_memory_collection.dart';
import 'package:everafter/data/public_demo_assets.dart';

JapanMemoryLocation _southKoreaHighlightLocation({
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

final List<JapanMemoryLocation> southKoreaMemoryLocations =
    <JapanMemoryLocation>[
      _southKoreaHighlightLocation(
        slug: 'seoul',
        label: 'Seoul',
        timeline: 'pppppppppvvppvppppppppvppppppppp',
      ),
      _southKoreaHighlightLocation(
        slug: 'incheon',
        label: 'Incheon',
        timeline: 'pvppppppvvvpvpvppppv',
      ),
      _southKoreaHighlightLocation(
        slug: 'jeju',
        label: 'Jeju',
        timeline: 'pppppppvpppppppvpvvpp',
      ),
      _southKoreaHighlightLocation(
        slug: 'gyeongju',
        label: 'Gyeongju',
        timeline: 'ppvpppppppvvpppvppppv',
      ),
      _southKoreaHighlightLocation(
        slug: 'busan',
        label: 'Busan',
        timeline: 'vvvvvvvvvpvvpvpppp',
      ),
    ];
