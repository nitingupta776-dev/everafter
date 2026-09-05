import 'package:everafter/data/trip_catalog_store.dart';
import 'package:everafter/widgets/trip_gallery.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await TripCatalogStore.instance.load();
  });

  test('setVisited(false) removes a trip from the visible list only', () {
    final store = TripCatalogStore.instance;
    final before = store.trips.map((t) => t.slug).toList();
    expect(before, contains('japan'));

    store.setVisited('japan', false);

    final afterVisible = store.trips.map((t) => t.slug).toList();
    final afterAll = store.allTrips.map((t) => t.slug).toList();
    expect(afterVisible, isNot(contains('japan')));
    expect(afterAll, contains('japan'), reason: 'still routable, just hidden');

    // Re-visit so the JSON on disk / SharedPreferences override isn't left
    // mutated after this diagnostic run.
    store.setVisited('japan', true);
  });

  testWidgets(
    'TripGallery drops a hidden trip live, in the same running instance, '
    'with no reload',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 1400,
            height: 800,
            child: TripGallery(
              controller: ScrollController(),
              onTripTap: (trip, heroTag) {},
              autoScrollEnabled: false,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('JAPAN'), findsWidgets);

      TripCatalogStore.instance.setVisited('japan', false);
      await tester.pump();

      expect(
        find.text('JAPAN'),
        findsNothing,
        reason:
            'toggling visited=false should immediately drop the card from '
            'the gallery grid without any reload, since TripGallery listens '
            'to the same TripCatalogStore singleton',
      );

      TripCatalogStore.instance.setVisited('japan', true);
    },
  );
}
