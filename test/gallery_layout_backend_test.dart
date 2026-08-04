import 'dart:convert';

import 'package:everafter/data/gallery_layout_backend.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('loads layouts keyed by trip slug', () async {
    final backend = GalleryLayoutBackend(
      baseUri: Uri.parse('https://example.insforge.app'),
      anonKey: 'anon-test',
      client: MockClient((request) async {
        expect(request.method, 'GET');
        expect(
          request.url.path,
          '/api/database/records/gallery_layouts_public_safe',
        );
        expect(request.headers['authorization'], 'Bearer anon-test');
        return http.Response(
          jsonEncode(<Map<String, dynamic>>[
            <String, dynamic>{
              'trip_slug': 'japan',
              'layout': <String, dynamic>{
                'stripWidth': 4200,
                'trinkets': <dynamic>[],
              },
            },
          ]),
          200,
        );
      }),
    );

    final layouts = await backend.loadLayouts();

    expect(layouts.keys, <String>['japan']);
    expect(layouts['japan']!['stripWidth'], 4200);
  });

  test('uploads embedded trinkets before saving the layout row', () async {
    var uploaded = false;
    final backend = GalleryLayoutBackend(
      baseUri: Uri.parse('https://example.insforge.app'),
      anonKey: 'anon-test',
      accessTokenProvider: () => 'admin-test',
      client: MockClient((request) async {
        expect(request.headers['authorization'], 'Bearer admin-test');
        if (request.url.path == '/functions/upload-gallery-trinket') {
          uploaded = true;
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['tripSlug'], 'japan');
          expect(body['trinketId'], 'custom-trinket-1');
          expect(body['base64'], isNotEmpty);
          return http.Response(
            jsonEncode(<String, dynamic>{
              'key': 'trinkets/japan/custom-trinket-1.png',
              'url': '/stored/custom-trinket-1.png',
            }),
            200,
          );
        }

        expect(uploaded, isTrue);
        expect(request.url.path, '/api/database/records/gallery_layouts');
        final rows = jsonDecode(request.body) as List<dynamic>;
        final layout =
            (rows.single as Map<String, dynamic>)['layout']
                as Map<String, dynamic>;
        final trinket =
            (layout['trinkets'] as List<dynamic>).single
                as Map<String, dynamic>;
        expect(trinket['assetName'], isNot(startsWith('data:image/')));
        expect(trinket['storageKey'], 'trinkets/japan/custom-trinket-1.png');
        return http.Response('[]', 201);
      }),
    );

    final saved = await backend.saveLayouts(<String, Map<String, dynamic>>{
      'japan': <String, dynamic>{
        'stripWidth': 4200,
        'travelStartDate': null,
        'travelEndDate': null,
        'trinkets': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'custom-trinket-1',
            'assetName':
                'data:image/png;base64,'
                'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwC'
                'AAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
          },
        ],
      },
    });

    final trinket =
        (saved['japan']!['trinkets'] as List<dynamic>).single
            as Map<String, dynamic>;
    expect(
      trinket['assetName'],
      'https://example.insforge.app/stored/custom-trinket-1.png',
    );
  });

  test('refuses writes without an authenticated administrator token', () async {
    final backend = GalleryLayoutBackend(
      baseUri: Uri.parse('https://example.insforge.app'),
      anonKey: 'anon-test',
      accessTokenProvider: () => null,
      client: MockClient((request) async {
        fail('An unauthorized save must not make a network request.');
      }),
    );

    await expectLater(
      backend.saveLayouts(<String, Map<String, dynamic>>{
        'japan': <String, dynamic>{'stripWidth': 4200, 'trinkets': <dynamic>[]},
      }),
      throwsA(
        isA<GalleryLayoutBackendException>().having(
          (error) => error.message,
          'message',
          contains('sign-in is required'),
        ),
      ),
    );
  });
}
