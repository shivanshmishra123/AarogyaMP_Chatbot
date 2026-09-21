/// AarogyaMP — Assessment result screen stub (Person C, M1)
/// Route: /assessment/:id
/// Mandatory disclaimer must render every time. Not used for EMERGENCY (see emergency_screen.dart).
import 'package:flutter/material.dart';

class AssessmentResultScreen extends StatelessWidget {
  final String assessmentId;
  const AssessmentResultScreen({super.key, required this.assessmentId});
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('Assessment Result: $assessmentId — M1')));
  }
}
