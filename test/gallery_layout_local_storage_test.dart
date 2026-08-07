import 'dart:convert';

import 'package:everafter/data/gallery_layout.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'loads, migrates, and saves gallery layouts only in local preferences',
    () async {
      const legacyStorageKey = 'everafter.gallery-layout.v1';
      const overridesKey = 'everafter.gallery-layout.device-overrides.v1';
      const embeddedImage =
          'data:image/png;base64,'
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJ'
          'AAAADUlEQVR42mNk+M/wHwAF/gL+XKzLAAAAAElFTkSuQmCC';
      final storedLayout = defaultGalleryLayoutFor('japan').toJson()
        ..['stripWidth'] = 4321
        ..['trinkets'] = <Map<String, Object?>>[
          <String, Object?>{
            'id': 'legacy-cloud-trinket',
            'assetName': 'https://old-backend.invalid/trinket.png',
            'label': 'Cloud only',
            'left': 10,
            'top': 20,
            'width': 30,
            'height': 40,
            'storageKey': 'obsolete/cloud/key.png',
          },
          <String, Object?>{
            'id': 'local-trinket',
            'assetName': embeddedImage,
            'label': 'Local image',
            'left': 50,
            'top': 60,
            'width': 70,
            'height': 80,
            'isCustom': true,
          },
        ];
      SharedPreferences.setMockInitialValues(<String, Object>{
        legacyStorageKey: jsonEncode(<String, Object?>{'japan': storedLayout}),
      });

      final store = GalleryLayoutStore.instance;
      await store.load();

      final loaded = store.layoutFor('japan');
      expect(loaded.stripWidth, 4321);
      expect(loaded.trinkets.map((item) => item.id), <String>['local-trinket']);
      expect(store.hasUnsavedChanges, isFalse);

      store.updateFrame(
        'japan',
        loaded.frames.first.copyWith(title: 'Saved on this device'),
      );
      await store.save();

      final preferences = await SharedPreferences.getInstance();
      final saved = preferences.getString(overridesKey)!;
      expect(saved, contains('Saved on this device'));
      expect(saved, contains(embeddedImage));
      expect(saved, isNot(contains('old-backend.invalid')));
      expect(saved, isNot(contains('storageKey')));
      expect(preferences.getString(legacyStorageKey), isNull);
      expect(store.hasUnsavedChanges, isFalse);
    },
  );

  test(
    'stores only changed global layout sections as a device override',
    () async {
      const overridesKey = 'everafter.gallery-layout.device-overrides.v1';
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final store = GalleryLayoutStore.instance;
      await store.load();
      final globalFrame = store.layoutFor('japan').frames.first;
      store.updateFrame(
        'japan',
        globalFrame.copyWith(title: 'Only on this device'),
      );
      await store.save();

      final preferences = await SharedPreferences.getInstance();
      final document = jsonDecode(preferences.getString(overridesKey)!) as Map;
      final japan = (document['overrides'] as Map)['japan'] as Map;
      expect(japan.keys, contains('frames'));
      expect(japan.keys, isNot(contains('foodMenu')));
      expect(japan.keys, isNot(contains('stripWidth')));
      expect(jsonEncode(japan), contains('Only on this device'));
    },
  );

  test('global layout document round-trips all bundled data', () {
    final original = <String, GalleryTripLayout>{
      'japan': defaultGalleryLayoutFor('japan'),
      'south-korea': defaultGalleryLayoutFor('south-korea'),
    };
    final decoded = decodeGlobalGalleryLayoutDocument(
      encodeGlobalGalleryLayoutDocument(original),
    );

    expect(decoded.keys, original.keys);
    expect(decoded['japan']!.toJson(), original['japan']!.toJson());
    expect(decoded['south-korea']!.toJson(), original['south-korea']!.toJson());
  });

  test('bundled global JSON contains every trip layout', () async {
    final contents = await rootBundle.loadString(
      GalleryLayoutStore.bundledGlobalLayoutPath,
    );
    final layouts = decodeGlobalGalleryLayoutDocument(contents);

    expect(
      layouts.keys,
      containsAll(<String>[
        'japan',
        'south-korea',
        'china',
        'philippines',
        'turkey',
        'taiwan',
        'hong-kong',
        'thailand',
        'malaysia',
        'bali',
        'vietnam',
        'sri-lanka',
      ]),
    );
    expect(layouts, hasLength(12));
  });
}
