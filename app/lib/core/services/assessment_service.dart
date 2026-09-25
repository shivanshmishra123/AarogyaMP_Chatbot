// AarogyaMP — Assessment Service (Checkpoint 1 — Person C)
// Wires assessment submission between mock engine and real backend.
// When USE_MOCKS=true (default in M1): uses MockService fixtures.
// When USE_MOCKS=false (CP1 integration): calls POST /api/assessments over HTTP.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../api/endpoints.dart';
import '../models/assessment_model.dart';
import 'mock_service.dart';

class AssessmentService {
  final Dio _dio;
  final MockService _mockService;

  AssessmentService(this._dio, this._mockService);

  /// Submits symptoms and vitals.
  /// Automatically toggles between MockService and live HTTP based on USE_MOCKS flag.
  Future<AssessmentResult> submitAssessment({
    required String rawText,
    required String inputMode,
    Map<String, dynamic>? vitals,
    String? durationText,
  }) async {
    const useMocks = bool.fromEnvironment('USE_MOCKS', defaultValue: true);

    if (useMocks) {
      return _mockService.submitAssessment(
        rawText: rawText,
        inputMode: inputMode,
        vitals: vitals,
      );
    }

    final payload = <String, dynamic>{
      'raw_text': rawText,
      'input_mode': inputMode,
      if (durationText != null && durationText.isNotEmpty)
        'duration_text': durationText,
      if (vitals != null && vitals.isNotEmpty)
        'vitals': vitals,
    };

    final response = await _dio.post(
      Endpoints.submitAssessment,
      data: payload,
    );

    return AssessmentResult.fromJson(response.data as Map<String, dynamic>);
  }

  /// Fetches an assessment by ID.
  Future<AssessmentResult> getAssessmentById(String id) async {
    const useMocks = bool.fromEnvironment('USE_MOCKS', defaultValue: true);
    if (useMocks) {
      return _mockService.getAssessmentById(id);
    }

    final response = await _dio.get(Endpoints.getAssessment(id));
    return AssessmentResult.fromJson(response.data as Map<String, dynamic>);
  }
}

final assessmentServiceProvider = Provider<AssessmentService>((ref) {
  final dio = ref.watch(dioProvider);
  final mockService = ref.watch(mockServiceProvider);
  return AssessmentService(dio, mockService);
});
