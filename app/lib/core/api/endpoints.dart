/// AarogyaMP — API endpoints
/// Person C owns this file (mirrors Reference §11 exactly — FROZEN).
///
/// Do NOT rename or add endpoints without updating AAROGYAMP-REFERENCE.md first.

class Endpoints {
  // Base URLs are injected via --dart-define at build time (see core/api/api_client.dart)

  // Auth
  static const String register = '/api/auth/register';
  static const String login = '/api/auth/login';

  // Assessments
  static const String submitAssessment = '/api/assessments';
  static String getAssessment(String id) => '/api/assessments/$id';

  // Doctors
  static const String listDoctors = '/api/doctors';

  // Consultations
  static const String createConsultation = '/api/consultations';
  static String getMessages(String consultationId) =>
      '/api/consultations/$consultationId/messages';

  // Doctor role
  static const String doctorQueue = '/api/doctor/queue';

  // Admin
  static String verifyDoctor(String doctorId) =>
      '/api/admin/doctors/$doctorId/verify';

  // WebSocket — note: uses WS_BASE_URL, not API_BASE_URL
  static String chatWs(String consultationId) =>
      '/ws/chat/$consultationId';

  // Health
  static const String health = '/health';
}
