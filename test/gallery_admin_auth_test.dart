import 'dart:convert';

import 'package:everafter/routing/app_router.dart';
import 'package:everafter/services/gallery_admin_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('signs in only after confirming explicit gallery membership', () async {
    final auth = GalleryAdminAuth(
      baseUri: Uri.parse('https://example.insforge.app'),
      client: MockClient((request) async {
        if (request.url.path == '/api/auth/sessions') {
          expect(request.url.queryParameters['client_type'], 'mobile');
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['email'], 'owner@example.com');
          expect(body['password'], 'correct-password');
          return http.Response(
            jsonEncode(<String, dynamic>{
              'accessToken': 'owner-access-token',
              'refreshToken': 'ignored-refresh-token',
              'user': <String, dynamic>{'id': 'owner-user-id'},
            }),
            200,
          );
        }

        expect(request.url.path, '/api/database/records/gallery_admins');
        expect(request.headers['authorization'], 'Bearer owner-access-token');
        return http.Response(
          jsonEncode(<Map<String, String>>[
            <String, String>{'user_id': 'owner-user-id'},
          ]),
          200,
        );
      }),
    );

    await auth.signIn(email: 'owner@example.com', password: 'correct-password');

    expect(auth.isAuthenticated, isTrue);
    expect(auth.userId, 'owner-user-id');
    expect(auth.accessToken, 'owner-access-token');
    auth.signOut();
    expect(auth.isAuthenticated, isFalse);
  });

  test('rejects a valid account without gallery membership', () async {
    final auth = GalleryAdminAuth(
      baseUri: Uri.parse('https://example.insforge.app'),
      client: MockClient((request) async {
        if (request.url.path == '/api/auth/sessions') {
          return http.Response(
            jsonEncode(<String, dynamic>{
              'accessToken': 'ordinary-access-token',
              'user': <String, dynamic>{'id': 'ordinary-user-id'},
            }),
            200,
          );
        }
        return http.Response('[]', 200);
      }),
    );

    await expectLater(
      auth.signIn(email: 'user@example.com', password: 'correct-password'),
      throwsA(
        isA<GalleryAdminAuthException>().having(
          (error) => error.message,
          'message',
          contains('not authorized'),
        ),
      ),
    );
    expect(auth.isAuthenticated, isFalse);
  });

  testWidgets('router sends unauthenticated admin visits to sign in', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    GalleryAdminAuth.instance.setSessionForTesting();
    final container = ProviderContainer();
    final router = container.read(appRouterProvider);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      container.dispose();
      GalleryAdminAuth.instance.setSessionForTesting();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    router.go('/admin/gallery');
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('gallery-admin-sign-in-screen')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('gallery-admin-screen')), findsNothing);
  });
}
