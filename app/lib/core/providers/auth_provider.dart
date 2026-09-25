// AarogyaMP — Auth state provider (M1 — Person C)
// Mock auth: stores role in memory. Real JWT wired at CP1.

import 'package:flutter_riverpod/flutter_riverpod.dart';

enum UserRole { patient, doctor }

class AuthState {
  final bool isAuthenticated;
  final UserRole? role;
  final String? userId;
  final String? name;
  final bool isDoctorVerified; // only relevant when role == doctor

  const AuthState({
    this.isAuthenticated = false,
    this.role,
    this.userId,
    this.name,
    this.isDoctorVerified = false,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    UserRole? role,
    String? userId,
    String? name,
    bool? isDoctorVerified,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      role: role ?? this.role,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      isDoctorVerified: isDoctorVerified ?? this.isDoctorVerified,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  /// Mock login — no network call in M1
  Future<void> login({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    state = AuthState(
      isAuthenticated: true,
      role: role,
      userId: 'mock-user-001',
      name: role == UserRole.doctor ? 'Dr. Sunita Verma' : 'Rahul Sharma',
      isDoctorVerified: role == UserRole.doctor,
    );
  }

  /// Mock register
  Future<void> register({
    required String name,
    required String phone,
    required UserRole role,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    state = AuthState(
      isAuthenticated: true,
      role: role,
      userId: 'mock-user-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      isDoctorVerified: false, // doctors always start unverified
    );
  }

  void logout() {
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);
