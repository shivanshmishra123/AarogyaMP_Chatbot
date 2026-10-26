// AarogyaMP — Auth state provider (M2 — Person C)
// USE_MOCKS=true  → mock in-memory auth (no network)
// USE_MOCKS=false → real JWT via AuthService + SharedPreferences persistence
//
// AuthState.accessToken is needed by:
//   - AuthInterceptor (Dio HTTP header)
//   - WebSocket chat (?token=<access_token> query param)

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';
import 'shared_preferences_provider.dart';
import '../services/auth_service.dart';

enum UserRole { patient, doctor }

class AuthState {
  final bool isAuthenticated;
  final UserRole? role;
  final String? userId;
  final String? name;
  final String? phone;
  final String? accessToken;         // JWT access token — needed for WS auth
  final bool isDoctorVerified;       // for routing; see AuthService notes on M3 TODO
  final String? lastSymptomReportId; // latest assessment / symptom report id
  final String? lastConsultationId;  // latest active consultation id
  final String? lastConsultationDoctorName;
  final List<Map<String, dynamic>> consultations;

  const AuthState({
    this.isAuthenticated = false,
    this.role,
    this.userId,
    this.name,
    this.phone,
    this.accessToken,
    this.isDoctorVerified = false,
    this.lastSymptomReportId,
    this.lastConsultationId,
    this.lastConsultationDoctorName,
    this.consultations = const [],
  });

