import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:everafter/app.dart';
import 'package:everafter/data/gallery_memory_content.dart';
import 'package:everafter/data/japan_instagram_posts.dart';
import 'package:everafter/data/public_demo_assets.dart';
import 'package:everafter/data/trip_catalog_store.dart';
import 'package:everafter/data/trip_repository.dart';
import 'package:everafter/screens/taste_of_japan_screen.dart';
import 'package:everafter/screens/trip_experience_screen.dart';
import 'package:everafter/services/nfc_service_provider.dart';
import 'package:everafter/state/museum_controller.dart';
import 'package:everafter/widgets/ambient_soundtrack.dart';
import 'package:everafter/widgets/trip_gallery.dart';
import 'package:everafter/widgets/trip_journey.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _demoUid = '04:00:00:00:00:01';
const _chinaUid = '04:00:00:00:00:02';
const _southKoreaUid = '04:00:00:00:00:03';
const _japanUid = '04:00:00:00:00:04';
const _taiwanUid = '04:00:00:00:00:05';
const _baliUid = '04:00:00:00:00:06';
const _thailandUid = '04:00:00:00:00:07';
const _philippinesUid = '04:00:00:00:00:08';
const _vietnamUid = '04:00:00:00:00:09';
const _sriLankaUid = '04:00:00:00:00:0A';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await TripCatalogStore.instance.load();
  });

  test(
    'public demo keeps seven anonymous reel placeholders in order',
    () async {
      expect(japanInstagramPosts, hasLength(7));
      expect(
        japanInstagramPosts.map((post) => post.shortcode),
        orderedEquals(<String>[
          'demo-01',
          'demo-02',
          'demo-03',
          'demo-04',
          'demo-05',
          'demo-06',
          'demo-07',
        ]),
      );
      expect(
        japanInstagramPosts.map((post) => post.coverAssetPath),
        everyElement(isIn(publicDemoMemoryAssets)),
      );
      expect(
        japanInstagramPosts.map((post) => post.videoAssetPath),
        everyElement('assets/video/public-demo-memory.mp4'),
      );
      for (final post in japanInstagramPosts) {
        final bytes = await rootBundle.load(post.videoAssetPath);
        expect(bytes.lengthInBytes, greaterThan(100000));
      }
      expect(
        japanInstagramPosts.map((post) => post.permalink),
        everyElement(isEmpty),
      );
    },
  );

  test('gallery frames keep videos paused until focused', () {
    expect(
      TripCatalogStore.instance.allTrips,
      everyElement(
        predicate<TripGalleryItem>((trip) => !galleryAutoplaysVideosFor(trip)),
      ),
    );
  });

  test('playing memory videos are not covered by the still-image tint', () {
    expect(memoryVideoSurfaceFit, BoxFit.fill);
    expect(
      memoryMediaUsesColorTreatment(isVideo: false, isPlaying: false),
      isTrue,
    );
    expect(
      memoryMediaUsesColorTreatment(isVideo: true, isPlaying: false),
      isTrue,
    );
    expect(
      memoryMediaUsesColorTreatment(isVideo: true, isPlaying: true),
      isFalse,
    );
  });

  test(
    'focused baroque frames use high-resolution transparent assets',
    () async {
      const frameAssets = <String>[
        'assets/images/experience/baroque-frame-oval-hd.png',
        'assets/images/experience/baroque-frame-circular-hd.png',
        'assets/images/experience/baroque-frame-horizontal-oval-hd.png',
        'assets/images/experience/baroque-frame-portrait-hd.png',
        'assets/images/experience/baroque-frame-landscape-hd.png',
      ];

      for (final asset in frameAssets) {
        final bytes = await rootBundle.load(asset);
        final codec = await ui.instantiateImageCodec(
          bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        );
        final frame = await codec.getNextFrame();
        expect(frame.image.width, greaterThanOrEqualTo(1200), reason: asset);
        expect(frame.image.height, greaterThanOrEqualTo(1200), reason: asset);
        frame.image.dispose();
        codec.dispose();
      }
    },
  );

  test('public demo keepsakes are bundled redistributable assets', () async {
    expect(galleryTrinketAssetChoices, hasLength(5));
    for (final assetPath in galleryTrinketAssetChoices) {
      final bytes = await rootBundle.load(assetPath);
      final codec = await ui.instantiateImageCodec(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      );
      final frame = await codec.getNextFrame();
      expect(frame.image.width, greaterThan(100));
      expect(frame.image.height, greaterThan(100));
      frame.image.dispose();
      codec.dispose();
    }
  });

  test('Japan food menu uses only the public demo artwork', () {
    final assetPaths = tasteOfJapanMemories
        .map((memory) => memory.assetPath)
        .toList();
    final accessionNumbers = tasteOfJapanMemories
        .map((memory) => memory.accessionNumber)
        .toList();

    expect(tasteOfJapanMemories, hasLength(16));
    expect(assetPaths, everyElement(publicMemoryPlaceholderAsset));
    expect(accessionNumbers.toSet(), hasLength(accessionNumbers.length));
  });

  test('demo Hong Kong NFC UID is bound to the Hong Kong artifact', () {
    final artifact = const TripRepository().findByUid(_demoUid);

    expect(artifact, isNotNull);
    expect(artifact!.place, 'Hong Kong');
  });

  test('demo China NFC UID is bound to the China trip', () {
    final artifact = const TripRepository().findByUid(_chinaUid);

    expect(artifact, isNotNull);
    expect(artifact!.place, 'China');
  });

  test('demo South Korea NFC UID is bound to the South Korea trip', () {
    final artifact = const TripRepository().findByUid(_southKoreaUid);

    expect(artifact, isNotNull);
    expect(artifact!.place, 'South Korea');
  });

  test('demo Japan NFC UID is bound to the Japan trip', () {
    final artifact = const TripRepository().findByUid(_japanUid);

    expect(artifact, isNotNull);
    expect(artifact!.place, 'Japan');
  });

  test('demo Taiwan NFC UID is bound to the Taiwan trip', () {
    final artifact = const TripRepository().findByUid(_taiwanUid);

    expect(artifact, isNotNull);
    expect(artifact!.place, 'Taiwan');
  });

  test('demo Bali NFC UID is bound to the Bali trip', () {
    final artifact = const TripRepository().findByUid(_baliUid);

    expect(artifact, isNotNull);
    expect(artifact!.place, 'Bali');
  });

  test('demo Thailand NFC UID is bound to the Thailand trip', () {
    final artifact = const TripRepository().findByUid(_thailandUid);

    expect(artifact, isNotNull);
    expect(artifact!.place, 'Thailand');
  });

  test('demo Philippines NFC UID is bound to the Philippines trip', () {
    final artifact = const TripRepository().findByUid(_philippinesUid);

    expect(artifact, isNotNull);
    expect(artifact!.place, 'Philippines');
  });

  test('demo Vietnam NFC UID is bound to the Vietnam trip', () {
    final artifact = const TripRepository().findByUid(_vietnamUid);

    expect(artifact, isNotNull);
    expect(artifact!.place, 'Vietnam');
  });

  test('demo Sri Lanka NFC UID is bound to the Sri Lanka trip', () {
    final artifact = const TripRepository().findByUid(_sriLankaUid);

    expect(artifact, isNotNull);
    expect(artifact!.place, 'Sri Lanka');
  });

  test('raster globe rotates before settling on the destination', () {
    final japan = TripCatalogStore.instance.allTrips.first;

    expect(rotatingGlobeFrameFor(japan, 0), isNot(28));
    expect(rotatingGlobeFrameFor(japan, 0.2), isNot(28));
    expect(rotatingGlobeFrameFor(japan, 0.34), 28);
    expect(rotatingGlobeFrameFor(japan, 0.7), 28);

    final framePosition = rotatingGlobeFramePositionFor(japan, 0.2);
    final nextFramePosition = rotatingGlobeFramePositionFor(japan, 0.201);
    expect(framePosition, isNot(framePosition.roundToDouble()));
    expect(nextFramePosition, greaterThan(framePosition));
    expect(nextFramePosition - framePosition, lessThan(0.25));
    expect(rotatingGlobeFramePositionFor(japan, 0.34), closeTo(28, 0.0001));

    final destinationPoint = destinationGlobePointFor(japan, 28);
    expect(destinationPoint.dx, inInclusiveRange(500, 524));
    expect(destinationPoint.dy, inInclusiveRange(235, 275));
    expect(
      destinationGlobeAssetFor(japan),
      'assets/images/experience/'
      'earth-globe-japan-centered-rotation-sheet.jpg',
    );

    final japanBoundary = projectedJapanBoundaryPathForFrame(
      28,
      const Size.square(1024),
    );
    final boundaryBounds = japanBoundary.getBounds();
    expect(japanBoundary.contains(destinationPoint), isTrue);
    expect(boundaryBounds.width, greaterThan(80));
    expect(boundaryBounds.height, greaterThan(160));
    expect(boundaryBounds.center.dx, inInclusiveRange(450, 490));
    expect(boundaryBounds.center.dy, inInclusiveRange(190, 315));

    for (final trip in TripCatalogStore.instance.allTrips) {
      final settledFrame = rotatingGlobeFrameFor(trip, 0.7);
      final point = destinationGlobePointFor(trip, settledFrame);
      expect(settledFrame, 28, reason: trip.slug);
      expect(point.dx, closeTo(512, 0.01), reason: trip.slug);
      expect(point.dy, closeTo(256, 0.01), reason: trip.slug);
      expect(point.dy, lessThan(512), reason: '${trip.slug} upper hemisphere');
      expect(
        destinationGlobeAssetFor(trip),
        'assets/images/experience/'
        'earth-globe-${trip.slug}-centered-rotation-sheet.jpg',
      );

      final destinationBoundary = projectedDestinationBoundaryPathForFrame(
        trip,
        settledFrame,
        const Size.square(1024),
      );
      // Destinations without hand-authored boundary polygon data (mostly
      // the newer non-Asia trips) intentionally render as a pin with no
      // outline instead of crashing; only assert boundary shape for slugs
      // known to have ring data.
      if (destinationBoundaryRingsFor(trip).isNotEmpty) {
        expect(
          destinationBoundary.getBounds().isEmpty,
          isFalse,
          reason: '${trip.slug} geographic boundary',
        );
        // Bangkok and Phuket reuse Thailand's simplified mainland outline,
        // which doesn't trace Phuket's own offshore island, so only assert
        // strict point-containment for destinations with their own ring
        // data.
        if (trip.slug != 'bangkok' && trip.slug != 'phuket') {
          expect(
            destinationBoundary.contains(point),
            isTrue,
            reason: '${trip.slug} coordinate inside destination boundary',
          );
        }
      } else {
        expect(
          destinationBoundary.getBounds().isEmpty,
          isTrue,
          reason: '${trip.slug} has no boundary data, so no outline',
        );
      }
    }

    final china = TripCatalogStore.instance.allTrips.firstWhere(
      (trip) => trip.slug == 'china',
    );
    expect(china.latitude, closeTo(39.9042, 0.0001));
    expect(china.longitude, closeTo(116.4074, 0.0001));
    final chinaBoundary = projectedChinaBoundaryPathForFrame(
      28,
      const Size.square(1024),
    );
    final chinaBoundaryBounds = chinaBoundary.getBounds();
    expect(chinaBoundary.contains(destinationGlobePointFor(china, 28)), isTrue);
    expect(chinaBoundaryBounds.width, greaterThan(190));
    expect(chinaBoundaryBounds.height, greaterThan(120));
    expect(chinaBoundaryBounds.right, lessThan(650));
  });

  test('Vietnam and Sri Lanka include complete trip visuals', () async {
    for (final slug in <String>['vietnam', 'sri-lanka']) {
      final trip = TripCatalogStore.instance.allTrips.firstWhere(
        (trip) => trip.slug == slug,
      );
      expect(trip.dateRangeLabel, 'DATES TO BE ADDED');
      expect(trip.durationLabel, isNull);

      for (final assetPath in <String>[
        trip.assetPath,
        trip.portraitAssetPath,
        destinationGlobeAssetFor(trip),
      ]) {
        final bytes = await rootBundle.load(assetPath);
        expect(bytes.lengthInBytes, greaterThan(1000), reason: assetPath);
      }
    }
  });

  test('Japan location slideshows use public demo artwork', () async {
    expect(
      TripCatalogStore.instance.memoryLocationsFor('japan'),
      hasLength(16),
    );
    expect(
      TripCatalogStore.instance
          .memoryLocationsFor('japan')
          .map((location) => location.label),
      containsAll(<String>[
        'Tokyo',
        'Kyoto',
        'Osaka',
        'Nara',
        'Hiroshima',
        'Ueno Park',
        'Akihabara',
        'Nezu Shrine',
        'Asakusa & Sumida River',
        'Kiyomizu-dera',
        'Arashiyama',
        'Midosuji',
        'Osaka Castle',
        'Takayama',
        'Shirakawa-go',
        'Tokyo Disney Resort',
      ]),
    );

    final expectedHighlightCounts = <String, (int, int, int)>{
      'Tokyo': (66, 39, 27),
      'Kyoto': (38, 31, 7),
      'Osaka': (9, 5, 4),
      'Nara': (10, 8, 2),
      'Hiroshima': (11, 5, 6),
    };
    for (final entry in expectedHighlightCounts.entries) {
      final location = TripCatalogStore.instance
          .memoryLocationsFor('japan')
          .firstWhere((location) => location.label == entry.key);
      expect(location.assetPaths, hasLength(entry.value.$1));
      expect(location.photoCount, entry.value.$1);
      expect(location.videoCount, 0);
    }

    final assetPaths = TripCatalogStore.instance
        .memoryLocationsFor('japan')
        .expand((location) => location.assetPaths)
        .toList();
    expect(assetPaths, hasLength(197));
    expect(assetPaths, everyElement(isIn(publicDemoMemoryAssets)));

    for (final assetPath in assetPaths) {
      final bytes = await rootBundle.load(assetPath);
      expect(bytes.lengthInBytes, greaterThan(1000), reason: assetPath);
    }

    final videoPosters = TripCatalogStore.instance
        .memoryLocationsFor('japan')
        .expand((location) => location.videoPosterPaths.values)
        .toList();
    expect(videoPosters, isEmpty);
  });

  test('China baroque slideshows include every highlight item', () async {
    expect(TripCatalogStore.instance.memoryLocationsFor('china'), hasLength(4));
    expect(
      TripCatalogStore.instance
          .memoryLocationsFor('china')
          .map((location) => location.label),
      orderedEquals(<String>[
        'Great Wall of China',
        'Beijing',
        'Shanghai',
        'Chongqing',
      ]),
    );

    final expectedCounts = <String, (int, int, int)>{
      'Great Wall of China': (8, 3, 5),
      'Beijing': (7, 6, 1),
      'Shanghai': (15, 14, 1),
      'Chongqing': (30, 23, 7),
    };
    for (final location in TripCatalogStore.instance.memoryLocationsFor(
      'china',
    )) {
      final counts = expectedCounts[location.label]!;
      expect(location.assetPaths, hasLength(counts.$1));
      expect(location.photoCount, counts.$1);
      expect(location.videoCount, 0);
    }

    final assetPaths = TripCatalogStore.instance
        .memoryLocationsFor('china')
        .expand((location) => location.assetPaths)
        .toList();
    expect(assetPaths, hasLength(60));
    expect(assetPaths, everyElement(isIn(publicDemoMemoryAssets)));

    for (final assetPath in assetPaths) {
      final bytes = await rootBundle.load(assetPath);
      expect(bytes.lengthInBytes, greaterThan(1000), reason: assetPath);
    }

    final videoPosters = TripCatalogStore.instance
        .memoryLocationsFor('china')
        .expand((location) => location.videoPosterPaths.values)
        .toList();
    expect(videoPosters, isEmpty);
  });

  test('Sri Lanka baroque slideshows include every highlight item', () async {
    expect(
      TripCatalogStore.instance.memoryLocationsFor('sri-lanka'),
      hasLength(4),
    );
    expect(
      TripCatalogStore.instance
          .memoryLocationsFor('sri-lanka')
          .map((location) => location.label),
      orderedEquals(<String>[
        'Galle Fort',
        'Unawatuna Coast',
        'Mirissa & Weligama',
        'Ahangama & Koggala',
      ]),
    );

    final expectedCounts = <String, (int, int, int)>{
      'Galle Fort': (7, 5, 2),
      'Unawatuna Coast': (9, 7, 2),
      'Mirissa & Weligama': (8, 4, 4),
      'Ahangama & Koggala': (5, 4, 1),
    };
    for (final location in TripCatalogStore.instance.memoryLocationsFor(
      'sri-lanka',
    )) {
      final counts = expectedCounts[location.label]!;
      expect(location.assetPaths, hasLength(counts.$1));
      expect(location.photoCount, counts.$1);
      expect(location.videoCount, 0);
    }

    final assetPaths = TripCatalogStore.instance
        .memoryLocationsFor('sri-lanka')
        .expand((location) => location.assetPaths)
        .toList();
    expect(assetPaths, hasLength(29));
    expect(assetPaths, everyElement(isIn(publicDemoMemoryAssets)));

    for (final assetPath in assetPaths) {
      final bytes = await rootBundle.load(assetPath);
      expect(bytes.lengthInBytes, greaterThan(1000), reason: assetPath);
    }

    final videoPosters = TripCatalogStore.instance
        .memoryLocationsFor('sri-lanka')
        .expand((location) => location.videoPosterPaths.values)
        .toList();
    expect(videoPosters, isEmpty);
  });

  test('Hong Kong baroque slideshows include every highlight item', () async {
    expect(
      TripCatalogStore.instance.memoryLocationsFor('hong-kong'),
      hasLength(7),
    );
    expect(
      TripCatalogStore.instance
          .memoryLocationsFor('hong-kong')
          .map((location) => location.label),
      orderedEquals(<String>[
        'Arrival & Lantau',
        'Central & Wan Chai',
        'Victoria Peak & High West',
        'Victoria Harbour',
        "Dragon's Back & Big Wave Bay",
        'City Stay & Dining',
        'Hong Kong Disneyland',
      ]),
    );

    final expectedCounts = <String, (int, int, int)>{
      'Arrival & Lantau': (4, 1, 3),
      'Central & Wan Chai': (8, 3, 5),
      'Victoria Peak & High West': (8, 3, 5),
      'Victoria Harbour': (5, 2, 3),
      "Dragon's Back & Big Wave Bay": (9, 3, 6),
      'City Stay & Dining': (4, 0, 4),
      'Hong Kong Disneyland': (3, 2, 1),
    };
    for (final location in TripCatalogStore.instance.memoryLocationsFor(
      'hong-kong',
    )) {
      final counts = expectedCounts[location.label]!;
      expect(location.assetPaths, hasLength(counts.$1));
      expect(location.photoCount, counts.$1);
      expect(location.videoCount, 0);
    }

    final assetPaths = TripCatalogStore.instance
        .memoryLocationsFor('hong-kong')
        .expand((location) => location.assetPaths)
        .toList();
    expect(assetPaths, hasLength(41));
    expect(assetPaths, everyElement(isIn(publicDemoMemoryAssets)));

    for (final assetPath in assetPaths) {
      final bytes = await rootBundle.load(assetPath);
      expect(bytes.lengthInBytes, greaterThan(1000), reason: assetPath);
    }

    final videoPosters = TripCatalogStore.instance
        .memoryLocationsFor('hong-kong')
        .expand((location) => location.videoPosterPaths.values)
        .toList();
    expect(videoPosters, isEmpty);
  });

  test('Taiwan baroque slideshows include every highlight photo', () async {
    expect(
      TripCatalogStore.instance.memoryLocationsFor('taiwan'),
      hasLength(6),
    );
    expect(
      TripCatalogStore.instance
          .memoryLocationsFor('taiwan')
          .map((location) => location.label),
      orderedEquals(<String>[
        'Taipei Arrival & City',
        'Jiufen',
        'Cingjing Farm',
        'Sun Moon Lake',
        'Grand Hotel Taipei',
        'Kaohsiung & Qijin',
      ]),
    );

    final expectedCounts = <String, int>{
      'Taipei Arrival & City': 11,
      'Jiufen': 5,
      'Cingjing Farm': 4,
      'Sun Moon Lake': 2,
      'Grand Hotel Taipei': 3,
      'Kaohsiung & Qijin': 6,
    };
    for (final location in TripCatalogStore.instance.memoryLocationsFor(
      'taiwan',
    )) {
      expect(location.assetPaths, hasLength(expectedCounts[location.label]!));
      expect(location.photoCount, expectedCounts[location.label]);
      expect(location.videoCount, 0);
    }

    final assetPaths = TripCatalogStore.instance
        .memoryLocationsFor('taiwan')
        .expand((location) => location.assetPaths)
        .toList();
    expect(assetPaths, hasLength(31));
    expect(assetPaths, everyElement(isIn(publicDemoMemoryAssets)));

    for (final assetPath in assetPaths) {
      final bytes = await rootBundle.load(assetPath);
      expect(bytes.lengthInBytes, greaterThan(1000), reason: assetPath);
    }
  });

  test('South Korea baroque slideshows include every highlight item', () async {
    expect(
      TripCatalogStore.instance.memoryLocationsFor('south-korea'),
      hasLength(5),
    );
    expect(
      TripCatalogStore.instance
          .memoryLocationsFor('south-korea')
          .map((location) => location.label),
      orderedEquals(<String>['Seoul', 'Incheon', 'Jeju', 'Gyeongju', 'Busan']),
    );

    final expectedCounts = <String, (int, int, int)>{
      'Seoul': (32, 28, 4),
      'Incheon': (20, 13, 7),
      'Jeju': (21, 17, 4),
      'Gyeongju': (21, 16, 5),
      'Busan': (18, 6, 12),
    };
    for (final location in TripCatalogStore.instance.memoryLocationsFor(
      'south-korea',
    )) {
      final counts = expectedCounts[location.label]!;
      expect(location.assetPaths, hasLength(counts.$1));
      expect(location.photoCount, counts.$1);
      expect(location.videoCount, 0);
    }

    final assetPaths = TripCatalogStore.instance
        .memoryLocationsFor('south-korea')
        .expand((location) => location.assetPaths)
        .toList();
    expect(assetPaths, hasLength(112));
    expect(assetPaths, everyElement(isIn(publicDemoMemoryAssets)));

    for (final assetPath in assetPaths) {
      final bytes = await rootBundle.load(assetPath);
      expect(bytes.lengthInBytes, greaterThan(1000), reason: assetPath);
    }

    final videoPosters = TripCatalogStore.instance
        .memoryLocationsFor('south-korea')
        .expand((location) => location.videoPosterPaths.values)
        .toList();
    expect(videoPosters, isEmpty);
  });

  test('country trips select their dedicated soundtracks', () async {
    expect(
      AmbientSoundtrack.soundtrackAssetForPath('/trip/china'),
      AmbientSoundtrack.chinaSoundtrackAsset,
    );
    expect(
      AmbientSoundtrack.soundtrackAssetForPath('/trip/japan'),
      AmbientSoundtrack.japanSoundtrackAsset,
    );
    expect(
      AmbientSoundtrack.soundtrackAssetForPath('/trip/south-korea'),
      AmbientSoundtrack.southKoreaSoundtrackAsset,
    );
    expect(
      AmbientSoundtrack.soundtrackAssetForPath('/'),
      AmbientSoundtrack.ambientSoundtrackAsset,
    );

    final southKoreaTrack = await rootBundle.load(
      'assets/${AmbientSoundtrack.southKoreaSoundtrackAsset}',
    );
    expect(southKoreaTrack.lengthInBytes, greaterThan(1000));
  });

  test('trip interaction sound effects are bundled', () async {
    for (final effect in EverAfterSoundEffect.values) {
      final bytes = await rootBundle.load('assets/${effect.assetPath}');
      expect(bytes.lengthInBytes, greaterThan(1000));
    }
  });

  test('paper burn sound fades in and out across the transition', () {
    const effect = EverAfterSoundEffect.paperBurn;

    expect(effect.envelopeGainAt(Duration.zero), 0);
    expect(
      effect.envelopeGainAt(const Duration(milliseconds: 260)),
      closeTo(0.5, 0.01),
    );
    expect(effect.envelopeGainAt(const Duration(milliseconds: 520)), 1);
    expect(effect.envelopeGainAt(const Duration(milliseconds: 2080)), 1);
    expect(
      effect.envelopeGainAt(const Duration(milliseconds: 2530)),
      closeTo(0.5, 0.01),
    );
    expect(effect.envelopeGainAt(const Duration(milliseconds: 2980)), 0);
  });

  testWidgets('trip card tap requests its zoom sound effect', (tester) async {
    final requestedEffects = <EverAfterSoundEffect>[];
    var opened = false;

    await tester.pumpWidget(
      MaterialApp(
        home: EverAfterSoundEffects(
          onPlay: requestedEffects.add,
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 280,
                height: 300,
                child: TripCard(
                  trip: TripCatalogStore.instance.allTrips.first,
                  heroTag: 'sound-effect-card',
                  onTap: () => opened = true,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TripCard));
    await tester.pump();

    expect(requestedEffects, <EverAfterSoundEffect>[
      EverAfterSoundEffect.tripCardZoom,
    ]);
    expect(opened, isTrue);
  });

  testWidgets('trip card return requests its zoom sound effect', (
    tester,
  ) async {
    final requestedEffects = <EverAfterSoundEffect>[];
    final router = GoRouter(
      routes: <RouteBase>[
        GoRoute(path: '/', builder: (context, state) => const SizedBox()),
        GoRoute(
          path: '/trip',
          builder: (context, state) => TripExperienceScreen(
            trip: TripCatalogStore.instance.allTrips.first,
            heroTag: 'sound-effect-return',
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      EverAfterSoundEffects(
        onPlay: requestedEffects.add,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    router.push('/trip');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.byTooltip('Back to travel gallery'));
    await tester.pump();

    expect(requestedEffects, <EverAfterSoundEffect>[
      EverAfterSoundEffect.tripCardZoom,
    ]);
  });

  testWidgets('Start requests the globe entrance sound effect', (tester) async {
    final requestedEffects = <EverAfterSoundEffect>[];

    await tester.pumpWidget(
      MaterialApp(
        home: EverAfterSoundEffects(
          onPlay: requestedEffects.add,
          child: TripExperienceScreen(
            trip: TripCatalogStore.instance.allTrips.first,
            heroTag: 'sound-effect-globe',
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('start-trip-experience')));
    await tester.pump();

    expect(requestedEffects, <EverAfterSoundEffect>[
      EverAfterSoundEffect.globeEntrance,
    ]);

    await tester.pump(const Duration(milliseconds: 9000));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('selecting a gallery frame requests its spotlight sound', (
    tester,
  ) async {
    final requestedEffects = <EverAfterSoundEffect>[];
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: EverAfterSoundEffects(
          onPlay: requestedEffects.add,
          child: SizedBox(
            width: 1280,
            height: 800,
            child: TripJourney(
              trip: TripCatalogStore.instance.allTrips.first,
              animation: const AlwaysStoppedAnimation<double>(1),
              onTasteTap: () async {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final firstFrameSize = tester.getSize(
      find.byKey(const ValueKey('gallery-memory-frame')).first,
    );
    expect(firstFrameSize.width, closeTo(190 * 2.3 * 0.90 * 1.10, 0.01));
    expect(firstFrameSize.height, closeTo(272 * 2.3 * 0.90 * 1.10, 0.01));
    expect(
      find.byKey(const ValueKey('gallery-baroque-frame-shadow')),
      findsWidgets,
    );

    final visibleFrames = find
        .byKey(const ValueKey('gallery-memory-frame'))
        .hitTestable();
    expect(visibleFrames, findsWidgets);
    await tester.tap(visibleFrames.first);
    await tester.pump();

    expect(requestedEffects, isEmpty);
    await tester.pump(const Duration(milliseconds: 625));
    expect(requestedEffects, isEmpty);
    expect(
      tester
          .widget<Opacity>(
            find.byKey(const ValueKey('focused-memory-spotlight')),
          )
          .opacity,
      lessThan(0.05),
    );

    await tester.pump(const Duration(milliseconds: 150));
    expect(requestedEffects, <EverAfterSoundEffect>[
      EverAfterSoundEffect.frameSelect,
    ]);
    expect(
      tester
          .widget<Opacity>(
            find.byKey(const ValueKey('focused-memory-spotlight')),
          )
          .opacity,
      greaterThan(0),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('trip image and frame share one Hero flight', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 280,
            height: 300,
            child: TripCard(
              trip: TripCatalogStore.instance.allTrips.first,
              heroTag: 'unified-trip-card',
              onTap: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.byType(Hero), findsOneWidget);
    final hero = tester.widget<Hero>(find.byType(Hero));
    expect(hero.tag, 'unified-trip-card');
    expect(
      find.byKey(const ValueKey('trip-card-contact-shadow')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('trip-card-paper-texture')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('trip-card-frame-shadow')),
      findsOneWidget,
    );
  });

  test('trip card transition eases at both ends', () {
    const begin = Rect.fromLTWH(120, 90, 180, 240);
    const destination = Rect.fromLTWH(0, 0, 1280, 800);
    final flight = cinematicTripRectTween(begin, destination);

    double centerProgressAt(double time) {
      final rect = flight.lerp(time)!;
      return (rect.center.dx - begin.center.dx) /
          (destination.center.dx - begin.center.dx);
    }

    double scaleProgressAt(double time) {
      final rect = flight.lerp(time)!;
      return (rect.width - begin.width) / (destination.width - begin.width);
    }

    expect(centerProgressAt(0.18), lessThan(0.18));
    expect(scaleProgressAt(0.18), lessThan(0.18));
    expect(centerProgressAt(0.82), greaterThan(0.82));
    expect(scaleProgressAt(0.82), greaterThan(0.82));
    expect(centerProgressAt(0.5), closeTo(0.5, 0.000001));
    expect(scaleProgressAt(0.5), closeTo(0.5, 0.000001));
  });

  testWidgets('app surface uses the 1280 by 800 display ratio', (tester) async {
    tester.view.physicalSize = EverAfterViewport.designSize;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(child: EverAfterApp(showSplash: false)),
    );

    expect(
      tester.getSize(find.byKey(const ValueKey('everafter-1280x800-surface'))),
      EverAfterViewport.designSize,
    );
  });

  testWidgets('idle museum starts directly with the travel gallery', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: EverAfterApp(showSplash: false)),
    );
    await tester.pump();

    expect(find.text('MUSEUM OF TRAVELS'), findsOneWidget);
    expect(find.text('Museum of\nMy Travels'), findsNothing);
    expect(find.text('ARTIFACTS'), findsNothing);
    expect(find.text('COUNTRIES'), findsNothing);
    expect(find.text('Present demo artifact'.toUpperCase()), findsNothing);
    expect(find.byKey(const ValueKey('warm-linen-background')), findsOneWidget);
    expect(find.byKey(const ValueKey('soundtrack-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('soundtrack-controls')), findsNothing);
  });

  testWidgets('idle museum confirms before closing the native app', (
    tester,
  ) async {
    var closeRequested = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'SystemNavigator.pop') {
            closeRequested = true;
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await tester.pumpWidget(
      const ProviderScope(child: EverAfterApp(showSplash: false)),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('close-everafter')));
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Close EverAfter?'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('confirm-close-everafter')),
      findsOneWidget,
    );
    expect(closeRequested, isFalse);

    await tester.tap(find.byKey(const ValueKey('keep-everafter-open')));
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Close EverAfter?'), findsNothing);
    expect(closeRequested, isFalse);

    await tester.tap(find.byKey(const ValueKey('close-everafter')));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.byKey(const ValueKey('confirm-close-everafter')));
    await tester.pump(const Duration(milliseconds: 150));

    expect(closeRequested, isTrue);
  });

  testWidgets('soundtrack button toggles its volume controls', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: EverAfterApp(showSplash: false)),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('soundtrack-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));

    expect(find.byKey(const ValueKey('soundtrack-controls')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('soundtrack-mute-toggle')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('soundtrack-volume')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('soundtrack-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 180));

    expect(find.byKey(const ValueKey('soundtrack-controls')), findsNothing);
  });

  testWidgets('country routes switch tracks and back restores ambient', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: EverAfterApp(showSplash: false)),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('active-soundtrack-ambient')),
      findsOneWidget,
    );

    final router = GoRouter.of(tester.element(find.text('MUSEUM OF TRAVELS')));
    unawaited(router.push('/trip/china'));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('active-soundtrack-china')),
      findsOneWidget,
    );

    router.pop();
    await tester.pump();

    expect(
      find.byKey(const ValueKey('active-soundtrack-ambient')),
      findsOneWidget,
    );

    unawaited(router.push('/trip/japan'));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('active-soundtrack-japan')),
      findsOneWidget,
    );

    router.pop();
    await tester.pump();

    expect(
      find.byKey(const ValueKey('active-soundtrack-ambient')),
      findsOneWidget,
    );

    unawaited(router.push('/trip/south-korea'));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('active-soundtrack-south-korea')),
      findsOneWidget,
    );

    router.pop();
    await tester.pump();

    expect(
      find.byKey(const ValueKey('active-soundtrack-ambient')),
      findsOneWidget,
    );
  });

  testWidgets('home gallery shows four columns by two rows and scrolls', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: EverAfterApp(showSplash: false)),
    );
    await tester.pump();

    final grid = tester.widget<GridView>(
      find.byKey(const ValueKey('trip-gallery')),
    );
    final delegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    final gallery = tester.widget<TripGallery>(find.byType(TripGallery));
    final viewportBounds = tester.getRect(
      find.byKey(const ValueKey('everafter-1280x800-surface')),
    );
    final galleryBounds = tester.getRect(find.byType(TripGallery));

    expect(delegate.crossAxisCount, TripGallery.rowCount);
    expect(TripGallery.visibleColumns, 4);
    expect(galleryBounds.left, closeTo(viewportBounds.left, 0.01));
    expect(galleryBounds.right, closeTo(viewportBounds.right, 0.01));
    expect(TripCatalogStore.instance.trips.length, 12);
    expect(find.text('12 TRIPS · DRAG TO EXPLORE'), findsOneWidget);
    expect(find.text('JAPAN'), findsOneWidget);
    expect(find.text('TASTE OF\nJAPAN'), findsNothing);

    expect(gallery.controller.offset, 0);
    expect(gallery.controller.position.maxScrollExtent, greaterThan(0));
    await tester.tap(find.byKey(const ValueKey('gallery-next')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(gallery.controller.offset, greaterThan(0));
    expect(find.text('MALAYSIA'), findsOneWidget);
  });

  testWidgets('home gallery scrolls when dragged with a mouse', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 1280,
          height: 700,
          child: TripGallery(
            controller: controller,
            autoScrollEnabled: false,
            onTripTap: (_, _) {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(controller.offset, 0);
    final drag = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('trip-gallery'))),
      kind: PointerDeviceKind.mouse,
    );
    await drag.moveBy(const Offset(-320, 0));
    await tester.pump();
    await drag.up();
    await tester.pumpAndSettle();

    expect(controller.offset, greaterThan(250));
  });

  testWidgets('home gallery drifts horizontally on its own', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: EverAfterApp(showSplash: false)),
    );
    await tester.pump();

    final gallery = tester.widget<TripGallery>(find.byType(TripGallery));
    final startOffset = gallery.controller.offset;

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 2));

    expect(gallery.controller.offset, greaterThan(startOffset));
  });

  testWidgets('home trip cards have stable hand-placed rotations', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: EverAfterApp(showSplash: false)),
    );
    await tester.pump();

    final rotationFinder = find.byWidgetPredicate((widget) {
      final key = widget.key;
      return widget is Transform &&
          key is ValueKey<String> &&
          key.value.startsWith('trip-card-hand-rotation-');
    });
    final offsetFinder = find.byWidgetPredicate((widget) {
      final key = widget.key;
      return widget is Transform &&
          key is ValueKey<String> &&
          key.value.startsWith('trip-card-hand-offset-');
    });
    final rotations = tester
        .widgetList<Transform>(rotationFinder)
        .take(24)
        .map(
          (transform) => math.atan2(
            transform.transform.entry(1, 0),
            transform.transform.entry(0, 0),
          ),
        )
        .toList();
    final offsets = tester
        .widgetList<Transform>(offsetFinder)
        .take(24)
        .map(
          (transform) => Offset(
            transform.transform.entry(0, 3),
            transform.transform.entry(1, 3),
          ),
        )
        .toList();

    expect(rotations, hasLength(8));
    expect(offsets, hasLength(8));
    expect(rotations.any((angle) => angle < 0), isTrue);
    expect(rotations.any((angle) => angle > 0), isTrue);
    expect(
      rotations.map((angle) => angle.toStringAsFixed(4)).toSet().length,
      greaterThan(4),
    );
    expect(rotations.every((angle) => angle.abs() <= 0.026), isTrue);
    expect(offsets.any((offset) => offset != Offset.zero), isTrue);

    await tester.pump(const Duration(milliseconds: 100));
    final rebuiltRotations = tester
        .widgetList<Transform>(rotationFinder)
        .map(
          (transform) => math.atan2(
            transform.transform.entry(1, 0),
            transform.transform.entry(0, 0),
          ),
        )
        .toList();
    expect(rebuiltRotations, orderedEquals(rotations));
  });

  testWidgets('Japan gallery menu opens and switches ledger memories', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: EverAfterApp(showSplash: false)),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('trip-0-japan')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2100));
    await tester.tap(find.byKey(const ValueKey('start-trip-experience')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 7600));

    expect(find.text('TASTE OF\nJAPAN'), findsWidgets);
    final menu = find.byKey(const ValueKey('taste-of-japan-menu-0'));
    expect(menu, findsOneWidget);
    final menuRect = tester.getRect(menu);
    final viewportRect = tester.getRect(
      find.byKey(const ValueKey('everafter-1280x800-surface')),
    );
    final menuTapTarget = find.descendant(
      of: menu,
      matching: find.byType(InkWell),
    );
    expect(menuTapTarget, findsOneWidget);
    tester.widget<InkWell>(menuTapTarget).onTap!();
    await tester.pump();

    expect(find.text('TASTES OF JAPAN'), findsNothing);
    await tester.pump(const Duration(milliseconds: 40));
    final liftedMenu = tester.widget<Transform>(
      find.descendant(
        of: find.byKey(const ValueKey('taste-of-japan-menu-0')),
        matching: find.byKey(const ValueKey('taste-menu-lift')),
      ),
    );
    expect(liftedMenu.transform.entry(1, 3), lessThan(0));
    expect(liftedMenu.transform.entry(1, 3), greaterThan(-4.1));

    await tester.pump(const Duration(milliseconds: 41));
    await tester.pump(const Duration(milliseconds: 325));
    final flippingCover = find.descendant(
      of: find.byKey(const ValueKey('taste-of-japan-menu-0')),
      matching: find.byKey(const ValueKey('taste-menu-cover-flip')),
    );
    final revealedInside = find.descendant(
      of: find.byKey(const ValueKey('taste-of-japan-menu-0')),
      matching: find.byKey(const ValueKey('taste-menu-inside-reveal')),
    );
    final coverTransform = tester.widget<Transform>(flippingCover);
    final insideOpacity = tester.widget<Opacity>(revealedInside);
    expect(coverTransform.transform.entry(0, 0), lessThan(0.5));
    expect(insideOpacity.opacity, greaterThan(0.5));
    expect(
      tester
          .widget<Opacity>(
            find.descendant(
              of: find.byKey(const ValueKey('taste-of-japan-menu-0')),
              matching: find.byKey(
                const ValueKey('taste-menu-cover-highlight'),
              ),
            ),
          )
          .opacity,
      greaterThan(0.15),
    );
    expect(
      tester
          .widget<Opacity>(
            find.descendant(
              of: find.byKey(const ValueKey('taste-of-japan-menu-0')),
              matching: find.byKey(const ValueKey('taste-menu-hinge-shadow')),
            ),
          )
          .opacity,
      greaterThan(0.3),
    );
    expect(find.text('TASTES OF JAPAN'), findsNothing);

    await tester.pump(const Duration(milliseconds: 326));
    await tester.pump(const Duration(milliseconds: 60));
    final settlingPage = tester.widget<Transform>(
      find.descendant(
        of: find.byKey(const ValueKey('taste-of-japan-menu-0')),
        matching: find.byKey(const ValueKey('taste-menu-page-settle')),
      ),
    );
    expect(settlingPage.transform.entry(0, 0), greaterThan(1));
    await tester.pump(const Duration(milliseconds: 61));
    await tester.pump();
    final zoomingPage = find.byKey(const ValueKey('taste-page-zoom-overlay'));
    expect(zoomingPage, findsOneWidget);
    expect(tester.getRect(zoomingPage).width, closeTo(menuRect.width, 6));
    final attachedCover = find.byKey(
      const ValueKey('taste-attached-open-cover'),
    );
    expect(attachedCover, findsOneWidget);
    expect(
      find.byKey(const ValueKey('taste-attached-book-spine')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('taste-page-backdrop-blur')),
      findsOneWidget,
    );

    await tester.pump(const Duration(milliseconds: 91));
    await tester.pump(const Duration(milliseconds: 325));
    final openingPageRect = tester.getRect(zoomingPage);
    expect(openingPageRect.width, greaterThan(menuRect.width * 2));
    expect(openingPageRect.width, lessThan(viewportRect.width));
    expect(
      openingPageRect.width / openingPageRect.height,
      closeTo(menuRect.width / menuRect.height, 0.03),
    );
    final openingCoverRect = tester.getRect(attachedCover);
    expect(openingCoverRect.right, greaterThan(openingPageRect.left));
    expect(
      openingCoverRect.right,
      lessThan(openingPageRect.left + (openingPageRect.width * 0.08)),
    );

    await tester.pump(const Duration(milliseconds: 326));
    await tester.pump();
    expect(tester.getRect(zoomingPage).width, closeTo(viewportRect.width, 2));
    expect(
      tester.getRect(zoomingPage).height,
      greaterThan(viewportRect.height),
    );
    final settlingTexture = find.byKey(
      const ValueKey('taste-texture-settle-scale'),
    );
    final initialTextureScale = tester
        .widget<Transform>(settlingTexture)
        .transform
        .getMaxScaleOnAxis();
    expect(initialTextureScale, greaterThan(1.05));

    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 225));
    final midwayTextureScale = tester
        .widget<Transform>(settlingTexture)
        .transform
        .getMaxScaleOnAxis();
    expect(midwayTextureScale, greaterThan(1));
    expect(midwayTextureScale, lessThan(initialTextureScale));
    expect(zoomingPage, findsOneWidget);

    await tester.pump(const Duration(milliseconds: 226));
    await tester.pump();
    expect(zoomingPage, findsOneWidget);
    expect(
      tester.widget<Transform>(settlingTexture).transform.getMaxScaleOnAxis(),
      closeTo(1, 0.01),
    );
    await tester.pump(const Duration(milliseconds: 81));
    await tester.pump();
    expect(zoomingPage, findsNothing);
    await tester.pump(const Duration(milliseconds: 31));
    await tester.pump(const Duration(milliseconds: 260));
    final headerReveal = tester.widget<Opacity>(
      find
          .descendant(
            of: find.byKey(const ValueKey('taste-reveal-header')),
            matching: find.byType(Opacity),
          )
          .first,
    );
    final ledgerReveal = tester.widget<Opacity>(
      find
          .descendant(
            of: find.byKey(const ValueKey('taste-reveal-ledger')),
            matching: find.byType(Opacity),
          )
          .first,
    );
    expect(headerReveal.opacity, 1);
    expect(ledgerReveal.opacity, greaterThan(0));
    expect(ledgerReveal.opacity, lessThan(1));
    await tester.pump(const Duration(milliseconds: 261));
    final contentReveal = tester.widget<FadeTransition>(
      find.byKey(const ValueKey('taste-menu-content-reveal')),
    );
    expect(contentReveal.opacity.value, 1);

    expect(find.text('TASTES OF JAPAN'), findsOneWidget);
    expect(find.byKey(const ValueKey('taste-ledger-list')), findsOneWidget);
    expect(find.byKey(const ValueKey('taste-image-EA-JP-001')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('taste-embossed-food-frame')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('taste-background-card-back')),
      findsNWidgets(2),
    );
    expect(
      find.byKey(const ValueKey('taste-background-card-middle')),
      findsNWidgets(2),
    );
    expect(
      find.byKey(const ValueKey('taste-select-a-memory-card')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('taste-ledger-item-3')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byKey(const ValueKey('taste-image-EA-JP-004')), findsOneWidget);
    expect(find.text('KYOTO STREET STALL'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('taste-back-to-gallery')));
    await tester.pump();

    await tester.pump(const Duration(milliseconds: 140));
    final clearingContent = tester.widget<FadeTransition>(
      find.byKey(const ValueKey('taste-menu-content-reveal')),
    );
    expect(clearingContent.opacity.value, greaterThan(0));
    expect(clearingContent.opacity.value, lessThan(1));

    await tester.pump(const Duration(milliseconds: 141));
    await tester.pump();
    await tester.pump();
    expect(find.text('TASTES OF JAPAN'), findsNothing);
    expect(zoomingPage, findsOneWidget);
    final openDuringRouteReturn = tester.widget<Transform>(flippingCover);
    expect(openDuringRouteReturn.transform.entry(0, 0), lessThan(-0.9));
    expect(
      tester.widget<Transform>(settlingTexture).transform.getMaxScaleOnAxis(),
      closeTo(1, 0.01),
    );

    await tester.pump(const Duration(milliseconds: 225));
    final enlargingTextureScale = tester
        .widget<Transform>(settlingTexture)
        .transform
        .getMaxScaleOnAxis();
    expect(enlargingTextureScale, greaterThan(1));
    expect(enlargingTextureScale, lessThan(initialTextureScale));
    expect(tester.getRect(zoomingPage).width, closeTo(viewportRect.width, 2));

    await tester.pump(const Duration(milliseconds: 226));
    await tester.pump();

    await tester.pump(const Duration(milliseconds: 270));
    final closingPageRect = tester.getRect(zoomingPage);
    expect(closingPageRect.width, greaterThan(menuRect.width * 2));
    expect(closingPageRect.width, lessThan(viewportRect.width));
    expect(
      closingPageRect.width / closingPageRect.height,
      closeTo(menuRect.width / menuRect.height, 0.03),
    );
    expect(attachedCover, findsOneWidget);

    await tester.pump(const Duration(milliseconds: 271));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 240));
    final closingCover = tester.widget<Transform>(flippingCover);
    final closingInside = tester.widget<Opacity>(revealedInside);
    expect(closingCover.transform.entry(0, 0), greaterThan(0));
    expect(closingCover.transform.entry(0, 0), lessThan(0.5));
    expect(closingInside.opacity, greaterThan(0.5));

    await tester.pump(const Duration(milliseconds: 241));
    expect(find.byKey(const ValueKey('trip-memory-gallery')), findsOneWidget);
    expect(zoomingPage, findsNothing);
    final closedCover = tester.widget<Transform>(flippingCover);
    final closedInside = tester.widget<Opacity>(revealedInside);
    expect(closedCover.transform.entry(0, 0), closeTo(1, 0.01));
    expect(closedInside.opacity, 0);

    await tester.pump(const Duration(milliseconds: 65));
    final landingMenu = tester.widget<Transform>(
      find.descendant(
        of: find.byKey(const ValueKey('taste-of-japan-menu-0')),
        matching: find.byKey(const ValueKey('taste-menu-lift')),
      ),
    );
    expect(landingMenu.transform.entry(1, 3), lessThan(0));
    await tester.pump(const Duration(milliseconds: 66));
    final landedMenu = tester.widget<Transform>(
      find.descendant(
        of: find.byKey(const ValueKey('taste-of-japan-menu-0')),
        matching: find.byKey(const ValueKey('taste-menu-lift')),
      ),
    );
    expect(landedMenu.transform.entry(1, 3), closeTo(0, 0.01));
  });

  testWidgets('every trip gallery includes its destination menu', (
    tester,
  ) async {
    for (final trip in TripCatalogStore.instance.allTrips) {
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 1280,
            height: 800,
            child: TripJourney(
              trip: trip,
              animation: const AlwaysStoppedAnimation<double>(1),
              onTasteTap: () async {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(ValueKey('taste-of-${trip.slug}-menu-0')),
        findsOneWidget,
        reason: '${trip.name} should include a menu in its gallery wall',
      );
      expect(
        find.text('TASTE OF\n${trip.name.toUpperCase()}'),
        findsNWidgets(2),
      );
    }
  });

  testWidgets('every trip gallery begins with its title centered', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final trip in TripCatalogStore.instance.allTrips) {
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 1280,
            height: 800,
            child: TripJourney(
              trip: trip,
              animation: const AlwaysStoppedAnimation<double>(1),
              onTasteTap: () async {},
            ),
          ),
        ),
      );
      await tester.pump();

      final titleRect = tester.getRect(
        find.byKey(ValueKey<String>('gallery-editorial-title-${trip.slug}-0')),
      );
      expect(
        titleRect.center.dx,
        closeTo(640, 0.1),
        reason: '${trip.name} should reveal with its title in the center',
      );
    }
  });

  testWidgets('gallery slideshows advance on staggered schedules', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 1280,
          height: 800,
          child: TripJourney(
            trip: TripCatalogStore.instance.allTrips.first,
            animation: const AlwaysStoppedAnimation<double>(1),
            onTasteTap: () async {},
          ),
        ),
      ),
    );
    await tester.pump();

    final gallerySwitchers = find.byWidgetPredicate((widget) {
      final key = widget.key;
      return widget is AnimatedSwitcher &&
          key is ValueKey<String> &&
          key.value.startsWith('gallery-memory-switcher-');
    });

    List<String> visibleMediaKeys() =>
        gallerySwitchers.evaluate().map((element) {
          final switcher = element.widget as AnimatedSwitcher;
          return (switcher.child!.key! as ValueKey<String>).value;
        }).toList();

    final before = visibleMediaKeys();
    expect(before, hasLength(24));
    expect(before.take(12), orderedEquals(before.skip(12)));

    await tester.pump(const Duration(seconds: 1));
    final after = visibleMediaKeys();
    final changedFrames = List<int>.generate(
      12,
      (index) => index,
    ).where((index) => before[index] != after[index]).length;

    expect(changedFrames, greaterThan(0));
    expect(changedFrames, lessThan(12));
    expect(after.take(12), orderedEquals(after.skip(12)));

    final transitioningPhotos = find.descendant(
      of: gallerySwitchers,
      matching: find.byType(FadeTransition),
    );
    expect(transitioningPhotos, findsAtLeastNWidgets(25));

    await tester.pump(const Duration(milliseconds: 300));
    final fadeOpacities = tester
        .widgetList<FadeTransition>(transitioningPhotos)
        .map((transition) => transition.opacity.value);
    expect(fadeOpacities.any((opacity) => opacity > 0 && opacity < 1), isTrue);
  });

  testWidgets(
    'in-trip gallery wall follows a mouse drag and resumes drifting',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 1280,
            height: 800,
            child: TripJourney(
              trip: TripCatalogStore.instance.allTrips.first,
              animation: const AlwaysStoppedAnimation<double>(1),
              onTasteTap: () async {},
            ),
          ),
        ),
      );
      await tester.pump();

      double galleryOffset() => tester
          .widget<Transform>(
            find.byKey(const ValueKey('gallery-drift-transform')),
          )
          .transform
          .entry(0, 3);

      final beforeDrag = galleryOffset();
      final drag = await tester.startGesture(
        tester.getCenter(
          find.byKey(const ValueKey('trip-memory-gallery-drag-area')),
        ),
        kind: PointerDeviceKind.mouse,
      );
      await drag.moveBy(const Offset(-20, 0));
      await drag.moveBy(const Offset(-300, 0));
      await tester.pump();

      final duringDrag = galleryOffset();
      const stripWidth = 9180.0;
      final draggedDistance = (beforeDrag - duringDrag) % stripWidth;
      expect(draggedDistance, greaterThan(280));
      expect(draggedDistance, lessThanOrEqualTo(320));
      expect(
        find.byKey(const ValueKey('focused-memory-overlay')),
        findsNothing,
      );

      await drag.up();
      await tester.pump();
      final afterRelease = galleryOffset();
      await tester.pump(const Duration(milliseconds: 500));

      final afterDrift = galleryOffset();
      expect(afterDrift, lessThan(afterRelease));
      expect(
        afterRelease - afterDrift,
        closeTo(6, 0.2),
        reason: 'The gallery should drift at a calm 12 pixels per second',
      );
    },
  );

  testWidgets('China gallery frames render public demo media', (tester) async {
    final china = TripCatalogStore.instance.allTrips.firstWhere(
      (trip) => trip.slug == 'china',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 1280,
          height: 800,
          child: TripJourney(
            trip: china,
            animation: const AlwaysStoppedAnimation<double>(1),
            onTasteTap: () async {},
          ),
        ),
      ),
    );
    await tester.pump();

    final chinaMemoryImages = find.byWidgetPredicate((widget) {
      if (widget is! Image || widget.image is! AssetImage) {
        return false;
      }
      final assetName = (widget.image as AssetImage).assetName;
      return publicDemoMemoryAssets.contains(assetName);
    });

    expect(chinaMemoryImages, findsWidgets);
    expect(find.text('CHINA'), findsWidgets);
  });

  testWidgets('Japan gallery interleaves tappable Instagram post frames', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 1280,
          height: 800,
          child: TripJourney(
            trip: TripCatalogStore.instance.allTrips.first,
            animation: const AlwaysStoppedAnimation<double>(1),
            onTasteTap: () async {},
          ),
        ),
      ),
    );
    await tester.pump();

    final wallpaper = find.byKey(const ValueKey('gallery-repeating-wallpaper'));
    expect(wallpaper, findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('gallery-drift-transform')),
        matching: wallpaper,
      ),
      findsOneWidget,
    );
    final wallpaperImage = tester.widget<Image>(wallpaper);
    expect(wallpaperImage.fit, BoxFit.none);
    expect(wallpaperImage.repeat, ImageRepeat.repeat);
    expect(wallpaperImage.alignment, Alignment.topLeft);
    final vignette = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('gallery-wallpaper-bottom-vignette')),
    );
    final vignetteDecoration = vignette.decoration as BoxDecoration;
    final vignetteGradient = vignetteDecoration.gradient! as LinearGradient;
    expect(vignetteGradient.begin, Alignment.topCenter);
    expect(vignetteGradient.end, Alignment.bottomCenter);
    expect(vignetteGradient.colors.last, const Color(0x8F090100));
    final wallpaperProvider = wallpaperImage.image as ExactAssetImage;
    expect(
      wallpaperProvider.assetName,
      'assets/textures/red_damask_gallery_wall.jpeg',
    );
    expect(wallpaperProvider.scale, closeTo(675 / 575, 0.0001));
    expect(
      find.byKey(const ValueKey('gallery-instagram-post-frame')),
      findsNWidgets(14),
    );
    expect(
      tester.getSize(
        find.byKey(
          ValueKey<String>(
            'japan-instagram-post-${japanInstagramPosts.first.shortcode}-0',
          ),
        ),
      ),
      const Size(408, 600),
    );
    expect(find.text('iihsavru'), findsNothing);
    expect(find.textContaining('REEL '), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('gallery-instagram-post-frame')),
        matching: find.byType(Icon),
      ),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('gallery-instagram-oval-baroque-frame')),
      findsNWidgets(2),
    );
    expect(
      find.byKey(const ValueKey('gallery-instagram-circular-baroque-frame')),
      findsNWidgets(4),
    );
    expect(
      find.byKey(const ValueKey('gallery-instagram-portrait-baroque-frame')),
      findsNWidgets(4),
    );
    expect(
      find.byKey(
        const ValueKey('gallery-instagram-horizontalOval-baroque-frame'),
      ),
      findsNWidgets(4),
    );
    expect(
      find.byKey(const ValueKey('gallery-horizontalOval-baroque-frame')),
      findsNWidgets(4),
    );
    final circularFrames = find.byKey(
      const ValueKey('gallery-circular-baroque-frame'),
    );
    expect(circularFrames, findsNWidgets(4));
    expect(
      tester.getSize(circularFrames.first).width,
      greaterThanOrEqualTo(500),
      reason: 'Circular frames should match the visual scale of nearby frames',
    );
    expect(
      find.byKey(const ValueKey('gallery-circular-media-mask')),
      findsNWidgets(4),
    );
    final horizontalOvalMemoryMasks = find.byKey(
      const ValueKey('gallery-horizontalOval-media-mask'),
    );
    final horizontalOvalInstagramMasks = find.byKey(
      const ValueKey('gallery-instagram-horizontalOval-media-mask'),
    );
    expect(horizontalOvalMemoryMasks, findsNWidgets(4));
    expect(horizontalOvalInstagramMasks, findsNWidgets(4));
    expect(
      tester.widget<ClipOval>(horizontalOvalMemoryMasks.first).child,
      isA<ColoredBox>(),
    );
    expect(
      tester.widget<ClipOval>(horizontalOvalInstagramMasks.first).child,
      isA<ColoredBox>(),
    );
    for (final post in japanInstagramPosts) {
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('gallery-instagram-post-frame')),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Image &&
                widget.image is AssetImage &&
                (widget.image as AssetImage).assetName == post.coverAssetPath,
          ),
        ),
        findsNWidgets(2),
      );
    }

    final visiblePosts = find
        .byKey(const ValueKey('gallery-instagram-post-frame'))
        .hitTestable();
    expect(visiblePosts, findsWidgets);
    await tester.tap(visiblePosts.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1250));

    expect(
      find.byKey(const ValueKey('focused-instagram-post')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('focused-instagram-post')),
        matching: find.byType(Icon),
      ),
      findsNothing,
    );
    final focusedReelSize = tester.getSize(
      find.byKey(const ValueKey('focused-instagram-reel-viewport')),
    );
    expect(focusedReelSize.aspectRatio, closeTo(9 / 16, 0.001));

    tester
        .widget<GestureDetector>(
          find.byKey(const ValueKey('focused-memory-backdrop')),
        )
        .onTap!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 710));
    await tester.pump();

    final japanWallItems = <Finder>[
      for (var copyIndex = 0; copyIndex < 2; copyIndex++) ...<Finder>[
        for (var memoryIndex = 0; memoryIndex < 12; memoryIndex++)
          find.byKey(
            ValueKey<String>(
              'gallery-memory-layout-japan-$memoryIndex-$copyIndex',
            ),
          ),
        for (final post in japanInstagramPosts)
          find.byKey(
            ValueKey<String>(
              'japan-instagram-post-${post.shortcode}-$copyIndex',
            ),
          ),
        find.byKey(ValueKey<String>('taste-of-japan-menu-$copyIndex')),
        find.byKey(
          ValueKey<String>('gallery-editorial-title-japan-$copyIndex'),
        ),
      ],
    ];
    for (final finder in japanWallItems) {
      expect(finder, findsOneWidget, reason: finder.toString());
    }
    final japanWallBounds = <({String label, Rect rect})>[
      for (final finder in japanWallItems)
        (
          label: finder.toString(),
          rect: MatrixUtils.transformRect(
            tester.renderObject<RenderBox>(finder).getTransformTo(null),
            Offset.zero & tester.getSize(finder),
          ),
        ),
    ];

    Rect globalRect(Finder finder) => MatrixUtils.transformRect(
      tester.renderObject<RenderBox>(finder).getTransformTo(null),
      Offset.zero & tester.getSize(finder),
    );

    final firstCopyFrames = <Rect>[
      for (var memoryIndex = 0; memoryIndex < 12; memoryIndex++)
        globalRect(
          find.byKey(
            ValueKey<String>('gallery-memory-layout-japan-$memoryIndex-0'),
          ),
        ),
    ];
    final firstCopyPosts = <Rect>[
      for (final post in japanInstagramPosts)
        globalRect(
          find.byKey(
            ValueKey<String>('japan-instagram-post-${post.shortcode}-0'),
          ),
        ),
    ];
    final titleRect = globalRect(
      find.byKey(const ValueKey('gallery-editorial-title-japan-0')),
    );
    final menuRect = globalRect(
      find.byKey(const ValueKey('taste-of-japan-menu-0')),
    );
    final rowItems = <Rect>[
      ...firstCopyFrames,
      ...firstCopyPosts,
      menuRect,
      titleRect,
    ];
    final rowCenters = rowItems.map((rect) => rect.center.dy).toList();
    expect(
      rowCenters.reduce(math.max) - rowCenters.reduce(math.min),
      lessThan(1),
      reason: 'Every frame, social post, menu, and title should share one row',
    );
    expect(firstCopyPosts.first.width, greaterThan(175));
    expect(firstCopyPosts.first.height, greaterThan(260));
    expect(menuRect.width, greaterThan(240));
    expect(menuRect.height, greaterThan(160));

    final frameAreaBands = firstCopyFrames
        .map((rect) => (rect.width * rect.height / 2000).round())
        .toSet();
    expect(
      frameAreaBands.length,
      greaterThanOrEqualTo(8),
      reason: 'The gallery wall should use subtly varied frame scales',
    );
    final firstCopyWallRects = <Rect>[
      ...firstCopyFrames,
      ...firstCopyPosts,
      menuRect,
      titleRect,
    ]..sort((a, b) => a.left.compareTo(b.left));
    var coverageFrontier = firstCopyWallRects.first.right;
    var largestHorizontalGap = 0.0;
    for (final rect in firstCopyWallRects.skip(1)) {
      largestHorizontalGap = math.max(
        largestHorizontalGap,
        rect.left - coverageFrontier,
      );
      coverageFrontier = math.max(coverageFrontier, rect.right);
    }
    expect(
      largestHorizontalGap,
      lessThan(64),
      reason: 'The salon wall should not leave broad empty vertical patches',
    );
    expect(
      coverageFrontier - firstCopyWallRects.first.left,
      greaterThan(6100),
      reason: 'The wall composition should stay balanced across the strip',
    );

    for (var first = 0; first < japanWallBounds.length; first++) {
      for (var second = first + 1; second < japanWallBounds.length; second++) {
        final overlap = japanWallBounds[first].rect.intersect(
          japanWallBounds[second].rect,
        );
        expect(
          overlap.width <= 0 || overlap.height <= 0,
          isTrue,
          reason:
              '${japanWallBounds[first].label} overlaps '
              '${japanWallBounds[second].label} by $overlap',
        );
      }
    }

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('Sri Lanka gallery frames render public demo media', (
    tester,
  ) async {
    final sriLanka = TripCatalogStore.instance.allTrips.firstWhere(
      (trip) => trip.slug == 'sri-lanka',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 1280,
          height: 800,
          child: TripJourney(
            trip: sriLanka,
            animation: const AlwaysStoppedAnimation<double>(1),
            onTasteTap: () async {},
          ),
        ),
      ),
    );
    await tester.pump();

    final sriLankaMemoryImages = find.byWidgetPredicate((widget) {
      if (widget is! Image || widget.image is! AssetImage) {
        return false;
      }
      final assetName = (widget.image as AssetImage).assetName;
      return publicDemoMemoryAssets.contains(assetName);
    });

    expect(sriLankaMemoryImages, findsWidgets);
    expect(find.text('SRI LANKA'), findsWidgets);
    for (final location in TripCatalogStore.instance.memoryLocationsFor(
      'sri-lanka',
    )) {
      expect(
        find.text(location.label.toUpperCase()),
        findsWidgets,
        reason: '${location.label} should appear on the Sri Lanka gallery wall',
      );
    }
  });

  testWidgets('Hong Kong gallery frames render public demo media', (
    tester,
  ) async {
    final hongKong = TripCatalogStore.instance.allTrips.firstWhere(
      (trip) => trip.slug == 'hong-kong',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 1280,
          height: 800,
          child: TripJourney(
            trip: hongKong,
            animation: const AlwaysStoppedAnimation<double>(1),
            onTasteTap: () async {},
          ),
        ),
      ),
    );
    await tester.pump();

    final hongKongMemoryImages = find.byWidgetPredicate((widget) {
      if (widget is! Image || widget.image is! AssetImage) {
        return false;
      }
      final assetName = (widget.image as AssetImage).assetName;
      return publicDemoMemoryAssets.contains(assetName);
    });

    expect(hongKongMemoryImages, findsWidgets);
    expect(find.text('HONG KONG'), findsWidgets);
    for (final location in TripCatalogStore.instance.memoryLocationsFor(
      'hong-kong',
    )) {
      expect(
        find.text(location.label.toUpperCase()),
        findsWidgets,
        reason: '${location.label} should appear on the Hong Kong gallery wall',
      );
    }
  });

  testWidgets('Taiwan gallery frames render public demo media', (tester) async {
    final taiwan = TripCatalogStore.instance.allTrips.firstWhere(
      (trip) => trip.slug == 'taiwan',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 1280,
          height: 800,
          child: TripJourney(
            trip: taiwan,
            animation: const AlwaysStoppedAnimation<double>(1),
            onTasteTap: () async {},
          ),
        ),
      ),
    );
    await tester.pump();

    final taiwanMemoryImages = find.byWidgetPredicate((widget) {
      if (widget is! Image || widget.image is! AssetImage) {
        return false;
      }
      final assetName = (widget.image as AssetImage).assetName;
      return publicDemoMemoryAssets.contains(assetName);
    });

    expect(taiwanMemoryImages, findsWidgets);
    expect(find.text('TAIWAN'), findsWidgets);
    for (final location in TripCatalogStore.instance.memoryLocationsFor(
      'taiwan',
    )) {
      expect(
        find.text(location.label.toUpperCase()),
        findsWidgets,
        reason: '${location.label} should appear on the Taiwan gallery wall',
      );
    }
  });

  testWidgets('Bali gallery frames render grouped highlight media', (
    tester,
  ) async {
    final bali = TripCatalogStore.instance.allTrips.firstWhere(
      (trip) => trip.slug == 'bali',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 1280,
          height: 800,
          child: TripJourney(
            trip: bali,
            animation: const AlwaysStoppedAnimation<double>(1),
            onTasteTap: () async {},
          ),
        ),
      ),
    );
    await tester.pump();

    final baliMemoryImages = find.byWidgetPredicate((widget) {
      if (widget is! Image || widget.image is! AssetImage) {
        return false;
      }
      final assetName = (widget.image as AssetImage).assetName;
      // Bali is registered with its real photos rather than public demo
      // placeholders, unlike the other still-placeholder demo trips.
      return assetName.startsWith('assets/memories/bali/');
    });

    expect(baliMemoryImages, findsWidgets);
    expect(find.text('BALI'), findsWidgets);
    for (final location in TripCatalogStore.instance.memoryLocationsFor(
      'bali',
    )) {
      expect(
        find.text(location.label.toUpperCase()),
        findsWidgets,
        reason: '${location.label} should appear on the Bali gallery wall',
      );
    }
  });

  testWidgets('South Korea gallery frames render public demo media', (
    tester,
  ) async {
    final southKorea = TripCatalogStore.instance.allTrips.firstWhere(
      (trip) => trip.slug == 'south-korea',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 1280,
          height: 800,
          child: TripJourney(
            trip: southKorea,
            animation: const AlwaysStoppedAnimation<double>(1),
            onTasteTap: () async {},
          ),
        ),
      ),
    );
    await tester.pump();

    final southKoreaMemoryImages = find.byWidgetPredicate((widget) {
      if (widget is! Image || widget.image is! AssetImage) {
        return false;
      }
      final assetName = (widget.image as AssetImage).assetName;
      return publicDemoMemoryAssets.contains(assetName);
    });

    expect(southKoreaMemoryImages, findsWidgets);
    final keepsakeImages = find.byWidgetPredicate((widget) {
      if (widget is! Image || widget.image is! AssetImage) {
        return false;
      }
      final assetName = (widget.image as AssetImage).assetName;
      return galleryTrinketAssetChoices.contains(assetName);
    });
    expect(keepsakeImages, findsNWidgets(20));
    expect(
      find.byKey(
        const ValueKey('south-korea-keepsake-china-nfc-magnet-reveal-0'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey(
          'south-korea-keepsake-vietnam-nfc-magnet-reveal-lotus-1',
        ),
      ),
      findsOneWidget,
    );
    for (final keepsakeName in <String>[
      'china-nfc-magnet-reveal',
      'hong-kong-nfc-magnet-reveal',
      'japan-nfc-magnet-reveal-fox',
      'taiwan-nfc-magnet-reveal-bubble-tea',
      'vietnam-nfc-magnet-reveal-lotus',
    ]) {
      final keepsake = find.byKey(
        ValueKey<String>('south-korea-keepsake-$keepsakeName-0'),
      );
      expect(
        tester.getCenter(keepsake).dy,
        closeTo(405, 1),
        reason: '$keepsakeName should share the gallery frame row',
      );
    }
    expect(find.text('SOUTH KOREA'), findsWidgets);
    for (final location in TripCatalogStore.instance.memoryLocationsFor(
      'south-korea',
    )) {
      expect(
        find.text(location.label.toUpperCase()),
        findsWidgets,
        reason: '${location.label} should appear on the South Korea wall',
      );
    }
  });

  testWidgets('an uncurated trip menu opens destination-specific content', (
    tester,
  ) async {
    final southKorea = TripCatalogStore.instance.allTrips.firstWhere(
      (trip) => trip.name == 'South Korea',
    );
    await tester.pumpWidget(
      MaterialApp(home: TripTasteMenuScreen(trip: southKorea)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 111));
    await tester.pump(const Duration(milliseconds: 521));

    expect(find.text('TASTES OF SOUTH KOREA'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('taste-empty-south-korea')),
      findsOneWidget,
    );
    expect(find.text('MENU COLLECTION IN PROGRESS'), findsOneWidget);
  });

  testWidgets('home gallery pauses for a trip and resumes on return', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: EverAfterApp(showSplash: false)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byKey(const ValueKey('trip-0-japan')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2100));

    var gallery = tester.widget<TripGallery>(
      find.byType(TripGallery, skipOffstage: false),
    );
    expect(gallery.autoScrollEnabled, isFalse);
    final pausedOffset = gallery.controller.offset;
    await tester.pump(const Duration(seconds: 2));
    expect(gallery.controller.offset, closeTo(pausedOffset, 0.001));

    await tester.tap(find.byTooltip('Back to travel gallery'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1150));

    gallery = tester.widget<TripGallery>(find.byType(TripGallery));
    expect(gallery.autoScrollEnabled, isTrue);
    final resumedOffset = gallery.controller.offset;
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 2));
    expect(gallery.controller.offset, greaterThan(resumedOffset));
  });

  testWidgets('a trip card opens and returns from its start experience', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: EverAfterApp(showSplash: false)),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('trip-0-japan')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1100));
    expect(tester.takeException(), isNull);
    final clipFinder = find.byKey(const ValueKey('trip-flight-window'));
    final imageFinder = find.byKey(const ValueKey('trip-flight-image'));
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('trip-flight-unit')),
        matching: find.byKey(const ValueKey('trip-card-paper-texture')),
      ),
      findsNothing,
    );
    final clipRender = tester.renderObject<RenderClipPath>(clipFinder);
    final localClipBounds = clipRender.clipper!
        .getClip(clipRender.size)
        .getBounds();
    final clipBounds = Rect.fromPoints(
      clipRender.localToGlobal(localClipBounds.topLeft),
      clipRender.localToGlobal(localClipBounds.bottomRight),
    );
    final imageBounds = tester.getRect(imageFinder);
    expect(imageBounds.left, lessThanOrEqualTo(clipBounds.left + 0.01));
    expect(imageBounds.top, lessThanOrEqualTo(clipBounds.top + 0.01));
    expect(
      imageBounds.right,
      greaterThanOrEqualTo(clipBounds.right - 0.01),
      reason:
          'image=$imageBounds clip=$clipBounds '
          'flight=${tester.getRect(clipFinder)}',
    );
    expect(
      imageBounds.bottom,
      greaterThanOrEqualTo(clipBounds.bottom - 0.01),
      reason:
          'image=$imageBounds clip=$clipBounds '
          'flight=${tester.getRect(clipFinder)}',
    );
    final frameExpansion = tester.widget<Transform>(
      find.byKey(const ValueKey('trip-flight-frame-expansion')),
    );
    expect(frameExpansion.transform.getMaxScaleOnAxis(), greaterThan(1));
    await tester.pump(const Duration(milliseconds: 760));
    final lateFlightBounds = tester.getRect(clipFinder);
    final lateImageBounds = tester.getRect(imageFinder);
    expect(
      (lateImageBounds.center - lateFlightBounds.center).distance,
      lessThan(1),
    );
    expect((lateImageBounds.width - lateFlightBounds.width).abs(), lessThan(2));
    expect(
      (lateImageBounds.height - lateFlightBounds.height).abs(),
      lessThan(2),
    );
    await tester.pump(const Duration(milliseconds: 190));

    expect(find.text('JAPAN'), findsOneWidget);
    expect(find.text('DATES TO BE ADDED'), findsOneWidget);
    expect(find.textContaining('DAYS'), findsNothing);
    expect(find.text('START'), findsOneWidget);
    expect(find.text('MUSEUM OF TRAVELS'), findsNothing);

    await tester.tap(find.byTooltip('Back to travel gallery'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    final reverseFlight = find.byKey(const ValueKey('trip-flight-unit'));
    expect(reverseFlight, findsOneWidget);
    expect(
      find.descendant(
        of: reverseFlight,
        matching: find.byKey(const ValueKey('trip-flight-window')),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: reverseFlight,
        matching: find.byKey(const ValueKey('trip-flight-image')),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: reverseFlight,
        matching: find.byKey(const ValueKey('trip-flight-frame-expansion')),
      ),
      findsOneWidget,
    );
    final reverseFrameExpansion = tester.widget<Transform>(
      find.byKey(const ValueKey('trip-flight-frame-expansion')),
    );
    expect(reverseFrameExpansion.transform.getMaxScaleOnAxis(), greaterThan(1));

    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('MUSEUM OF TRAVELS'), findsOneWidget);
  });

  testWidgets('Start runs the globe-to-drifting-memory-wall journey', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: EverAfterApp(showSplash: false)),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('trip-0-japan')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2100));

    await tester.tap(find.byKey(const ValueKey('start-trip-experience')));
    await tester.pump();

    expect(find.byKey(const ValueKey('trip-globe-scene')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('destination-globe-raster')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('destination-globe-atmosphere')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('destination-globe-upper-hemisphere')),
      findsOneWidget,
    );
    expect(
      tester.getSize(
        find.byKey(const ValueKey('destination-globe-upper-hemisphere')),
      ),
      const Size(1024, 512),
    );
    expect(
      find.byKey(const ValueKey('destination-area-outline')),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label ==
                'Japan destination area outlined and glowing',
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('trip-globe-destination')),
      findsOneWidget,
    );

    await tester.pump(const Duration(milliseconds: 100));
    expect(
      find.byWidgetPredicate((widget) {
        final key = widget.key;
        return widget is Positioned &&
            key is ValueKey<String> &&
            key.value.startsWith('destination-globe-frame-blend-');
      }),
      findsOneWidget,
    );

    final driftAtStart = tester
        .widget<Transform>(
          find.byKey(const ValueKey('gallery-drift-transform')),
        )
        .transform
        .getTranslation()
        .x;

    await tester.pump(const Duration(milliseconds: 7600));

    final galleryOpacity = tester.widget<Opacity>(
      find.byKey(const ValueKey('trip-memory-gallery-opacity')),
    );
    final driftAfterReveal = tester
        .widget<Transform>(
          find.byKey(const ValueKey('gallery-drift-transform')),
        )
        .transform
        .getTranslation()
        .x;

    expect(galleryOpacity.opacity, greaterThan(0.95));
    expect(driftAfterReveal, lessThan(driftAtStart));
    expect(find.byKey(const ValueKey('gallery-memory-frame')), findsWidgets);
    for (final label in <String>[
      'TOKYO',
      'KYOTO',
      'OSAKA',
      'NARA',
      'HIROSHIMA',
    ]) {
      expect(find.text(label), findsWidgets);
    }
    final visibleSlideshowFrames = find
        .byKey(const ValueKey('gallery-memory-frame'))
        .hitTestable();
    expect(visibleSlideshowFrames, findsWidgets);
    await tester.tap(visibleSlideshowFrames.first);
    await tester.pump();

    expect(
      find.byKey(const ValueKey('focused-memory-overlay')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('focused-memory-frame')), findsOneWidget);
    expect(
      tester
          .widget<Stack>(
            find.byKey(const ValueKey('focused-memory-camera-plane')),
          )
          .clipBehavior,
      Clip.none,
    );
    expect(
      find.byKey(const ValueKey('focused-memory-frame-opacity')),
      findsNothing,
    );
    expect(
      tester
          .widget<Opacity>(
            find.byKey(
              const ValueKey('focused-memory-transition-frame-opacity'),
            ),
          )
          .opacity,
      1,
    );
    expect(
      tester
          .widget<Opacity>(
            find.byKey(const ValueKey('focused-memory-media-opacity')),
          )
          .opacity,
      0,
    );
    await tester.pump(const Duration(milliseconds: 625));

    final midSpotlight = tester.widget<Opacity>(
      find.byKey(const ValueKey('focused-memory-spotlight')),
    );
    expect(midSpotlight.opacity, lessThan(0.05));
    expect(
      find.byKey(const ValueKey('focused-memory-frame-opacity')),
      findsNothing,
    );
    final midTransitionFrameOpacity = tester
        .widget<Opacity>(
          find.byKey(const ValueKey('focused-memory-transition-frame-opacity')),
        )
        .opacity;
    final midFocusedMediaOpacity = tester
        .widget<Opacity>(
          find.byKey(const ValueKey('focused-memory-media-opacity')),
        )
        .opacity;
    expect(midTransitionFrameOpacity, inExclusiveRange(0, 1));
    expect(midFocusedMediaOpacity, inExclusiveRange(0, 1));
    expect(
      midTransitionFrameOpacity + midFocusedMediaOpacity,
      closeTo(1, 0.001),
    );

    await tester.pump(const Duration(milliseconds: 250));
    expect(
      find.byKey(const ValueKey('focused-memory-frame-opacity')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('focused-memory-transition-frame-opacity')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('focused-memory-media-opacity')),
      findsNothing,
    );

    await tester.pump(const Duration(milliseconds: 375));

    final focusedFrameRect = tester.getRect(
      find.byKey(const ValueKey('focused-memory-frame')),
    );
    final focusedOverlayRect = tester.getRect(
      find.byKey(const ValueKey('focused-memory-overlay')),
    );
    final focusedImageRect = tester.getRect(
      find.byKey(const ValueKey('focused-memory-image')),
    );
    final locationNote = find.byKey(
      const ValueKey('focused-memory-location-note'),
    );
    final locationNoteRect = tester.getRect(locationNote);
    expect(
      (focusedFrameRect.center - focusedOverlayRect.center).distance,
      lessThan(1),
    );
    expect(
      focusedImageRect.height,
      closeTo(focusedOverlayRect.height * 0.9, 1),
    );
    expect(
      find.byKey(const ValueKey('focused-memory-media-only')),
      findsOneWidget,
    );
    expect(focusedFrameRect.top, greaterThan(focusedOverlayRect.top));
    expect(focusedFrameRect.bottom, lessThan(focusedOverlayRect.bottom));
    expect(locationNote, findsOneWidget);
    expect(locationNoteRect.center.dx, lessThan(focusedFrameRect.center.dx));
    expect(
      find.descendant(of: locationNote, matching: find.text('LOCATION')),
      findsOneWidget,
    );
    expect(
      tester.widget<Semantics>(locationNote).properties.label,
      startsWith('Location: '),
    );
    expect(
      find.text(
        'TAP LEFT / RIGHT FOR PREVIOUS / NEXT'
        '  ·  PINCH TO ZOOM'
        '  ·  TAP OUTSIDE TO RETURN',
      ),
      findsOneWidget,
    );

    final interactiveViewerFinder = find.byKey(
      const ValueKey('focused-memory-interactive-viewer'),
    );
    final interactiveViewer = tester.widget<InteractiveViewer>(
      interactiveViewerFinder,
    );
    expect(interactiveViewer.minScale, 1);
    expect(interactiveViewer.maxScale, 4);
    expect(interactiveViewer.panEnabled, isTrue);
    expect(interactiveViewer.scaleEnabled, isTrue);
    expect(interactiveViewer.trackpadScrollCausesScale, isTrue);

    final counterFinder = find.byKey(
      const ValueKey('focused-memory-slideshow-counter'),
    );
    final counterBeforeTap = tester.widget<Text>(counterFinder).data;
    await tester.tap(find.byKey(const ValueKey('focused-memory-next')));
    await tester.pump();
    expect(tester.widget<Text>(counterFinder).data, isNot(counterBeforeTap));
    await tester.tap(find.byKey(const ValueKey('focused-memory-previous')));
    await tester.pump();
    expect(tester.widget<Text>(counterFinder).data, counterBeforeTap);

    final zoomCenter = tester.getCenter(interactiveViewerFinder);
    final firstFinger = await tester.startGesture(
      zoomCenter - const Offset(40, 0),
      pointer: 1,
    );
    final secondFinger = await tester.startGesture(
      zoomCenter + const Offset(40, 0),
      pointer: 2,
    );
    await tester.pump();
    await firstFinger.moveTo(zoomCenter - const Offset(90, 0));
    await secondFinger.moveTo(zoomCenter + const Offset(90, 0));
    await tester.pump();
    expect(
      interactiveViewer.transformationController!.value.getMaxScaleOnAxis(),
      greaterThan(1),
    );
    await firstFinger.up();
    await secondFinger.up();

    final focusedPhotoFades = find.descendant(
      of: find.byKey(const ValueKey('focused-memory-image')),
      matching: find.byType(FadeTransition),
    );
    expect(focusedPhotoFades, findsNWidgets(2));
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      tester
          .widgetList<FadeTransition>(focusedPhotoFades)
          .map((transition) => transition.opacity.value)
          .any((opacity) => opacity > 0 && opacity < 1),
      isTrue,
    );

    await tester.tap(find.byTooltip('Back to travel gallery'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 720));
    await tester.pump();
    expect(find.byKey(const ValueKey('focused-memory-overlay')), findsNothing);
    expect(find.byKey(const ValueKey('trip-memory-gallery')), findsOneWidget);
    expect(find.text('MUSEUM OF TRAVELS'), findsNothing);

    await tester.tap(find.byTooltip('Back to travel gallery'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1150));
    expect(find.text('MUSEUM OF TRAVELS'), findsOneWidget);
  });

  testWidgets('Hong Kong NFC scan opens its centered magnet experience', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: EverAfterApp()));
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(EverAfterApp)),
    );
    unawaited(
      container.read(museumControllerProvider.notifier).requestDemoScan(),
    );
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 2000));

    expect(find.byKey(const ValueKey('splash-sequence-opacity')), findsNothing);
    expect(find.byKey(const ValueKey('nfc-magnet-reveal')), findsOneWidget);
    expect(find.byKey(const ValueKey('nfc-magnet-image')), findsOneWidget);
    expect(find.text('NFC MEMORY FOUND'), findsOneWidget);
    expect(find.byKey(const ValueKey('nfc-glow-pulse')), findsOneWidget);
    expect(find.byKey(const ValueKey('nfc-trip-name')), findsOneWidget);
    expect(find.text('HONG\nKONG'), findsOneWidget);
    expect(find.byKey(const ValueKey('nfc-trip-details')), findsOneWidget);
    expect(find.text('TRIP DETAILS'), findsOneWidget);
    expect(find.text('TO BE ADDED'), findsNWidgets(2));
    expect(find.textContaining('DAYS'), findsNothing);
    expect(find.text('HONG KONG'), findsNothing);
    expect(find.byKey(const ValueKey('pulsing-start-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('start-trip-experience')), findsOneWidget);
    final startButtonRect = tester.getRect(
      find.byKey(const ValueKey('pulsing-start-button')),
    );
    final surfaceRect = tester.getRect(
      find.byKey(const ValueKey('everafter-1280x800-surface')),
    );
    expect((startButtonRect.center - surfaceRect.center).distance, lessThan(1));

    final initialGlowOpacity = tester
        .widget<Opacity>(find.byKey(const ValueKey('nfc-glow-pulse')))
        .opacity;
    await tester.pump(const Duration(milliseconds: 700));
    final laterGlowOpacity = tester
        .widget<Opacity>(find.byKey(const ValueKey('nfc-glow-pulse')))
        .opacity;
    expect(laterGlowOpacity, isNot(closeTo(initialGlowOpacity, 0.001)));

    await tester.tap(find.byTooltip('Back to travel gallery'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1100));
    expect(find.text('MUSEUM OF TRAVELS'), findsOneWidget);
  });

  testWidgets('China NFC scan opens the China trip experience', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: EverAfterApp(showSplash: false)),
    );
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(EverAfterApp)),
    );
    container.read(museumControllerProvider.notifier).selectArtifact(_chinaUid);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));

    expect(find.byKey(const ValueKey('nfc-magnet-reveal')), findsOneWidget);
    final magnetImage = tester.widget<Image>(
      find.byKey(const ValueKey('nfc-magnet-image')),
    );
    expect(
      (magnetImage.image as AssetImage).assetName,
      'assets/images/experience/china-nfc-magnet-reveal.png',
    );
    expect(find.text('NFC MEMORY FOUND'), findsOneWidget);
    expect(find.text('CHINA'), findsOneWidget);
    expect(find.text('TO BE ADDED'), findsNWidgets(2));
    expect(find.textContaining('DAYS'), findsNothing);
    expect(find.byKey(const ValueKey('start-trip-experience')), findsOneWidget);
  });

  testWidgets('South Korea NFC scan opens the South Korea trip experience', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: EverAfterApp(showSplash: false)),
    );
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(EverAfterApp)),
    );
    container
        .read(museumControllerProvider.notifier)
        .selectArtifact(_southKoreaUid);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));

    expect(find.byKey(const ValueKey('nfc-magnet-reveal')), findsOneWidget);
    final magnetImage = tester.widget<Image>(
      find.byKey(const ValueKey('nfc-magnet-image')),
    );
    expect(
      (magnetImage.image as AssetImage).assetName,
      'assets/images/experience/south-korea-nfc-magnet-reveal-spacious.png',
    );
    expect(find.text('NFC MEMORY FOUND'), findsOneWidget);
    expect(find.text('SOUTH\nKOREA'), findsOneWidget);
    expect(find.text('TO BE ADDED'), findsNWidgets(2));
    expect(find.textContaining('DAYS'), findsNothing);
    expect(find.byKey(const ValueKey('start-trip-experience')), findsOneWidget);
  });

  testWidgets('Japan NFC scan opens the Japan trip experience', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: EverAfterApp(showSplash: false)),
    );
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(EverAfterApp)),
    );
    container.read(museumControllerProvider.notifier).selectArtifact(_japanUid);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));

    expect(find.byKey(const ValueKey('nfc-magnet-reveal')), findsOneWidget);
    final magnetImage = tester.widget<Image>(
      find.byKey(const ValueKey('nfc-magnet-image')),
    );
    expect(
      (magnetImage.image as AssetImage).assetName,
      'assets/images/experience/japan-nfc-magnet-reveal-fox.png',
    );
    expect(find.text('NFC MEMORY FOUND'), findsOneWidget);
    expect(find.text('JAPAN'), findsOneWidget);
    expect(find.text('TO BE ADDED'), findsNWidgets(2));
    expect(find.textContaining('DAYS'), findsNothing);
    expect(find.byKey(const ValueKey('start-trip-experience')), findsOneWidget);
  });

  testWidgets('a new NFC scan replaces a trip that is already playing', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: EverAfterApp(showSplash: false)),
    );
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(EverAfterApp)),
    );
    final nfcService = container.read(nfcServiceProvider);
    unawaited(nfcService.scanDemo(_japanUid));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 1200));

    await tester.tap(find.byKey(const ValueKey('start-trip-experience')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.byKey(const ValueKey('trip-memory-gallery')), findsOneWidget);

    unawaited(nfcService.scanDemo(_chinaUid));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 1200));

    expect(find.byKey(const ValueKey('nfc-magnet-reveal')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('nfc-trip-name')),
        matching: find.text('CHINA'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('start-trip-experience')), findsOneWidget);
    expect(find.byKey(const ValueKey('trip-memory-gallery')), findsNothing);
    final magnetImage = tester.widget<Image>(
      find.byKey(const ValueKey('nfc-magnet-image')),
    );
    expect(
      (magnetImage.image as AssetImage).assetName,
      'assets/images/experience/china-nfc-magnet-reveal.png',
    );
  });

  testWidgets('Taiwan NFC scan opens the Taiwan trip experience', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: EverAfterApp(showSplash: false)),
    );
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(EverAfterApp)),
    );
    container
        .read(museumControllerProvider.notifier)
        .selectArtifact(_taiwanUid);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));

    expect(find.byKey(const ValueKey('nfc-magnet-reveal')), findsOneWidget);
    final magnetImage = tester.widget<Image>(
      find.byKey(const ValueKey('nfc-magnet-image')),
    );
    expect(
      (magnetImage.image as AssetImage).assetName,
      'assets/images/experience/taiwan-nfc-magnet-reveal-bubble-tea.png',
    );
    expect(find.text('NFC MEMORY FOUND'), findsOneWidget);
    expect(find.text('TAIWAN'), findsOneWidget);
    expect(find.text('TO BE ADDED'), findsNWidgets(2));
    expect(find.textContaining('DAYS'), findsNothing);
    expect(find.byKey(const ValueKey('start-trip-experience')), findsOneWidget);
  });

  testWidgets('Bali NFC scan opens the Bali trip experience', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: EverAfterApp(showSplash: false)),
    );
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(EverAfterApp)),
    );
    container.read(museumControllerProvider.notifier).selectArtifact(_baliUid);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));

    expect(find.byKey(const ValueKey('nfc-magnet-reveal')), findsOneWidget);
    expect(find.text('NFC MEMORY FOUND'), findsOneWidget);
    expect(find.text('BALI'), findsOneWidget);
    expect(find.byKey(const ValueKey('start-trip-experience')), findsOneWidget);
  });

  testWidgets('Thailand NFC scan opens the Thailand trip experience', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: EverAfterApp(showSplash: false)),
    );
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(EverAfterApp)),
    );
    container
        .read(museumControllerProvider.notifier)
        .selectArtifact(_thailandUid);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));

    expect(find.byKey(const ValueKey('nfc-magnet-reveal')), findsOneWidget);
    expect(find.text('NFC MEMORY FOUND'), findsOneWidget);
    expect(find.text('THAILAND'), findsOneWidget);
    expect(find.byKey(const ValueKey('start-trip-experience')), findsOneWidget);
  });

  testWidgets('Philippines NFC scan opens the Philippines trip experience', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: EverAfterApp(showSplash: false)),
    );
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(EverAfterApp)),
    );
    container
        .read(museumControllerProvider.notifier)
        .selectArtifact(_philippinesUid);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));

    expect(find.byKey(const ValueKey('nfc-magnet-reveal')), findsOneWidget);
    expect(find.text('NFC MEMORY FOUND'), findsOneWidget);
    expect(find.text('PHILIPPINES'), findsOneWidget);
    expect(find.byKey(const ValueKey('start-trip-experience')), findsOneWidget);
  });

  testWidgets('Vietnam NFC scan opens the Vietnam trip experience', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: EverAfterApp(showSplash: false)),
    );
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(EverAfterApp)),
    );
    container
        .read(museumControllerProvider.notifier)
        .selectArtifact(_vietnamUid);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));

    expect(find.byKey(const ValueKey('nfc-magnet-reveal')), findsOneWidget);
    final magnetImage = tester.widget<Image>(
      find.byKey(const ValueKey('nfc-magnet-image')),
    );
    expect(
      (magnetImage.image as AssetImage).assetName,
      'assets/images/experience/vietnam-nfc-magnet-reveal-lotus.png',
    );
    expect(find.text('NFC MEMORY FOUND'), findsOneWidget);
    expect(find.text('VIETNAM'), findsOneWidget);
    expect(find.byKey(const ValueKey('start-trip-experience')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('start-trip-experience')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2200));

    expect(find.text('DATES TO BE ADDED'), findsAtLeastNWidgets(1));
  });

  testWidgets('Sri Lanka NFC scan opens the Sri Lanka trip experience', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: EverAfterApp(showSplash: false)),
    );
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(EverAfterApp)),
    );
    container
        .read(museumControllerProvider.notifier)
        .selectArtifact(_sriLankaUid);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));

    expect(find.byKey(const ValueKey('nfc-magnet-reveal')), findsOneWidget);
    expect(find.text('NFC MEMORY FOUND'), findsOneWidget);
    expect(find.text('SRI\nLANKA'), findsOneWidget);
    expect(find.byKey(const ValueKey('start-trip-experience')), findsOneWidget);
  });

  testWidgets('trip card keeps the photo-based Start experience', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: EverAfterApp(showSplash: false)),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('trip-0-japan')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2100));

    expect(find.text('JAPAN'), findsOneWidget);
    expect(find.byKey(const ValueKey('trip-experience-title')), findsOneWidget);
    expect(find.byKey(const ValueKey('nfc-magnet-reveal')), findsNothing);
    expect(find.byKey(const ValueKey('pulsing-start-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('start-trip-experience')), findsOneWidget);
  });

  testWidgets('artifact intro can still begin its exhibit', (tester) async {
    await _openDemoExhibit(tester);

    expect(find.byKey(const ValueKey('exhibit-pages')), findsOneWidget);
    expect(
      find.text('The souvenir remembers the light first.'),
      findsOneWidget,
    );
  });

  testWidgets('collection catalogue exposes every local artifact', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const ProviderScope(child: EverAfterApp(showSplash: false)),
    );
    await tester.pump();

    GoRouter.of(
      tester.element(find.text('MUSEUM OF TRAVELS')),
    ).go('/collection');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Collection Catalogue'), findsOneWidget);
    expect(find.text('Fridge Magnet With Harbour Light'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('collection-04:00:00:00:00:0B')),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Station Ticket Stub'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('collection-04:00:00:00:00:0C')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Black Sand Vial'), findsOneWidget);
  });

  testWidgets('finishing an exhibit returns the museum to idle', (
    tester,
  ) async {
    await _openDemoExhibit(tester);

    final nextButton = find.byKey(const ValueKey('next-chapter'));
    for (var page = 1; page < 3; page++) {
      await tester.tap(nextButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
    }

    expect(find.text('EXIT'), findsOneWidget);
    await tester.tap(nextButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('MUSEUM OF TRAVELS'), findsOneWidget);
    expect(find.byKey(const ValueKey('exhibit-pages')), findsNothing);
  });
}

Future<void> _openDemoExhibit(WidgetTester tester) async {
  await tester.pumpWidget(
    const ProviderScope(child: EverAfterApp(showSplash: false)),
  );
  await tester.pump();

  GoRouter.of(
    tester.element(find.text('MUSEUM OF TRAVELS')),
  ).go('/intro/$_demoUid');
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));

  expect(find.text('Fridge Magnet With Harbour Light'), findsWidgets);
  expect(find.text('Tap to begin'.toUpperCase()), findsOneWidget);

  final beginButton = find.byKey(const ValueKey('begin-exhibit'));
  await tester.ensureVisible(beginButton);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(beginButton);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}
