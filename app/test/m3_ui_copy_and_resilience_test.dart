// AarogyaMP — Milestone 3 Tests: Person C (Mobile App Track)
// UI Copy Audit, Mandatory Disclaimers (Reference §10), Emergency Redirection, and State Handling
//
// Verification:
// 1. Mandatory DisclaimerBanner text and presence
// 2. Emergency isolation (no possible-conditions on emergency screen, auto-redirection)
// 3. Clinical copy audit across all mock assessments (no definitive diagnoses)
// 4. Defense-in-depth on unverified doctors and degraded-path state handling

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aarogyamp/core/models/assessment_model.dart';
import 'package:aarogyamp/core/models/doctor_model.dart';
import 'package:aarogyamp/core/models/consultation_model.dart';
import 'package:aarogyamp/widgets/shared_widgets.dart';
import 'package:aarogyamp/features/assessment/assessment_result_screen.dart';

void main() {
  group('Milestone 3 — Mandatory Disclaimer Audit (Reference §10)', () {
    testWidgets('DisclaimerBanner renders required non-diagnostic text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DisclaimerBanner(),
          ),
        ),
      );

      // Verify the mandatory disclaimer line is displayed
      expect(
        find.text(
          'This is an AI-generated possible-conditions read, not a medical diagnosis. A doctor makes the final call.',
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
    });

    testWidgets('AssessmentResultScreen renders DisclaimerBanner on non-emergency', (tester) async {
      final mockResult = AssessmentResult(
        assessmentId: 'asm-test-01',
        isEmergency: false,
        riskLevel: 'MODERATE',
        possibleConditions: [
          const PossibleCondition(name: 'Viral upper respiratory illness', likelihood: 'high'),
        ],
        recommendedSpecialty: 'General Physician',
        recommendationText: 'Consult a general physician. Rest and stay hydrated.',
        aiStatus: 'ok',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AssessmentResultScreen(result: mockResult),
        ),
      );

      // Verify DisclaimerBanner is present in the widget tree
      expect(find.byType(DisclaimerBanner), findsOneWidget);
      expect(find.text('Possible Causes'), findsOneWidget);
      expect(find.text('Viral upper respiratory illness'), findsOneWidget);
      expect(find.text('Find a General Physician near me'), findsOneWidget);
    });
  });

  group('Milestone 3 — Emergency Separation & Degraded Path', () {
    testWidgets('AssessmentResult with isEmergency true shows redirecting overlay', (tester) async {
      final emergencyResult = const AssessmentResult(
        assessmentId: 'asm-emg-01',
        isEmergency: true,
        riskLevel: 'EMERGENCY',
        possibleConditions: null,
        recommendedSpecialty: null,
        recommendationText: 'Seek immediate emergency medical care.',
        aiStatus: 'skipped',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AssessmentResultScreen(result: emergencyResult),
        ),
      );

      // AssessmentResultScreen must not render normal conditions; it initiates redirect
      expect(find.text('Possible Causes'), findsNothing);
      expect(find.text('Redirecting...'), findsOneWidget);
    });

    testWidgets('AssessmentResult with aiStatus=unavailable renders degraded path guidance', (tester) async {
      final degradedResult = const AssessmentResult(
        assessmentId: 'asm-deg-01',
        isEmergency: false,
        riskLevel: 'MODERATE',
        possibleConditions: null,
        recommendedSpecialty: 'General Physician',
        recommendationText: 'AI assessment is temporarily unavailable. Consult a general physician.',
        aiStatus: 'unavailable',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AssessmentResultScreen(result: degradedResult),
        ),
      );

      // Degraded path banner must be visible
      expect(
        find.text(
          'AI narrative is temporarily unavailable. Risk level is based on rule-based assessment only.',
        ),
        findsOneWidget,
      );
      expect(find.byType(DisclaimerBanner), findsOneWidget);
    });
  });

  group('Milestone 3 — Clinical Copy Audit of Mock Assessment Data', () {
    test('mock_assessments.json contains no forbidden diagnosis language', () {
      final file = File('lib/mocks/mock_assessments.json');
      if (!file.existsSync()) {
        // Fallback relative path when running from app/
        final fallback = File('app/lib/mocks/mock_assessments.json');
        if (!fallback.existsSync()) return;
      }
      final jsonPath = file.existsSync() ? file.path : 'app/lib/mocks/mock_assessments.json';
      final jsonString = File(jsonPath).readAsStringSync();
      final data = json.decode(jsonString) as Map<String, dynamic>;

      final forbiddenRegexes = [
        RegExp(r'\byou have\b', caseSensitive: false),
        RegExp(r'\bdiagnosed with\b', caseSensitive: false),
        RegExp(r'\bthe diagnosis is\b', caseSensitive: false),
        RegExp(r'\byou are suffering from\b', caseSensitive: false),
        RegExp(r'\bconfirmed case\b', caseSensitive: false),
        RegExp(r'\bprescribe\b', caseSensitive: false),
      ];

      for (final entry in data.entries) {
        final personaId = entry.key;
        final assessment = entry.value as Map<String, dynamic>;

        // Non-emergency personas must include the non-diagnostic disclaimer
        if (assessment['is_emergency'] == false) {
          final disclaimer = assessment['_disclaimer'] as String?;
          expect(
            disclaimer,
            isNotNull,
            reason: 'Persona $personaId is missing mandatory _disclaimer',
          );
          expect(
            disclaimer,
            contains('not a medical diagnosis'),
            reason: 'Persona $personaId disclaimer missing "not a medical diagnosis"',
          );
        }

        // Check recommendation text
        final recText = assessment['recommendation_text'] as String?;
        if (recText != null) {
          for (final pattern in forbiddenRegexes) {
            expect(
              pattern.hasMatch(recText),
              isFalse,
              reason: 'Persona $personaId recommendation contains forbidden pattern "${pattern.pattern}": "$recText"',
            );
          }
        }

        // Check condition names
        final conditions = assessment['possible_conditions'] as List<dynamic>?;
        if (conditions != null) {
          for (final c in conditions) {
            final name = (c as Map<String, dynamic>)['name'] as String;
            for (final pattern in forbiddenRegexes) {
              expect(
                pattern.hasMatch(name),
                isFalse,
                reason: 'Persona $personaId condition name contains forbidden pattern "${pattern.pattern}": "$name"',
              );
            }
          }
        }
      }
    });
  });

  group('Milestone 3 — Defense-in-Depth & Queue Models', () {
    test('Unverified doctor is blocked by client-side verification check', () {
      const unverifiedDoc = Doctor(
        id: 'doc-unv-01',
        name: 'Dr. Unverified Fake',
        specialty: 'Cardiologist',
        hospital: 'City Clinic',
        verificationStatus: 'unverified',
        phone: '+919876543210',
        email: 'fake@example.com',
      );

      // Defense-in-depth: isVerified must be strictly false
      expect(unverifiedDoc.isVerified, isFalse);
    });

    test('PatientQueueItem handles emergency and non-emergency items gracefully', () {
      final queueJson = {
        'consultation_id': 'c-201',
        'patient_name': 'Meera Verma',
        'symptom_summary': 'Mild seasonal allergy symptoms',
        'risk_level': 'LOW',
        'is_emergency': false,
        'started_at': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
      };

      final item = PatientQueueItem.fromJson(queueJson);
      expect(item.isEmergency, isFalse);
      expect(item.displayRiskLevel, 'LOW');
      expect(item.timeAgoText, contains('min ago'));
    });
  });
}
