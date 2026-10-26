// AarogyaMP — Consultation / Queue models (M2 — Person C)
// Mirrors PatientQueueItem schema (FROZEN §11 — schemas.py).

import 'package:intl/intl.dart';

class QueueVitals {
  final double? temperatureF;
  final int? heartRateBpm;
  final int? systolicBp;
  final int? diastolicBp;
  final int? spo2Pct;

  const QueueVitals({
    this.temperatureF,
    this.heartRateBpm,
    this.systolicBp,
    this.diastolicBp,
    this.spo2Pct,
  });

  factory QueueVitals.fromJson(Map<String, dynamic> json) => QueueVitals(
        temperatureF: (json['temperature_f'] as num?)?.toDouble(),
        heartRateBpm: json['heart_rate_bpm'] as int?,
        systolicBp: json['systolic_bp'] as int?,
        diastolicBp: json['diastolic_bp'] as int?,
        spo2Pct: json['spo2_pct'] as int?,
      );

  String get summaryText {
    final parts = <String>[];
    if (temperatureF != null) parts.add('Temp: ${temperatureF!.toStringAsFixed(1)}°F');
    if (heartRateBpm != null) parts.add('HR: $heartRateBpm bpm');
    if (systolicBp != null && diastolicBp != null) {
      parts.add('BP: $systolicBp/$diastolicBp mmHg');
    }
    if (spo2Pct != null) parts.add('SpO₂: $spo2Pct%');
    return parts.join(' · ');
  }
}

class PatientQueueItem {
  final String consultationId;
  final String patientName;
  final String symptomSummary;
  final String? riskLevel; // "LOW" | "MODERATE" | "HIGH" | "EMERGENCY" | null
  final bool isEmergency;
  final DateTime startedAt;
  final QueueVitals? vitals;

  const PatientQueueItem({
    required this.consultationId,
    required this.patientName,
    required this.symptomSummary,
    this.riskLevel,
    required this.isEmergency,
    required this.startedAt,
    this.vitals,
  });

  factory PatientQueueItem.fromJson(Map<String, dynamic> json) =>
      PatientQueueItem(
        consultationId: json['consultation_id'] as String,
        patientName: json['patient_name'] as String,
        symptomSummary: json['symptom_summary'] as String,
        riskLevel: json['risk_level'] as String?,
        isEmergency: json['is_emergency'] as bool? ?? false,
        startedAt: DateTime.parse(json['started_at'] as String),
        vitals: json['vitals'] != null
            ? QueueVitals.fromJson(json['vitals'] as Map<String, dynamic>)
            : null,
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

