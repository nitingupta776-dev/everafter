import 'package:everafter/data/trip_catalog_store.dart';
import 'package:everafter/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await TripCatalogStore.instance.load();
  });

  testWidgets('local gallery admin opens without a sign-in redirect', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    final container = ProviderContainer();
    final router = container.read(appRouterProvider);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      container.dispose();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    router.go('/admin/gallery');
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('gallery-admin-screen')), findsOneWidget);
  });
}
