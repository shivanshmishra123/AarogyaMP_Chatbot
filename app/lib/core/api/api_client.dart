// AarogyaMP — Dio HTTP client with auth interceptor (Milestone 0 stub)
// Person C owns this file.
//
// API_BASE_URL and WS_BASE_URL injected via --dart-define:
//   flutter run --dart-define=API_BASE_URL=http://192.168.x.x:8000
//              --dart-define=WS_BASE_URL=ws://192.168.x.x:8000
//
// See Reference §5 (Mobile app config) for networking note on LAN IP.
//
// TODO (M1 — Person C): Wire auth token interceptor + refresh logic.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const String _apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8000',
);

const String _wsBaseUrl = String.fromEnvironment(
  'WS_BASE_URL',
  defaultValue: 'ws://localhost:8000',
);

// Public constants
const String kApiBaseUrl = _apiBaseUrl;
const String kWsBaseUrl = _wsBaseUrl;

Dio _buildDio() {
  final dio = Dio(
    BaseOptions(
      baseUrl: _apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  // TODO (M1 — Person C): Add auth interceptor
  // dio.interceptors.add(AuthInterceptor(ref));

  return dio;
}

final dioProvider = Provider<Dio>((ref) => _buildDio());
