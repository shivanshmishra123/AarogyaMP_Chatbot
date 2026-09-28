// AarogyaMP — Consultation / Queue models (M2 — Person C)
// Mirrors PatientQueueItem schema (FROZEN §11 — schemas.py).

import 'package:intl/intl.dart';

class PatientQueueItem {
  final String consultationId;
  final String patientName;
  final String symptomSummary;
  final String? riskLevel; // "LOW" | "MODERATE" | "HIGH" | "EMERGENCY" | null
  final bool isEmergency;
  final DateTime startedAt;

  const PatientQueueItem({
    required this.consultationId,
    required this.patientName,
    required this.symptomSummary,
    this.riskLevel,
    required this.isEmergency,
    required this.startedAt,
  });

  factory PatientQueueItem.fromJson(Map<String, dynamic> json) =>
      PatientQueueItem(
        consultationId: json['consultation_id'] as String,
        patientName: json['patient_name'] as String,
        symptomSummary: json['symptom_summary'] as String,
        riskLevel: json['risk_level'] as String?,
        isEmergency: json['is_emergency'] as bool? ?? false,
        startedAt: DateTime.parse(json['started_at'] as String),
      );

  /// Human-readable "X min ago" / "X hrs ago" label.
  String get timeAgoText {
    final diff = DateTime.now().difference(startedAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hrs ago';
    return DateFormat('d MMM').format(startedAt.toLocal());
  }

  String get displayRiskLevel => riskLevel ?? 'UNKNOWN';
}
