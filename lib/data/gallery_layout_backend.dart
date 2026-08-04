import 'dart:convert';
import 'dart:typed_data';

import 'package:everafter/services/gallery_admin_auth.dart';
import 'package:http/http.dart' as http;

class GalleryLayoutBackend {
  GalleryLayoutBackend({
    http.Client? client,
    Uri? baseUri,
    String? anonKey,
    String? Function()? accessTokenProvider,
  }) : _client = client ?? http.Client(),
       _baseUri =
           baseUri ??
           Uri.parse(const String.fromEnvironment('NEXT_PUBLIC_INSFORGE_URL')),
       _anonKey =
           anonKey ??
           const String.fromEnvironment('NEXT_PUBLIC_INSFORGE_ANON_KEY'),
       _accessTokenProvider =
           accessTokenProvider ?? (() => GalleryAdminAuth.instance.accessToken);

  static const String _bucket = 'gallery-trinkets';

  final http.Client _client;
  final Uri _baseUri;
  final String _anonKey;
  final String? Function() _accessTokenProvider;

  Map<String, String> get _readHeaders => <String, String>{
    'Authorization': 'Bearer ${_accessTokenProvider() ?? _anonKey}',
    'Content-Type': 'application/json',
  };

  Map<String, String> get _writeHeaders {
    final token = _requireAdminToken();
    return <String, String>{
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<Map<String, Map<String, dynamic>>> loadLayouts() async {
    _requireConfigured();
    final table = _accessTokenProvider() == null
        ? 'gallery_layouts_public_safe'
        : 'gallery_layouts';
    final response = await _client.get(
      _baseUri.resolve(
        '/api/database/records/$table'
        '?select=trip_slug,layout&order=trip_slug.asc',
      ),
      headers: _readHeaders,
    );
    _requireSuccess(response, 'load gallery layouts');
    final rows = jsonDecode(response.body) as List<dynamic>;
    return <String, Map<String, dynamic>>{
      for (final row in rows.cast<Map<String, dynamic>>())
        row['trip_slug'] as String: Map<String, dynamic>.from(
          row['layout'] as Map,
        ),
    };
  }

  Future<Map<String, Map<String, dynamic>>> saveLayouts(
    Map<String, Map<String, dynamic>> layouts,
  ) async {
    _requireConfigured();
    final uploaded = <String, Map<String, dynamic>>{};
    for (final entry in layouts.entries) {
      uploaded[entry.key] = await _uploadEmbeddedTrinkets(
        entry.key,
        entry.value,
      );
    }

    final rows = <Map<String, dynamic>>[
      for (final entry in uploaded.entries)
        <String, dynamic>{
          'trip_slug': entry.key,
          'layout': entry.value,
          'strip_width': entry.value['stripWidth'],
          'travel_start_date': entry.value['travelStartDate'],
          'travel_end_date': entry.value['travelEndDate'],
          'revision': DateTime.now().microsecondsSinceEpoch,
        },
    ];
    if (rows.isEmpty) return uploaded;

    final response = await _client.post(
      _baseUri.resolve('/api/database/records/gallery_layouts'),
      headers: <String, String>{
        ..._writeHeaders,
        'Prefer': 'resolution=merge-duplicates,return=representation',
      },
      body: jsonEncode(rows),
    );
    _requireSuccess(response, 'save gallery layouts');
    return uploaded;
  }

  Future<Map<String, dynamic>> _uploadEmbeddedTrinkets(
    String tripSlug,
    Map<String, dynamic> layout,
  ) async {
    final result = Map<String, dynamic>.from(layout);
    final trinkets = (layout['trinkets'] as List<dynamic>? ?? <dynamic>[])
        .cast<Map<String, dynamic>>();
    result['trinkets'] = <Map<String, dynamic>>[
      for (final trinket in trinkets)
        await _uploadEmbeddedTrinket(tripSlug, trinket),
    ];
    return result;
  }

  Future<Map<String, dynamic>> _uploadEmbeddedTrinket(
    String tripSlug,
    Map<String, dynamic> trinket,
  ) async {
    final source = trinket['assetName'] as String? ?? '';
    if (!source.startsWith('data:image/')) {
      return Map<String, dynamic>.from(trinket);
    }

    final data = _parseDataImage(source);
    final id = (trinket['id'] as String? ?? 'trinket').replaceAll(
      RegExp(r'[^a-zA-Z0-9-]'),
      '-',
    );
    final uploaded = await _uploadObject(
      tripSlug: tripSlug,
      trinketId: id,
      bytes: data.bytes,
      mimeType: data.mimeType,
    );
    return <String, dynamic>{
      ...trinket,
      'assetName': uploaded.url,
      'storageKey': uploaded.key,
    };
  }

  Future<_UploadedObject> _uploadObject({
    required String tripSlug,
    required String trinketId,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final response = await _client.post(
      _baseUri.resolve('/functions/upload-gallery-trinket'),
      headers: _writeHeaders,
      body: jsonEncode(<String, dynamic>{
        'tripSlug': tripSlug,
        'trinketId': trinketId,
        'base64': base64Encode(bytes),
        'mimeType': mimeType,
      }),
    );
    _requireSuccess(response, 'upload trinket image');
    final uploadResult = jsonDecode(response.body) as Map<String, dynamic>;
    final storedKey = uploadResult['key'] as String?;
    if (storedKey == null || storedKey.isEmpty) {
      throw const GalleryLayoutBackendException(
        'The storage service returned an invalid object key.',
      );
    }
    final rawUrl =
        uploadResult['url'] as String? ??
        '/api/storage/buckets/$_bucket/objects/$storedKey';
    return _UploadedObject(key: storedKey, url: _resolveUrl(rawUrl).toString());
  }

  Uri _resolveUrl(String value) {
    final uri = Uri.parse(value);
    return uri.hasScheme ? uri : _baseUri.resolve(value);
  }

  void _requireSuccess(http.Response response, String operation) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw GalleryLayoutBackendException(
      'Could not $operation (${response.statusCode}): ${response.body}',
    );
  }

  void _requireConfigured() {
    if (!_baseUri.hasScheme || _anonKey.isEmpty) {
      throw const GalleryLayoutBackendException(
        'The EverAfter database connection is not configured.',
      );
    }
  }

  String _requireAdminToken() {
    final token = _accessTokenProvider();
    if (token == null || token.isEmpty) {
      throw const GalleryLayoutBackendException(
        'Gallery administrator sign-in is required.',
      );
    }
    return token;
  }
}

class GalleryLayoutBackendException implements Exception {
  const GalleryLayoutBackendException(this.message);

  final String message;

  @override
  String toString() => message;
}

class _UploadedObject {
  const _UploadedObject({required this.key, required this.url});

  final String key;
  final String url;
}

class _DataImage {
  const _DataImage({required this.bytes, required this.mimeType});

  final Uint8List bytes;
  final String mimeType;
}

_DataImage _parseDataImage(String source) {
  final separator = source.indexOf(',');
  if (separator < 0) {
    throw const GalleryLayoutBackendException('The trinket image is invalid.');
  }
  final header = source.substring(5, separator);
  final mimeType = header.split(';').first;
  if (mimeType != 'image/jpeg' &&
      mimeType != 'image/webp' &&
      mimeType != 'image/png') {
    throw const GalleryLayoutBackendException(
      'Only PNG, JPEG, and WebP trinket images are supported.',
    );
  }
  late final Uint8List bytes;
  try {
    bytes = base64Decode(source.substring(separator + 1));
  } on FormatException {
    throw const GalleryLayoutBackendException('The trinket image is invalid.');
  }
  if (bytes.length > 2 * 1024 * 1024) {
    throw const GalleryLayoutBackendException(
      'Trinket images must be 2 MB or smaller.',
    );
  }
  return _DataImage(bytes: bytes, mimeType: mimeType);
}
