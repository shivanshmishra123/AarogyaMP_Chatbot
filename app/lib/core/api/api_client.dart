// AarogyaMP — Dio HTTP client with auth interceptor (M2 — Person C)
//
// API_BASE_URL and WS_BASE_URL injected via --dart-define:
//   flutter run --dart-define=API_BASE_URL=http://192.168.x.x:8000
//              --dart-define=WS_BASE_URL=ws://192.168.x.x:8000
//
// Two Dio instances:
//   dioProvider       — authenticated (has AuthInterceptor), used everywhere
//   buildBareDio()    — unauthenticated, used ONLY by AuthService itself to
//                       avoid a chicken-and-egg: can't attach a token interceptor
//                       to the client that IS responsible for getting the token.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/shared_preferences_provider.dart';

const String _apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8000',
);

const String _wsBaseUrl = String.fromEnvironment(
  'WS_BASE_URL',
  defaultValue: 'ws://localhost:8000',
);

// Public URL constants (used by ChatService for WebSocket)
const String kApiBaseUrl = _apiBaseUrl;
const String kWsBaseUrl = _wsBaseUrl;

// ── AuthInterceptor ───────────────────────────────────────────

class AuthInterceptor extends Interceptor {
  final SharedPreferences _prefs;
  static const _kAccessToken = 'auth_access_token';

  AuthInterceptor(this._prefs);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _prefs.getString(_kAccessToken);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Token expired or invalid: clear stored credentials.
      // On next app start tryRestoreSession() will find no token → login screen.
      _prefs.remove(_kAccessToken);
      _prefs.remove('auth_refresh_token');
      _prefs.remove('auth_role');
      _prefs.remove('auth_user_id');
      // Let the error propagate — callers handle DioException 401 with a
      // "session expired" message (see individual service error handling).
    }
    handler.next(err);
  }
}

// ── Bare Dio (no auth) — used by AuthService only ─────────────

/// Returns a plain Dio instance with no auth interceptor.
/// Only AuthService should call this.
Dio buildBareDio() {
  return Dio(
    BaseOptions(
      baseUrl: _apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ),
  );
}

// ── Authenticated Dio (all other services) ────────────────────

Dio _buildAuthenticatedDio(SharedPreferences prefs) {
  final dio = Dio(
    BaseOptions(
      baseUrl: _apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ),
  );
  dio.interceptors.add(AuthInterceptor(prefs));
  return dio;
}

/// Authenticated Dio provider. Requires sharedPreferencesProvider override.
/// When USE_MOCKS=true this provider is not used (services call mock path directly).
final dioProvider = Provider<Dio>((ref) {
  const useMocks = bool.fromEnvironment('USE_MOCKS', defaultValue: true);
  if (useMocks) {
    // In mock mode return a bare Dio — it will never actually be called.
    return buildBareDio();
  }
  final prefs = ref.watch(sharedPreferencesProvider);
  return _buildAuthenticatedDio(prefs);
});
