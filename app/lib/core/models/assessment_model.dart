// AarogyaMP — Assessment Dart model (mirrors schemas.py AssessmentResponse — FROZEN)
// Person C owns this file.

class PossibleCondition {
  final String name;
  final String likelihood; // high | medium | low

  const PossibleCondition({required this.name, required this.likelihood});

  factory PossibleCondition.fromJson(Map<String, dynamic> json) =>
      PossibleCondition(name: json['name'], likelihood: json['likelihood']);
}

class EmergencyTrigger {
  final String ruleId;
  final String description;

  const EmergencyTrigger({required this.ruleId, required this.description});

  factory EmergencyTrigger.fromJson(Map<String, dynamic> json) =>
      EmergencyTrigger(ruleId: json['rule_id'], description: json['description']);
}

class AssessmentResult {
  final String assessmentId;
  final bool isEmergency;
  final String riskLevel; // LOW | MODERATE | HIGH | EMERGENCY
  final List<EmergencyTrigger>? emergencyTriggers;
  final List<PossibleCondition>? possibleConditions;
  final String? recommendedSpecialty;
  final String? recommendationText;
  final String aiStatus; // ok | unavailable | skipped

  const AssessmentResult({
    required this.assessmentId,
    required this.isEmergency,
    required this.riskLevel,
    this.emergencyTriggers,
    this.possibleConditions,
    this.recommendedSpecialty,
    this.recommendationText,
    required this.aiStatus,
  });

  factory AssessmentResult.fromJson(Map<String, dynamic> json) {
    return AssessmentResult(
      assessmentId: json['assessment_id'],
      isEmergency: json['is_emergency'],
      riskLevel: json['risk_level'],
      emergencyTriggers: (json['emergency_triggers'] as List?)
          ?.map((e) => EmergencyTrigger.fromJson(e))
          .toList(),
      possibleConditions: (json['possible_conditions'] as List?)
          ?.map((e) => PossibleCondition.fromJson(e))
          .toList(),
      recommendedSpecialty: json['recommended_specialty'],
      recommendationText: json['recommendation_text'],
      aiStatus: json['ai_status'],
    );
  }
}
