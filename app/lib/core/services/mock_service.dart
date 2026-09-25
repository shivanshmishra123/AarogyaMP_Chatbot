// AarogyaMP — Mock data service (M1 — Person C)
// Loads JSON fixtures from app/lib/mocks/ when USE_MOCKS=true
// All reads are through this service — never import mock JSON directly from screens.

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/assessment_model.dart';
import '../models/doctor_model.dart';

class MockService {
  // Cached parsed data
  Map<String, dynamic>? _assessments;
  List<dynamic>? _doctors;

  Future<Map<String, dynamic>> _loadAssessments() async {
    _assessments ??= jsonDecode(
      await rootBundle.loadString('lib/mocks/mock_assessments.json'),
    ) as Map<String, dynamic>;
    return _assessments!;
  }

  Future<List<dynamic>> _loadDoctors() async {
    _doctors ??= jsonDecode(
      await rootBundle.loadString('lib/mocks/mock_doctors.json'),
    ) as List<dynamic>;
    return _doctors!;
  }

  /// Returns the mock assessment for a given persona key.
  /// Keys: persona_low, persona_moderate, persona_high,
  ///       persona_emergency_vitals, persona_emergency_keyword
  Future<AssessmentResult> getAssessment(String personaKey) async {
    final data = await _loadAssessments();
    final entry = data[personaKey] as Map<String, dynamic>?;
    if (entry == null) {
      throw Exception('Mock persona "$personaKey" not found');
    }
    return AssessmentResult.fromJson(entry);
  }

  /// Returns the assessment for a mock assessment_id.
  /// For M1 mocks, we map IDs to persona keys.
  Future<AssessmentResult> getAssessmentById(String id) async {
    final data = await _loadAssessments();
    for (final entry in data.entries) {
      if (entry.key.startsWith('_')) continue;
      final val = entry.value as Map<String, dynamic>;
      if (val['assessment_id'] == id) {
        return AssessmentResult.fromJson(val);
      }
    }
    // Default to moderate for unknown IDs during mock mode
    return AssessmentResult.fromJson(
      data['persona_moderate'] as Map<String, dynamic>,
    );
  }

  /// Simulates submitting symptoms; returns a mock assessment based on
  /// keywords in rawText (emergency keyword detection) or falls back to moderate.
  Future<AssessmentResult> submitAssessment({
    required String rawText,
    required String inputMode,
    Map<String, dynamic>? vitals,
  }) async {
    final data = await _loadAssessments();
    // Very basic mock "emergency" detection for demo
    final lower = rawText.toLowerCase();
    final isEmergencyKeyword = lower.contains('chest pain') ||
        lower.contains('can\'t breathe') ||
        lower.contains('unconscious') ||
        lower.contains('stroke') ||
        lower.contains('heart attack');

    final bool isEmergencyVitals = vitals != null &&
        ((vitals['spo2_pct'] != null && (vitals['spo2_pct'] as int) < 90) ||
            (vitals['heart_rate_bpm'] != null &&
                (vitals['heart_rate_bpm'] as int) > 130));

    String key;
    if (isEmergencyKeyword) {
      key = 'persona_emergency_keyword';
    } else if (isEmergencyVitals) {
      key = 'persona_emergency_vitals';
    } else if (lower.contains('chest') || lower.contains('breathe')) {
      key = 'persona_high';
    } else if (lower.contains('fever') || lower.contains('pain')) {
      key = 'persona_moderate';
    } else {
      key = 'persona_low';
    }

    // Simulate a short async delay
    await Future.delayed(const Duration(milliseconds: 800));
    return AssessmentResult.fromJson(
      data[key] as Map<String, dynamic>,
    );
  }

  /// Returns all mock doctors, optionally filtered by specialty.
  Future<List<Doctor>> getDoctors({String? specialty}) async {
    final raw = await _loadDoctors();
    final doctors = raw
        .where((e) => !(e as Map<String, dynamic>).containsKey('_comment'))
        .map((e) => Doctor.fromJson(e as Map<String, dynamic>))
        .where((d) => d.isVerified) // defense-in-depth: never show unverified
        .where((d) => specialty == null || d.specialty == specialty)
        .toList()
      ..sort((a, b) => (a.distanceKm ?? 99).compareTo(b.distanceKm ?? 99));
    return doctors;
  }

  /// Returns a single doctor by id.
  Future<Doctor?> getDoctorById(String id) async {
    final all = await getDoctors();
    try {
      return all.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }
}

final mockServiceProvider = Provider<MockService>((ref) => MockService());
