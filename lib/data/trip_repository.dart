import 'package:everafter/models/travel_artifact.dart';
import 'package:everafter/theme/everafter_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final tripRepositoryProvider = Provider<TripRepository>((ref) {
  return const TripRepository();
});

class TripRepository {
  const TripRepository();

  List<TravelArtifact> get artifacts => _artifacts;

  TravelArtifact? findByUid(String uid) {
    for (final artifact in _artifacts) {
      if (artifact.uid == uid) {
        return artifact;
      }
    }
    return null;
  }

  TravelArtifact artifactByUid(String uid) {
    return findByUid(uid) ?? _artifacts.first;
  }

  TravelArtifact get demoArtifact => _artifacts.first;
}

const _modelPath = 'models/fridge_magnet/fridge_magnet.glb';

const _artifacts = <TravelArtifact>[
  TravelArtifact(
    uid: '04:00:00:00:00:01',
    title: 'Fridge Magnet With Harbour Light',
    place: 'Hong Kong',
    country: 'China',
    dateLabel: 'Demo collection',
    coordinates: '22.3193 N, 114.1694 E',
    medium: 'Painted resin, ferrite, NFC tag',
    collection: 'Pacific crossings',
    accessionNumber: 'EA-DEMO-HKG-001',
    coverLine: 'A small skyline held the whole evening in miniature.',
    modelAsset: _modelPath,
    colors: <Color>[
      EverAfterColors.burgundy,
      EverAfterColors.brass,
      EverAfterColors.olive,
    ],
    chapters: <ExhibitChapter>[
      ExhibitChapter(
        kicker: 'Cover',
        title: 'The souvenir remembers the light first.',
        body:
            'The magnet arrived home with a little theatrical confidence: brass windows, red tramlines, and a harbor that still felt warm from the walk back.',
        detail: 'Demo NFC UID 04:00:00:00:00:01',
      ),
      ExhibitChapter(
        kicker: 'Journey',
        title: 'A route traced in receipts, rain, and ferry glass.',
        body:
            'The trip moved slowly through markets, museum rooms, steep streets, and late platforms. The object is less proof of place than a bookmark for the pace of being there.',
        detail: 'Collection note: pair with ambient audio after exhibit entry.',
      ),
      ExhibitChapter(
        kicker: 'End',
        title: 'Returned to the kitchen, still catalogued as elsewhere.',
        body:
            'On the fridge it becomes ordinary again. In EverAfter, the same object opens like a quiet gallery label and lets the journey breathe for a minute longer.',
        detail: 'Local exhibit. No cloud sync required.',
      ),
    ],
  ),
  TravelArtifact(
    uid: '04:00:00:00:00:02',
    title: 'China Travel Token',
    place: 'China',
    country: 'China',
    dateLabel: 'Demo collection',
    coordinates: '39.9042 N, 116.4074 E',
    medium: 'NFC tag',
    collection: 'Mainland journeys',
    accessionNumber: 'EA-DEMO-CHN-001',
    coverLine: 'A small token that opens the route across China.',
    modelAsset: _modelPath,
    colors: <Color>[
      EverAfterColors.burgundy,
      EverAfterColors.brass,
      EverAfterColors.warmBrown,
    ],
    chapters: <ExhibitChapter>[
      ExhibitChapter(
        kicker: 'Cover',
        title: 'The journey begins with a single tap.',
        body:
            'This NFC token opens the China travel collection, from the Great Wall through Beijing, Shanghai, and Chongqing.',
        detail: 'Demo NFC UID 04:00:00:00:00:02',
      ),
      ExhibitChapter(
        kicker: 'Journey',
        title: 'Four places held inside one route.',
        body:
            'The collection moves through mountain stone, city avenues, river light, and nights layered high above the streets.',
        detail: 'Collection note: China travel archive.',
      ),
      ExhibitChapter(
        kicker: 'End',
        title: 'The tag returns the journey to the room.',
        body:
            'A physical object becomes the doorway back into the photographs, films, and places gathered along the way.',
        detail: 'Local exhibit. No cloud sync required.',
      ),
    ],
  ),
  TravelArtifact(
    uid: '04:00:00:00:00:03',
    title: 'South Korea Travel Token',
    place: 'South Korea',
    country: 'South Korea',
    dateLabel: 'Demo collection',
    coordinates: '37.5665 N, 126.9780 E',
    medium: 'NFC tag',
    collection: 'Korean journeys',
    accessionNumber: 'EA-DEMO-KOR-001',
    coverLine: 'A small token that opens the route across South Korea.',
    modelAsset: _modelPath,
    colors: <Color>[
      EverAfterColors.olive,
      EverAfterColors.burgundy,
      EverAfterColors.brass,
    ],
    chapters: <ExhibitChapter>[
      ExhibitChapter(
        kicker: 'Cover',
        title: 'The journey begins with a single tap.',
        body:
            'This NFC token opens the South Korea travel collection, moving through Seoul, Incheon, Jeju, Gyeongju, and Busan.',
        detail: 'Demo NFC UID 04:00:00:00:00:03',
      ),
      ExhibitChapter(
        kicker: 'Journey',
        title: 'Five places held inside one route.',
        body:
            'The collection moves from city streets and harbor light to island coastlines, historic paths, and evenings beside the sea.',
        detail: 'Collection note: South Korea travel archive.',
      ),
      ExhibitChapter(
        kicker: 'End',
        title: 'The tag returns the journey to the room.',
        body:
            'A physical object becomes the doorway back into the photographs, films, and places gathered along the way.',
        detail: 'Local exhibit. No cloud sync required.',
      ),
    ],
  ),
  TravelArtifact(
    uid: '04:00:00:00:00:04',
    title: 'Japan Travel Token',
    place: 'Japan',
    country: 'Japan',
    dateLabel: 'Demo collection',
    coordinates: '35.6762 N, 139.6503 E',
    medium: 'NFC tag',
    collection: 'Japanese journeys',
    accessionNumber: 'EA-DEMO-JPN-001',
    coverLine: 'A small token that opens the route across Japan.',
    modelAsset: _modelPath,
    colors: <Color>[
      EverAfterColors.burgundy,
      EverAfterColors.olive,
      EverAfterColors.brass,
    ],
    chapters: <ExhibitChapter>[
      ExhibitChapter(
        kicker: 'Cover',
        title: 'The journey begins with a single tap.',
        body:
            'This NFC token opens the Japan travel collection, moving through Tokyo, Kyoto, Osaka, Nara, and Hiroshima.',
        detail: 'Demo NFC UID 04:00:00:00:00:04',
      ),
      ExhibitChapter(
        kicker: 'Journey',
        title: 'Five places held inside one route.',
        body:
            'The collection moves through temple paths, city crossings, quiet gardens, train windows, and evenings beneath lantern light.',
        detail: 'Collection note: Japan travel archive.',
      ),
      ExhibitChapter(
        kicker: 'End',
        title: 'The tag returns the journey to the room.',
        body:
            'A physical object becomes the doorway back into the photographs, films, and places gathered along the way.',
        detail: 'Local exhibit. No cloud sync required.',
      ),
    ],
  ),
  TravelArtifact(
    uid: '04:00:00:00:00:05',
    title: 'Taiwan Travel Token',
    place: 'Taiwan',
    country: 'Taiwan',
    dateLabel: 'Demo collection',
    coordinates: '25.0330 N, 121.5654 E',
    medium: 'NFC tag',
    collection: 'Taiwan journeys',
    accessionNumber: 'EA-DEMO-TWN-001',
    coverLine: 'A small token that opens the route through Taiwan.',
    modelAsset: _modelPath,
    colors: <Color>[
      EverAfterColors.brass,
      EverAfterColors.burgundy,
      EverAfterColors.olive,
    ],
    chapters: <ExhibitChapter>[
      ExhibitChapter(
        kicker: 'Cover',
        title: 'The journey begins with a single tap.',
        body:
            'This NFC token opens the Taiwan travel collection, returning to its streets, mountain views, markets, and quiet details.',
        detail: 'Demo NFC UID 04:00:00:00:00:05',
      ),
      ExhibitChapter(
        kicker: 'Journey',
        title: 'An island held inside one route.',
        body:
            'The collection moves through city light, temple courtyards, green horizons, shared meals, and the changing pace of the road.',
        detail: 'Collection note: Taiwan travel archive.',
      ),
      ExhibitChapter(
        kicker: 'End',
        title: 'The tag returns the journey to the room.',
        body:
            'A physical object becomes the doorway back into the photographs, films, and places gathered along the way.',
        detail: 'Local exhibit. No cloud sync required.',
      ),
    ],
  ),
  TravelArtifact(
    uid: '04:00:00:00:00:06',
    title: 'Bali Travel Token',
    place: 'Bali',
    country: 'Indonesia',
    dateLabel: 'Demo collection',
    coordinates: '8.4095 S, 115.1889 E',
    medium: 'NFC tag',
    collection: 'Island journeys',
    accessionNumber: 'EA-DEMO-BAL-001',
    coverLine: 'A small token that opens the route through Bali.',
    modelAsset: _modelPath,
    colors: <Color>[
      EverAfterColors.olive,
      EverAfterColors.brass,
      EverAfterColors.burgundy,
    ],
    chapters: <ExhibitChapter>[
      ExhibitChapter(
        kicker: 'Cover',
        title: 'The journey begins with a single tap.',
        body:
            'This NFC token opens the Bali travel collection, returning to its coastlines, temples, green interiors, and evening light.',
        detail: 'Demo NFC UID 04:00:00:00:00:06',
      ),
      ExhibitChapter(
        kicker: 'Journey',
        title: 'An island held inside one route.',
        body:
            'The collection moves through warm rain, carved stone, ocean roads, shared meals, and mornings surrounded by green.',
        detail: 'Collection note: Bali travel archive.',
      ),
      ExhibitChapter(
        kicker: 'End',
        title: 'The tag returns the journey to the room.',
        body:
            'A physical object becomes the doorway back into the photographs, films, and places gathered along the way.',
        detail: 'Local exhibit. No cloud sync required.',
      ),
    ],
  ),
  TravelArtifact(
    uid: '04:00:00:00:00:07',
    title: 'Thailand Travel Token',
    place: 'Thailand',
    country: 'Thailand',
    dateLabel: 'Demo collection',
    coordinates: '13.7563 N, 100.5018 E',
    medium: 'NFC tag',
    collection: 'Thai journeys',
    accessionNumber: 'EA-DEMO-THA-001',
    coverLine: 'A small token that opens the route through Thailand.',
    modelAsset: _modelPath,
    colors: <Color>[
      EverAfterColors.brass,
      EverAfterColors.olive,
      EverAfterColors.burgundy,
    ],
    chapters: <ExhibitChapter>[
      ExhibitChapter(
        kicker: 'Cover',
        title: 'The journey begins with a single tap.',
        body:
            'This NFC token opens the Thailand travel collection, returning to its temples, city streets, coastlines, and evening markets.',
        detail: 'Demo NFC UID 04:00:00:00:00:07',
      ),
      ExhibitChapter(
        kicker: 'Journey',
        title: 'A country held inside one route.',
        body:
            'The collection moves through gold-lit courtyards, river crossings, shared meals, tropical roads, and warm nights.',
        detail: 'Collection note: Thailand travel archive.',
      ),
      ExhibitChapter(
        kicker: 'End',
        title: 'The tag returns the journey to the room.',
        body:
            'A physical object becomes the doorway back into the photographs, films, and places gathered along the way.',
        detail: 'Local exhibit. No cloud sync required.',
      ),
    ],
  ),
  TravelArtifact(
    uid: '04:00:00:00:00:08',
    title: 'Philippines Travel Token',
    place: 'Philippines',
    country: 'Philippines',
    dateLabel: 'Demo collection',
    coordinates: '14.5995 N, 120.9842 E',
    medium: 'NFC tag',
    collection: 'Philippine journeys',
    accessionNumber: 'EA-DEMO-PHL-001',
    coverLine: 'A small token that opens the route through the Philippines.',
    modelAsset: _modelPath,
    colors: <Color>[
      EverAfterColors.olive,
      EverAfterColors.brass,
      EverAfterColors.burgundy,
    ],
    chapters: <ExhibitChapter>[
      ExhibitChapter(
        kicker: 'Cover',
        title: 'The journey begins with a single tap.',
        body:
            'This NFC token opens the Philippines travel collection, returning to its islands, city streets, coastlines, and clear water.',
        detail: 'Demo NFC UID 04:00:00:00:00:08',
      ),
      ExhibitChapter(
        kicker: 'Journey',
        title: 'An archipelago held inside one route.',
        body:
            'The collection moves through boat crossings, limestone horizons, shared meals, tropical roads, and evenings beside the sea.',
        detail: 'Collection note: Philippines travel archive.',
      ),
      ExhibitChapter(
        kicker: 'End',
        title: 'The tag returns the journey to the room.',
        body:
            'A physical object becomes the doorway back into the photographs, films, and places gathered along the way.',
        detail: 'Local exhibit. No cloud sync required.',
      ),
    ],
  ),
  TravelArtifact(
    uid: '04:00:00:00:00:09',
    title: 'Vietnam Travel Token',
    place: 'Vietnam',
    country: 'Vietnam',
    dateLabel: 'Demo collection',
    coordinates: '15.8801 N, 108.3380 E',
    medium: 'NFC tag',
    collection: 'Vietnam journeys',
    accessionNumber: 'EA-DEMO-VNM-001',
    coverLine: 'A small token that opens the route through Vietnam.',
    modelAsset: _modelPath,
    colors: <Color>[
      EverAfterColors.burgundy,
      EverAfterColors.brass,
      EverAfterColors.olive,
    ],
    chapters: <ExhibitChapter>[
      ExhibitChapter(
        kicker: 'Cover',
        title: 'The journey begins with a single tap.',
        body:
            'This NFC token opens the Vietnam travel collection, returning to its cities, coastlines, rivers, and mountain roads.',
        detail: 'Demo NFC UID 04:00:00:00:00:09',
      ),
      ExhibitChapter(
        kicker: 'Journey',
        title: 'A country held inside one route.',
        body:
            'The collection moves through busy streets, quiet water, shared meals, green horizons, and evenings lit by lanterns.',
        detail: 'Collection note: Vietnam travel archive.',
      ),
      ExhibitChapter(
        kicker: 'End',
        title: 'The tag returns the journey to the room.',
        body:
            'A physical object becomes the doorway back into the photographs, films, and places gathered along the way.',
        detail: 'Local exhibit. No cloud sync required.',
      ),
    ],
  ),
  TravelArtifact(
    uid: '04:00:00:00:00:0A',
    title: 'Sri Lanka Travel Token',
    place: 'Sri Lanka',
    country: 'Sri Lanka',
    dateLabel: 'Demo collection',
    coordinates: '7.9570 N, 80.7603 E',
    medium: 'NFC tag',
    collection: 'Sri Lankan journeys',
    accessionNumber: 'EA-DEMO-LKA-001',
    coverLine: 'A small token that opens the route through Sri Lanka.',
    modelAsset: _modelPath,
    colors: <Color>[
      EverAfterColors.brass,
      EverAfterColors.olive,
      EverAfterColors.burgundy,
    ],
    chapters: <ExhibitChapter>[
      ExhibitChapter(
        kicker: 'Cover',
        title: 'The journey begins with a single tap.',
        body:
            'This NFC token opens the Sri Lanka travel collection, returning to its coastlines, hill country, cities, and ancient paths.',
        detail: 'Demo NFC UID 04:00:00:00:00:0A',
      ),
      ExhibitChapter(
        kicker: 'Journey',
        title: 'An island held inside one route.',
        body:
            'The collection moves through tea-green hills, railway windows, warm beaches, shared meals, and roads beside the sea.',
        detail: 'Collection note: Sri Lanka travel archive.',
      ),
      ExhibitChapter(
        kicker: 'End',
        title: 'The tag returns the journey to the room.',
        body:
            'A physical object becomes the doorway back into the photographs, films, and places gathered along the way.',
        detail: 'Local exhibit. No cloud sync required.',
      ),
    ],
  ),
  TravelArtifact(
    uid: '04:00:00:00:00:0B',
    title: 'Station Ticket Stub',
    place: 'Kyoto',
    country: 'Japan',
    dateLabel: 'Demo collection',
    coordinates: '35.0116 N, 135.7681 E',
    medium: 'Thermal paper, ink, NFC tag',
    collection: 'Quiet rail journeys',
    accessionNumber: 'EA-DEMO-KYO-014',
    coverLine: 'A paper rectangle from a morning of temples and rain.',
    modelAsset: _modelPath,
    colors: <Color>[
      EverAfterColors.olive,
      EverAfterColors.burgundy,
      EverAfterColors.warmBrown,
    ],
    chapters: <ExhibitChapter>[
      ExhibitChapter(
        kicker: 'Cover',
        title: 'The platform clock held the first memory.',
        body:
            'A stub saved between pages, creased at one corner, still carrying the exactness of a departure board.',
        detail: 'Archive status: digitized label only.',
      ),
      ExhibitChapter(
        kicker: 'Journey',
        title: 'Stone paths, cedar shade, and soft station bells.',
        body:
            'The exhibit keeps the sequence sparse: a gate, a train, a bowl of noodles, and a long walk back under umbrellas.',
        detail: 'Suggested media: audio field notes.',
      ),
      ExhibitChapter(
        kicker: 'End',
        title: 'Filed under motion.',
        body:
            'The ticket is fragile, so the memory becomes the object you can handle.',
        detail: 'Local exhibit. Ready for future NFC binding.',
      ),
    ],
  ),
  TravelArtifact(
    uid: '04:00:00:00:00:0C',
    title: 'Black Sand Vial',
    place: 'Vik',
    country: 'Iceland',
    dateLabel: 'Demo collection',
    coordinates: '63.4186 N, 19.0060 W',
    medium: 'Glass, basalt sand, cork',
    collection: 'Northern weather',
    accessionNumber: 'EA-DEMO-VIK-003',
    coverLine: 'A storm kept in a bottle without making a sound.',
    modelAsset: _modelPath,
    colors: <Color>[
      EverAfterColors.ink,
      EverAfterColors.olive,
      EverAfterColors.brass,
    ],
    chapters: <ExhibitChapter>[
      ExhibitChapter(
        kicker: 'Cover',
        title: 'The shore was nearly monochrome.',
        body:
            'Wind pressed every sentence flat. The sand looked like ground ink and made the horizon feel older than the trip.',
        detail: 'Archive status: pending object scan.',
      ),
      ExhibitChapter(
        kicker: 'Journey',
        title: 'Weather as the main exhibit.',
        body:
            'The route is remembered by what had to be leaned into: rain, wool, hot soup, and a road disappearing into white.',
        detail: 'Suggested media: map and low ambient audio.',
      ),
      ExhibitChapter(
        kicker: 'End',
        title: 'A landscape small enough to shelve.',
        body:
            'The vial keeps the scale impossible, which is why it belongs in the museum.',
        detail: 'Local exhibit. Ready for future NFC binding.',
      ),
    ],
  ),
];
