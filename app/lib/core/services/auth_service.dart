// AarogyaMP — Auth Service (M2 — Person C)
// Wraps real HTTP login/register calls. All token persistence via SharedPreferences.
// Used only when USE_MOCKS=false. Mock path stays in AuthNotifier.
//
// JWT payload structure (set by Person A's auth.py):
//   { "sub": "<user_id>", "role": "patient"|"doctor", "exp": ..., "iat": ..., "type": "access" }
//
// Login response (AuthResponse schema — FROZEN §11):
//   { "access_token": str, "refresh_token": str, "role": str }
//   NOTE: name is NOT returned in login — stored locally during register.
//
// M3 TODO (Person A): add GET /api/auth/me to return name + verification_status,
//   so name is available on fresh login without prior registration in this session.

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/endpoints.dart';
import '../providers/auth_provider.dart';

class AuthService {
  final Dio _dio;
  final SharedPreferences _prefs;

  // SharedPreferences keys
  static const _kAccessToken = 'auth_access_token';
  static const _kRefreshToken = 'auth_refresh_token';
  static const _kRole = 'auth_role';
  static const _kName = 'auth_name';
  static const _kUserId = 'auth_user_id';
  static const _kLastConsultationId = 'auth_last_consultation_id';
  static const _kLastConsultationDoctorName = 'auth_last_consultation_doctor_name';

  AuthService(this._dio, this._prefs);

  /// Read stored access token (used by AuthInterceptor + WebSocket).
  String? get storedToken => _prefs.getString(_kAccessToken);

  /// Decode the JWT payload section without verifying the signature.
  /// Only used to extract non-sensitive claims (sub, role, exp) on the client side.
  Map<String, dynamic> _decodeJwtPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return {};
      // Base64url padding
      var payload = parts[1];
      payload += '=' * ((4 - payload.length % 4) % 4);
      final decoded = utf8.decode(base64Url.decode(payload));
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  /// POST /api/auth/login — phone + password → JWT tokens.
  Future<AuthState> login({
    required String phone,
    required String password,
  }) async {
    final response = await _dio.post(
      Endpoints.login,
      data: {'phone': phone, 'password': password},
    );
    final data = response.data as Map<String, dynamic>;
    final accessToken = data['access_token'] as String;
    final refreshToken = data['refresh_token'] as String;
    final role = data['role'] as String;

    final claims = _decodeJwtPayload(accessToken);
    final userId = claims['sub'] as String? ?? '';

    await _prefs.setString(_kAccessToken, accessToken);
    await _prefs.setString(_kRefreshToken, refreshToken);
    await _prefs.setString(_kRole, role);
    await _prefs.setString(_kUserId, userId);
    // name may already be stored from a previous registration session; preserve it.

    return AuthState(
      isAuthenticated: true,
      role: role == 'doctor' ? UserRole.doctor : UserRole.patient,
      userId: userId,
      name: _prefs.getString(_kName), // null on very first login — acceptable for M2
      accessToken: accessToken,
      // M2: isDoctorVerified=true for live mode. Server enforces access on endpoints.
      // The "pending verification" screen is shown only immediately after registration.
      // M3: replace with real verification_status from a GET /api/auth/me endpoint.
      isDoctorVerified: true,
    );
  }

  /// POST /api/auth/register — full registration payload.
  Future<AuthState> register({
    required String name,
    required String phone,
    required String password,
    required UserRole role,
    String? specialty,    // required for doctors (server validates)
    String? qualification,
  }) async {
    final response = await _dio.post(
      Endpoints.register,
      data: {
        'name': name,
        'phone': phone,
        'password': password,
        'role': role == UserRole.doctor ? 'doctor' : 'patient',
        if (specialty != null) 'specialty': specialty,
        if (qualification != null && qualification.isNotEmpty)
          'qualification': qualification,
      },
    );
    final data = response.data as Map<String, dynamic>;
    final accessToken = data['access_token'] as String;
    final refreshToken = data['refresh_token'] as String;

    final claims = _decodeJwtPayload(accessToken);
    final userId = claims['sub'] as String? ?? '';

    await _prefs.setString(_kAccessToken, accessToken);
    await _prefs.setString(_kRefreshToken, refreshToken);
    await _prefs.setString(_kRole, role == UserRole.doctor ? 'doctor' : 'patient');
    await _prefs.setString(_kName, name);
    await _prefs.setString(_kUserId, userId);

    return AuthState(
      isAuthenticated: true,
      role: role,
      userId: userId,
      name: name,
      accessToken: accessToken,
      // Newly registered doctors are always "pending" — show pending screen.
      isDoctorVerified: role == UserRole.patient,
    );
  }

  /// Attempt to restore a previous session from stored tokens.
  /// Returns null if no token stored or token is expired.
  Future<AuthState?> tryRestoreSession() async {
    final token = _prefs.getString(_kAccessToken);
    if (token == null || token.isEmpty) return null;

    // Check expiry from JWT claims (no network call)
    final claims = _decodeJwtPayload(token);
    final exp = claims['exp'];
    if (exp != null) {
      final expiry = DateTime.fromMillisecondsSinceEpoch((exp as int) * 1000);
      if (expiry.isBefore(DateTime.now())) {
        await clearSession();
        return null;
      }
    }

    final roleStr = _prefs.getString(_kRole) ?? 'patient';
    final userId = _prefs.getString(_kUserId) ?? '';

    return AuthState(
      isAuthenticated: true,
      role: roleStr == 'doctor' ? UserRole.doctor : UserRole.patient,
      userId: userId,
      name: _prefs.getString(_kName),
      accessToken: token,
      isDoctorVerified: true, // M2: assume verified on session restore
      lastConsultationId: _prefs.getString(_kLastConsultationId),
      lastConsultationDoctorName: _prefs.getString(_kLastConsultationDoctorName),
    );
  }

  /// Persist last active consultation details.
  Future<void> saveLastConsultation(String consultationId, String doctorName) async {
    await _prefs.setString(_kLastConsultationId, consultationId);
    await _prefs.setString(_kLastConsultationDoctorName, doctorName);
  }

  /// Clear all stored auth data (logout).
  Future<void> clearSession() async {
    await Future.wait([
      _prefs.remove(_kAccessToken),
      _prefs.remove(_kRefreshToken),
      _prefs.remove(_kRole),
      _prefs.remove(_kName),
      _prefs.remove(_kUserId),
      _prefs.remove(_kLastConsultationId),
      _prefs.remove(_kLastConsultationDoctorName),
    ]);
  }
}

/// Provider — requires sharedPreferencesProvider override in ProviderScope.
final authServiceProvider = Provider<AuthService>((ref) {
  throw UnimplementedError(
    'authServiceProvider requires dioProvider and sharedPreferencesProvider',
  );
});
