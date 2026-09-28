// AarogyaMP — Milestone 2 Unit Tests (Person C)
// Tests: DoctorService, ConsultationService, PatientQueueItem, ChatMessageModel

import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:aarogyamp/core/models/consultation_model.dart';
import 'package:aarogyamp/core/services/consultation_service.dart';
import 'package:aarogyamp/core/services/doctor_service.dart';

void main() {
  group('PatientQueueItem model tests', () {
    test('parses JSON correctly with all fields', () {
      final json = {
        'consultation_id': 'c-101',
        'patient_name': 'Rahul Sharma',
        'symptom_summary': 'Severe headache and nausea',
        'risk_level': 'HIGH',
        'is_emergency': false,
        'started_at': DateTime.now().subtract(const Duration(minutes: 15)).toIso8601String(),
      };

      final item = PatientQueueItem.fromJson(json);

      expect(item.consultationId, 'c-101');
      expect(item.patientName, 'Rahul Sharma');
      expect(item.symptomSummary, 'Severe headache and nausea');
      expect(item.riskLevel, 'HIGH');
      expect(item.displayRiskLevel, 'HIGH');
      expect(item.isEmergency, false);
      expect(item.timeAgoText, contains('min ago'));
    });

    test('handles null risk level and emergency flag', () {
      final json = {
        'consultation_id': 'c-102',
        'patient_name': 'Ankit Patel',
        'symptom_summary': 'General consultation',
        'risk_level': null,
        'is_emergency': true,
        'started_at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      };

      final item = PatientQueueItem.fromJson(json);

      expect(item.displayRiskLevel, 'UNKNOWN');
      expect(item.isEmergency, true);
      expect(item.timeAgoText, contains('hrs ago'));
    });
  });

  group('ChatMessageModel tests', () {
    test('parses and serializes ChatMessageModel', () {
      final now = DateTime.now();
      final json = {
        'id': 'msg-001',
        'consultation_id': 'c-101',
        'sender_role': 'patient',
        'message_type': 'text',
        'text': 'Hello doctor',
        'file_path': null,
        'timestamp': now.toIso8601String(),
      };

      final msg = ChatMessageModel.fromJson(json);

      expect(msg.id, 'msg-001');
      expect(msg.isPatient, true);
      expect(msg.text, 'Hello doctor');
      expect(msg.toJson()['id'], 'msg-001');
    });

    test('parses WebSocket broadcast payload correctly', () {
      final now = DateTime.now();
      final wsJson = {
        'id': 'msg-002',
        'consultation_id': 'c-101',
        'sender_role': 'doctor',
        'message_type': 'text',
        'text': 'Take 500mg paracetamol',
        'file_path': null,
        'timestamp': now.toIso8601String(),
      };

      final msg = ChatMessageModel.fromWsBroadcast(wsJson);
      expect(msg.isPatient, false);
      expect(msg.senderRole, 'doctor');
      expect(msg.text, 'Take 500mg paracetamol');
    });
  });

  group('DoctorService query params', () {
    test('DoctorService sends query parameters properly', () async {
      final dio = Dio();
      dio.httpClientAdapter = _MockHttpClientAdapter((options) {
        expect(options.queryParameters['specialty'], 'Cardiologist');
        expect(options.queryParameters['lat'], 23.25);
        expect(options.queryParameters['lng'], 77.41);
        expect(options.queryParameters['radius_km'], 50.0);
        return ResponseBody.fromString(
          '{"doctors": []}',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType]
          },
        );
      });

      final service = DoctorService(dio);
      final docs = await service.getDoctors(
        specialty: 'Cardiologist',
        lat: 23.25,
        lng: 77.41,
        radiusKm: 50.0,
      );

      expect(docs, isEmpty);
    });
  });

  group('ConsultationService REST tests', () {
    test('createConsultation sends correct POST payload', () async {
      final dio = Dio();
      dio.httpClientAdapter = _MockHttpClientAdapter((options) {
        expect(options.path, '/api/consultations');
        expect(options.method, 'POST');
        final data = options.data as Map<String, dynamic>;
        expect(data['doctor_id'], 'doc-123');
        expect(data['channel'], 'chat');
        expect(data['symptom_report_id'], 'sr-456');

        return ResponseBody.fromString(
          '{"consultation_id": "consult-created-999"}',
          201,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType]
          },
        );
      });

      final service = ConsultationService(dio);
      final id = await service.createConsultation(
        doctorId: 'doc-123',
        symptomReportId: 'sr-456',
      );

      expect(id, 'consult-created-999');
    });

    test('getMessages fetches and maps chat messages', () async {
      final dio = Dio();
      dio.httpClientAdapter = _MockHttpClientAdapter((options) {
        expect(options.path, '/api/consultations/c-777/messages');
        expect(options.queryParameters['limit'], 50);

        final now = DateTime.now().toIso8601String();
        return ResponseBody.fromString(
          '{"messages": [{"id": "m1", "consultation_id": "c-777", "sender_role": "patient", "message_type": "text", "text": "Hi", "timestamp": "$now"}]}',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType]
          },
        );
      });

      final service = ConsultationService(dio);
      final msgs = await service.getMessages('c-777');

      expect(msgs.length, 1);
      expect(msgs.first.text, 'Hi');
      expect(msgs.first.isPatient, true);
    });
  });
}

class _MockHttpClientAdapter implements HttpClientAdapter {
  final ResponseBody Function(RequestOptions options) _handler;
  _MockHttpClientAdapter(this._handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return _handler(options);
  }

  @override
  void close({bool force = false}) {}
}
