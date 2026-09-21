/// AarogyaMP — go_router configuration (Milestone 0 stub)
/// Person C owns this file.
///
/// All routes from Reference §12. Role-based redirect guard:
///   - Unauthenticated → /login
///   - Unverified doctor → /pending-verification
///   - Patient accessing /doctor/* routes → redirect to /home
///   - Doctor accessing patient-only routes → redirect to /doctor/queue
///
/// TODO (M1 — Person C): Implement auth state + redirect guards.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Route path constants
class Routes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String patientHome = '/home';
  static const String symptomText = '/symptoms/text';
  static const String symptomVoice = '/symptoms/voice';
  static const String vitals = '/vitals';
  static const String assessment = '/assessment/:id';
  static const String emergency = '/emergency';
  static const String doctorList = '/doctors';
  static const String doctorMap = '/doctors/map';
  static const String doctorProfile = '/doctors/:id';
  static const String chat = '/chat/:consultationId';
  static const String doctorQueue = '/doctor/queue';
  static const String patientDetail = '/doctor/patient/:id';
  static const String history = '/history';
  static const String pendingVerification = '/pending-verification';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.splash,
    // TODO (M1 — Person C): add redirect + refreshListenable for auth state
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const _PlaceholderScreen(label: 'Splash'),
      ),
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const _PlaceholderScreen(label: 'Login'),
      ),
      GoRoute(
        path: Routes.register,
        builder: (context, state) => const _PlaceholderScreen(label: 'Register'),
      ),
      GoRoute(
        path: Routes.patientHome,
        builder: (context, state) => const _PlaceholderScreen(label: 'Patient Home'),
      ),
      GoRoute(
        path: Routes.symptomText,
        builder: (context, state) => const _PlaceholderScreen(label: 'Symptom Text Input'),
      ),
      GoRoute(
        path: Routes.symptomVoice,
        builder: (context, state) => const _PlaceholderScreen(label: 'Symptom Voice Input'),
      ),
      GoRoute(
        path: Routes.vitals,
        builder: (context, state) => const _PlaceholderScreen(label: 'Vitals Entry'),
      ),
      GoRoute(
        path: '/assessment/:id',
        builder: (context, state) => _PlaceholderScreen(label: 'Assessment Result: ${state.pathParameters['id']}'),
      ),
      GoRoute(
        path: Routes.emergency,
        builder: (context, state) => const _PlaceholderScreen(label: 'EMERGENCY — Full Screen'),
      ),
      GoRoute(
        path: Routes.doctorList,
        builder: (context, state) => const _PlaceholderScreen(label: 'Doctor List'),
      ),
      GoRoute(
        path: Routes.doctorMap,
        builder: (context, state) => const _PlaceholderScreen(label: 'Doctor Map'),
      ),
      GoRoute(
        path: '/doctors/:id',
        builder: (context, state) => _PlaceholderScreen(label: 'Doctor Profile: ${state.pathParameters['id']}'),
      ),
      GoRoute(
        path: '/chat/:consultationId',
        builder: (context, state) => _PlaceholderScreen(label: 'Chat: ${state.pathParameters['consultationId']}'),
      ),
      GoRoute(
        path: Routes.doctorQueue,
        builder: (context, state) => const _PlaceholderScreen(label: 'Doctor Queue'),
      ),
      GoRoute(
        path: '/doctor/patient/:id',
        builder: (context, state) => _PlaceholderScreen(label: 'Patient Detail: ${state.pathParameters['id']}'),
      ),
      GoRoute(
        path: Routes.history,
        builder: (context, state) => const _PlaceholderScreen(label: 'Consultation History'),
      ),
      GoRoute(
        path: Routes.pendingVerification,
        builder: (context, state) => const _PlaceholderScreen(label: 'Pending Verification'),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Route not found: ${state.uri}')),
    ),
  );
});

/// Temporary placeholder shown on all routes until real screens are built.
class _PlaceholderScreen extends StatelessWidget {
  final String label;
  const _PlaceholderScreen({required this.label});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(label)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction, size: 48, color: Colors.orange),
            const SizedBox(height: 16),
            Text(label, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('Screen placeholder — M1 implementation pending'),
          ],
        ),
      ),
    );
  }
}
