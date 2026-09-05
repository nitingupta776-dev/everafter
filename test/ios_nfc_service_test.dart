import 'dart:async';

import 'package:everafter/app.dart';
import 'package:everafter/data/trip_catalog_store.dart';
import 'package:everafter/services/nfc_configuration.dart';
import 'package:everafter/services/ios_nfc_service.dart';
import 'package:everafter/services/nfc_service.dart';
import 'package:everafter/services/nfc_service_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _japanUid = '04:00:00:00:00:04';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await TripCatalogStore.instance.load();
  });

  test(
    'iOS NFC service normalizes native scan into the shared UID stream',
    () async {
      const channel = MethodChannel('everafter.test/nfc');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            expect(call.method, 'scanMagnet');
            return _japanUid;
          });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      });

      final service = IosNfcService(channel: channel);
      addTearDown(service.dispose);
      final detectedUid = service.detectedUids.first;

      expect(await service.startScan(), _japanUid);
      expect(await detectedUid, _japanUid);
    },
  );

  testWidgets('iPhone Scan Magnet action opens the linked trip', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final service = _FakeIosNfcService(_japanUid);
    addTearDown(service.dispose);
    try {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [nfcServiceProvider.overrideWithValue(service)],
          child: const EverAfterApp(showSplash: false),
        ),
      );
      await tester.pump();

      expect(find.byKey(const ValueKey('scan-magnet')), findsOneWidget);
      expect(find.byKey(const ValueKey('close-everafter')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('scan-magnet')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1200));

      expect(find.byKey(const ValueKey('nfc-magnet-reveal')), findsOneWidget);
      expect(find.text('JAPAN'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('start-trip-experience')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('start-trip-experience')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));

      expect(find.byKey(const ValueKey('trip-memory-gallery')), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  }, skip: !nativeIosNfcEnabled);

  testWidgets('Personal Team build explains NFC Shortcut setup', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await tester.pumpWidget(
        const ProviderScope(child: EverAfterApp(showSplash: false)),
      );
      await tester.pump();

      expect(find.byKey(const ValueKey('nfc-shortcuts-setup')), findsOneWidget);
      expect(find.byKey(const ValueKey('scan-magnet')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('nfc-shortcuts-setup')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Connect each magnet to its trip'), findsOneWidget);
      expect(find.text('everafter:///nfc/japan'), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  }, skip: nativeIosNfcEnabled);

  testWidgets('an iPhone trip deep link opens its magnet reveal', (
    tester,
  ) async {
    tester.binding.platformDispatcher.defaultRouteNameTestValue = '/nfc/japan';
    try {
      await tester.pumpWidget(
        const ProviderScope(child: EverAfterApp(showSplash: false)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1200));

      expect(find.byKey(const ValueKey('nfc-magnet-reveal')), findsOneWidget);
      expect(find.text('JAPAN'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('start-trip-experience')),
        findsOneWidget,
      );
    } finally {
      tester.binding.platformDispatcher.defaultRouteNameTestValue = '/';
    }
  });
}

class _FakeIosNfcService implements NfcService {
  _FakeIosNfcService(this.uid);

  final String uid;
  final _controller = StreamController<String>.broadcast(sync: true);

  @override
  Stream<String> get detectedUids => _controller.stream;

  @override
  Future<String?> startScan() async {
    _controller.add(uid);
    return uid;
  }

  @override
  Future<void> scanDemo(String uid) async => _controller.add(uid);

  @override
  void dispose() => _controller.close();
}
