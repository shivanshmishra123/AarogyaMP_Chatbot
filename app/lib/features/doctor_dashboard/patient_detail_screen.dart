/// AarogyaMP — Patient detail screen stub (Person C, M1) — Doctor role — Route: /doctor/patient/:id
/// Shows: symptoms + vitals + AI assessment (labeled as AI-generated, not fact) + chat entry.
import 'package:flutter/material.dart';

class PatientDetailScreen extends StatelessWidget {
  final String patientId;
  const PatientDetailScreen({super.key, required this.patientId});
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('Patient Detail: $patientId — M1')));
  }
}
