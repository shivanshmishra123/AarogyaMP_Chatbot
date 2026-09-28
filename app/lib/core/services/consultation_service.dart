// AarogyaMP — Consultation + Chat Message Service (M2 — Person C)
// Wraps:
//   POST /api/consultations          → create consultation, returns consultation_id
//   GET  /api/consultations/{id}/messages  → paginated chat history (for load + reconnect)

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../api/endpoints.dart';

/// Mirrors ChatMessageOut schema (FROZEN §11).
class ChatMessageModel {
  final String id;
  final String consultationId;
  final String senderRole; // "patient" | "doctor"
  final String messageType; // "text" | "voice" | "image" | "document"
  final String? text;
  final String? filePath;
  final DateTime timestamp;

  const ChatMessageModel({
    required this.id,
    required this.consultationId,
    required this.senderRole,
    required this.messageType,
    this.text,
    this.filePath,
    required this.timestamp,
  });

  bool get isPatient => senderRole == 'patient';

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) =>
      ChatMessageModel(
        id: json['id'] as String,
        consultationId: json['consultation_id'] as String,
        senderRole: json['sender_role'] as String,
        messageType: json['message_type'] as String,
        text: json['text'] as String?,
        filePath: json['file_path'] as String?,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );

  /// Used to reconstruct from a WebSocket broadcast payload (same shape).
  factory ChatMessageModel.fromWsBroadcast(Map<String, dynamic> json) =>
      ChatMessageModel.fromJson(json);

  Map<String, dynamic> toJson() => {
        'id': id,
        'consultation_id': consultationId,
        'sender_role': senderRole,
        'message_type': messageType,
        'text': text,
        'file_path': filePath,
        'timestamp': timestamp.toIso8601String(),
      };
}

class ConsultationService {
  final Dio _dio;
  ConsultationService(this._dio);

  /// POST /api/consultations — creates a chat consultation, returns consultation_id.
  Future<String> createConsultation({
    required String doctorId,
    String? symptomReportId,
  }) async {
    final response = await _dio.post(
      Endpoints.createConsultation,
      data: {
        'doctor_id': doctorId,
        'channel': 'chat',
        if (symptomReportId != null) 'symptom_report_id': symptomReportId,
      },
    );
    return response.data['consultation_id'] as String;
  }

  /// GET /api/consultations/{id}/messages — returns chronological message list.
  /// Used on initial load AND on reconnect to catch up on missed messages.
  Future<List<ChatMessageModel>> getMessages(
    String consultationId, {
    int limit = 50,
  }) async {
    final response = await _dio.get(
      Endpoints.getMessages(consultationId),
      queryParameters: {'limit': limit},
    );
    return (response.data['messages'] as List)
        .map((m) => ChatMessageModel.fromJson(m as Map<String, dynamic>))
        .toList();
  }
}

final consultationServiceProvider = Provider<ConsultationService>((ref) {
  return ConsultationService(ref.watch(dioProvider));
});