  AuthState copyWith({
    bool? isAuthenticated,
    UserRole? role,
    String? userId,
    String? name,
    String? phone,
    String? accessToken,
    bool? isDoctorVerified,
    String? lastSymptomReportId,
    String? lastConsultationId,
    String? lastConsultationDoctorName,
    List<Map<String, dynamic>>? consultations,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      role: role ?? this.role,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      accessToken: accessToken ?? this.accessToken,
      isDoctorVerified: isDoctorVerified ?? this.isDoctorVerified,
      lastSymptomReportId: lastSymptomReportId ?? this.lastSymptomReportId,
      lastConsultationId: lastConsultationId ?? this.lastConsultationId,
      lastConsultationDoctorName: lastConsultationDoctorName ?? this.lastConsultationDoctorName,
      consultations: consultations ?? this.consultations,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final SharedPreferences? _prefs; // null in mock mode
  AuthService? _authService;       // null in mock mode

  static const _useMocks = bool.fromEnvironment('USE_MOCKS', defaultValue: true);

  AuthNotifier(this._prefs) : super(const AuthState()) {
    if (_prefs != null) {
      if (!_useMocks) {
        _tryRestoreSession();
      }
      _loadStoredConsultations();
    }
  }

  void _loadStoredConsultations() {
    _initService();
    final map = _authService?.getDoctorConsultations() ?? {};
    if (map.isNotEmpty) {
      final list = <Map<String, dynamic>>[];
      for (final v in map.values) {
        if (v is Map) list.add(Map<String, dynamic>.from(v));
      }
      list.sort((a, b) {
        final aTime = DateTime.tryParse(a['updatedAt']?.toString() ?? '') ?? DateTime(2000);
        final bTime = DateTime.tryParse(b['updatedAt']?.toString() ?? '') ?? DateTime(2000);
        return bTime.compareTo(aTime);
      });
      state = state.copyWith(consultations: list);
    }
  }

  void _initService() {
    // Lazy init — avoids circular dep at construction time.
    // Dio is a const provider and doesn't need AuthService.
    if (_authService == null && _prefs != null) {
      // Build a bare Dio (no auth interceptor yet) just for auth calls.
      // The regular dioProvider has the interceptor; this avoids chicken-and-egg.
      final dio = buildBareDio();
      _authService = AuthService(dio, _prefs!);
    }
  }

  /// On app start: restore session from SharedPreferences without a network call.
  Future<void> _tryRestoreSession() async {
    _initService();
    final restored = await _authService!.tryRestoreSession();
    if (restored != null) {
      state = restored;
    }
  }

  // ── MOCK PATH ─────────────────────────────────────────────────
  // Used when USE_MOCKS=true (development / CI / design review)

  Future<void> _mockLogin({required UserRole role}) async {
    await Future.delayed(const Duration(milliseconds: 600));
    state = AuthState(
      isAuthenticated: true,
      role: role,
      userId: 'mock-user-001',
      name: role == UserRole.doctor ? 'Dr. Sunita Verma' : 'रामेश्वर जी',
      phone: '+91 98765 43210',
      accessToken: 'mock-token-not-real',
      isDoctorVerified: role == UserRole.doctor,
    );
  }

  Future<void> _mockRegister({
    required String name,
    required UserRole role,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    state = AuthState(
      isAuthenticated: true,
      role: role,
      userId: 'mock-user-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      phone: '+91 98765 00000',
      accessToken: 'mock-token-not-real',
      isDoctorVerified: false, // doctors always start unverified
    );
  }

  // ── PUBLIC API ────────────────────────────────────────────────

  /// Login with phone + password. Role determined by server response.
  Future<void> login({
    required String phone,
    required String password,
    UserRole? hintRole, // ignored in live mode; used only in mock for role selection
  }) async {
    if (_useMocks) {
      await _mockLogin(role: hintRole ?? UserRole.patient);
      return;
    }
    _initService();
    final newState = await _authService!.login(phone: phone, password: password);
    state = newState;
  }

  /// Instant guest session for quick evaluation without credentials
  void loginAsGuest() {
    state = const AuthState(
      isAuthenticated: true,
      role: UserRole.patient,
      userId: 'guest_patient',
      name: 'अतिथि नागरिक (Guest User)',
      phone: '+91 98765 00000',
      accessToken: 'guest_token',
      isDoctorVerified: false,
    );
  }

  /// Register new account. Role + name known at registration time.
  Future<void> register({
    required String name,
    required String phone,
    required String password,
    required UserRole role,
    String? specialty,
    String? qualification,
  }) async {
    if (_useMocks) {
      await _mockRegister(name: name, role: role);
      return;
    }
    _initService();
    final newState = await _authService!.register(
      name: name,
      phone: phone,
      password: password,
      role: role,
      specialty: specialty,
      qualification: qualification,
    );
    state = newState;
  }

  void setLastSymptomReportId(String? id) {
    state = state.copyWith(lastSymptomReportId: id);
  }

  void setLastConsultation({
    required String consultationId,
    required String doctorName,
  }) {
    state = state.copyWith(
      lastConsultationId: consultationId,
      lastConsultationDoctorName: doctorName,
    );
    if (_prefs != null) {
      _initService();
      _authService?.saveLastConsultation(consultationId, doctorName);
    }
  }

  /// Check if an active consultation already exists with this doctor.
  String? getConsultationIdForDoctor(String doctorId) {
    if (_prefs != null) {
      _initService();
      final id = _authService?.getConsultationIdForDoctor(doctorId);
      if (id != null && id.isNotEmpty) return id;
    }
    return _useMocks ? 'mock-consult-$doctorId' : null;
  }

  /// Save consultation for a specific doctor so future chats reuse the existing thread.
  void saveDoctorConsultation({
    required String doctorId,
    required String consultationId,
    required String doctorName,
    String? specialty,
  }) {
    final entry = {
      'consultationId': consultationId,
      'doctorName': doctorName,
      'doctorId': doctorId,
      'specialty': specialty,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    final currentList = List<Map<String, dynamic>>.from(state.consultations);
    currentList.removeWhere(
      (c) => c['doctorId'] == doctorId || c['consultationId'] == consultationId,
    );
    currentList.insert(0, entry);

    state = state.copyWith(
      lastConsultationId: consultationId,
      lastConsultationDoctorName: doctorName,
      consultations: currentList,
    );

    if (_prefs != null) {
      _initService();
      _authService?.saveDoctorConsultation(
        doctorId: doctorId,
        consultationId: consultationId,
        doctorName: doctorName,
        specialty: specialty,
      );
    }
  }

  /// List all past consultations sorted by most recent.
  List<Map<String, dynamic>> getConsultationHistory() {
    if (state.consultations.isNotEmpty) {
      return state.consultations;
    }
    if (_prefs != null) {
      _initService();
      final map = _authService?.getDoctorConsultations() ?? {};
      if (map.isNotEmpty) {
        final list = <Map<String, dynamic>>[];
        for (final v in map.values) {
          if (v is Map) {
            list.add(Map<String, dynamic>.from(v));
          }
        }
        list.sort((a, b) {
          final aTime = DateTime.tryParse(a['updatedAt']?.toString() ?? '') ?? DateTime(2000);
          final bTime = DateTime.tryParse(b['updatedAt']?.toString() ?? '') ?? DateTime(2000);
          return bTime.compareTo(aTime);
        });
        return list;
      }
    }
    return [];
  }

  Future<void> logout() async {
    if (_prefs != null) {
      _initService();
      await _authService!.clearSession();
    }
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  SharedPreferences? prefs;
  try {
    prefs = ref.watch(sharedPreferencesProvider);
  } catch (_) {}
  return AuthNotifier(prefs);
});
