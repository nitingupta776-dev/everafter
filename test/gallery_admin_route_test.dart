import 'package:everafter/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
