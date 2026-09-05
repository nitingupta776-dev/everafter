import 'dart:io';

import 'package:everafter/data/trip_catalog_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await TripCatalogStore.instance.load();
    root = Directory.systemTemp.createTempSync('everafter-catalog-test-');
  });

  tearDown(() async {
    await TripCatalogStore.instance.setExternalMemoriesRoot(null);
    root.deleteSync(recursive: true);
  });

  test('with no external root configured, falls back to the registered '
      "(bundled) collection exactly as before this feature existed", () {
    final store = TripCatalogStore.instance;
    expect(store.externalMemoriesRoot, isNull);
    final baliLocations = store.memoryLocationsFor('bali');
    expect(baliLocations, isNotEmpty);
    expect(
      baliLocations.first.assetPaths.first,
      startsWith('assets/memories/bali/'),
    );
  });

  test('once a root is configured, a trip with real files there is read live '
      'instead of the registered collection', () async {
    final store = TripCatalogStore.instance;
    final baliFolder = Directory('${root.path}/bali')..createSync();
    File('${baliFolder.path}/from-sd-card.jpg').writeAsBytesSync(<int>[]);

    await store.setExternalMemoriesRoot(root.path);

    final locations = store.memoryLocationsFor('bali');
    expect(locations, hasLength(1));
    expect(locations.single.assetPaths.single, endsWith('from-sd-card.jpg'));
  });

  test("a trip whose folder isn't present on the configured root still falls "
      'back to the registered collection', () async {
    final store = TripCatalogStore.instance;
    // root exists, but has no "bali" subfolder in it.
    await store.setExternalMemoriesRoot(root.path);

    final locations = store.memoryLocationsFor('bali');
    expect(locations, isNotEmpty);
    expect(
      locations.first.assetPaths.first,
      startsWith('assets/memories/bali/'),
    );
  });

  test(
    'rescanExternalMemories picks up files added after the first scan',
    () async {
      final store = TripCatalogStore.instance;
      final baliFolder = Directory('${root.path}/bali')..createSync();
      await store.setExternalMemoriesRoot(root.path);

      expect(store.memoryLocationsFor('bali'), isNotEmpty);
      // The folder existed but was empty on the first read, so it already
      // fell back to the bundled collection; now add a real file and confirm
      // a rescan (not just re-calling memoryLocationsFor) picks it up.
      File('${baliFolder.path}/added-later.jpg').writeAsBytesSync(<int>[]);
      store.rescanExternalMemories();

      final locations = store.memoryLocationsFor('bali');
      expect(locations.single.assetPaths.single, endsWith('added-later.jpg'));
    },
  );

  test(
    'a trip with no memoriesFolder ignores the external root entirely',
    () async {
      final store = TripCatalogStore.instance;
      await store.setExternalMemoriesRoot(root.path);

      final japanLocations = store.memoryLocationsFor('japan');
      // Japan is a demo trip (memoriesFolder == null) — must keep using its
      // registered/bundled collection, never attempt a filesystem scan.
      expect(japanLocations, isNotEmpty);
    },
  );
}
