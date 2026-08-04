import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class GalleryAdminAuth extends ChangeNotifier {
  GalleryAdminAuth({http.Client? client, Uri? baseUri})
    : _client = client ?? http.Client(),
      _baseUri =
          baseUri ??
          Uri.parse(const String.fromEnvironment('NEXT_PUBLIC_INSFORGE_URL'));

  static final GalleryAdminAuth instance = GalleryAdminAuth();

  final http.Client _client;
  final Uri _baseUri;

  String? _accessToken;
  String? _userId;

  String? get accessToken => _accessToken;
  String? get userId => _userId;
  bool get isAuthenticated => _accessToken != null && _userId != null;

  Future<void> signIn({required String email, required String password}) async {
    _requireConfigured();
    if (email.trim().isEmpty || password.isEmpty) {
      throw const GalleryAdminAuthException('Enter your email and password.');
    }

    final response = await _client.post(
      _baseUri.resolve('/api/auth/sessions?client_type=mobile'),
      headers: const <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(<String, String>{
        'method': 'password',
        'email': email.trim(),
        'password': password,
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw GalleryAdminAuthException(
        _safeErrorMessage(response, fallback: 'Sign-in failed.'),
      );
    }

    final Object? decodedSession;
    try {
      decodedSession = jsonDecode(response.body);
    } on FormatException {
      throw const GalleryAdminAuthException(
        'The backend did not return a valid authenticated session.',
      );
    }
    if (decodedSession is! Map<String, dynamic>) {
      throw const GalleryAdminAuthException(
        'The backend did not return a valid authenticated session.',
      );
    }
    final session = decodedSession;
    final token = session['accessToken'] as String?;
    final user = session['user'] as Map<String, dynamic>?;
    final userId = user?['id'] as String?;
    if (token == null || token.isEmpty || userId == null || userId.isEmpty) {
      throw const GalleryAdminAuthException(
        'The backend did not return a valid authenticated session.',
      );
    }

    final membership = await _client.get(
      _baseUri.resolve(
        '/api/database/records/gallery_admins'
        '?select=user_id&user_id=eq.${Uri.encodeQueryComponent(userId)}&limit=1',
      ),
      headers: <String, String>{'Authorization': 'Bearer $token'},
    );
    if (membership.statusCode < 200 || membership.statusCode >= 300) {
      throw GalleryAdminAuthException(
        _safeErrorMessage(
          membership,
          fallback: 'Could not verify gallery administrator access.',
        ),
      );
    }
    final Object? decodedMembership;
    try {
      decodedMembership = jsonDecode(membership.body);
    } on FormatException {
      throw const GalleryAdminAuthException(
        'Could not verify gallery administrator access.',
      );
    }
    if (decodedMembership is! List<dynamic>) {
      throw const GalleryAdminAuthException(
        'Could not verify gallery administrator access.',
      );
    }
    final rows = decodedMembership;
    if (rows.isEmpty) {
      throw const GalleryAdminAuthException(
        'This account is not authorized to edit the gallery.',
      );
    }

    // Access tokens deliberately remain in memory. The admin signs in again
    // after an app restart instead of persisting a refresh token in web or
    // desktop storage.
    _accessToken = token;
    _userId = userId;
    notifyListeners();
  }

  void signOut() {
    if (!isAuthenticated) return;
    _accessToken = null;
    _userId = null;
    notifyListeners();
  }

  @visibleForTesting
  void setSessionForTesting({String? accessToken, String? userId}) {
    _accessToken = accessToken;
    _userId = userId;
    notifyListeners();
  }

  void _requireConfigured() {
    if (!_baseUri.hasScheme) {
      throw const GalleryAdminAuthException(
        'The EverAfter database connection is not configured.',
      );
    }
  }
}

String _safeErrorMessage(http.Response response, {required String fallback}) {
  try {
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      return '$fallback (${response.statusCode})';
    }
    final message =
        decoded['message'] as String? ?? decoded['error'] as String?;
    if (message != null && message.isNotEmpty && message.length <= 240) {
      return message;
    }
  } on FormatException {
    // Avoid surfacing arbitrary HTML or verbose gateway output.
  }
  return '$fallback (${response.statusCode})';
}

class GalleryAdminAuthException implements Exception {
  const GalleryAdminAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
