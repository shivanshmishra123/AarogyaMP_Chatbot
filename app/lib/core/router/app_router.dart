// AarogyaMP — go_router configuration (M1 — Person C)
// All routes from Reference §12. Role-based redirect guard wired.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/patient_home_screen.dart';
import '../../features/symptom_intake/symptom_input_screens.dart';
import '../../features/symptom_intake/vitals_entry_screen.dart';
import '../../features/assessment/assessment_result_screen.dart';
import '../../features/assessment/emergency_screen.dart';
import '../../features/doctor_directory/doctor_list_screen.dart';
import '../../features/chat/chat_screen.dart';
import '../../features/doctor_dashboard/doctor_dashboard_screens.dart';
import '../../core/models/assessment_model.dart';
import '../../core/models/doctor_model.dart';

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
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: Routes.splash,
    redirect: (context, state) {
      final isAuth = authState.isAuthenticated;
      final loc = state.uri.toString();

      // Unauthenticated: allow only splash, login, register
      final publicRoutes = [Routes.splash, Routes.login, Routes.register];
      if (!isAuth && !publicRoutes.contains(loc)) {
        return Routes.login;
      }

      // Authenticated doctor but unverified: gate to pending screen
      if (isAuth &&
          authState.role == UserRole.doctor &&
          !authState.isDoctorVerified &&
          loc != Routes.pendingVerification &&
          loc != Routes.login) {
        return Routes.pendingVerification;
      }

      // Authenticated patient: redirect splash/login → home
      if (isAuth &&
          authState.role == UserRole.patient &&
          (loc == Routes.splash || loc == Routes.login)) {
        return Routes.patientHome;
      }

      // Authenticated verified doctor: redirect splash/login → queue
      if (isAuth &&
          authState.role == UserRole.doctor &&
          authState.isDoctorVerified &&
          (loc == Routes.splash || loc == Routes.login)) {
        return Routes.doctorQueue;
      }

      return null; // No redirect
    },
    routes: [
      // ── Splash / Auth ─────────────────────────────────────────────
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const _SplashScreen(),
      ),
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.register,
        builder: (context, state) => const RegisterScreen(),
      ),

      // ── Patient flow ───────────────────────────────────────────────
      GoRoute(
        path: Routes.patientHome,
        builder: (context, state) => const PatientHomeScreen(),
      ),
      GoRoute(
        path: Routes.symptomText,
        builder: (context, state) => const SymptomTextInputScreen(),
      ),
      GoRoute(
        path: Routes.symptomVoice,
        builder: (context, state) => const SymptomVoiceInputScreen(),
      ),
      GoRoute(
        path: Routes.vitals,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return VitalsEntryScreen(
            rawText: extra?['raw_text'] as String? ?? '',
            inputMode: extra?['input_mode'] as String? ?? 'text',
          );
        },
      ),
      GoRoute(
        path: '/assessment/:id',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is AssessmentResult) {
            return AssessmentResultScreen(result: extra);
          }
          // Fallback: should not normally happen in M1
          return const Scaffold(
            body: Center(child: Text('Assessment not found')),
          );
        },
      ),
      GoRoute(
        path: Routes.emergency,
        builder: (context, state) {
          final extra = state.extra;
          return EmergencyScreen(
            result: extra is AssessmentResult ? extra : null,
          );
        },
      ),

      // ── Doctor directory ───────────────────────────────────────────
      GoRoute(
        path: Routes.doctorList,
        builder: (context, state) {
          final specialty = state.extra as String?;
          return DoctorListScreen(initialSpecialty: specialty);
        },
      ),
      GoRoute(
        path: Routes.doctorMap,
        builder: (context, state) => const _DoctorMapPlaceholder(),
      ),
      GoRoute(
        path: '/doctors/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final extra = state.extra;
          return DoctorProfileScreen(
            doctorId: id,
            doctor: extra is Doctor ? extra : null,
          );
        },
      ),

      // ── Chat ───────────────────────────────────────────────────────
      GoRoute(
        path: '/chat/:consultationId',
        builder: (context, state) {
          final id = state.pathParameters['consultationId'] ?? '';
          final extra = state.extra as Map<String, dynamic>?;
          return ChatScreen(
            consultationId: id,
            doctorName: extra?['doctorName'] as String?,
          );
        },
      ),

      // ── Doctor role ────────────────────────────────────────────────
      GoRoute(
        path: Routes.doctorQueue,
        builder: (context, state) => const PatientQueueScreen(),
      ),
      GoRoute(
        path: '/doctor/patient/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final extra = state.extra;
          return PatientDetailScreen(
            patientId: id,
            patient: null, // extra is _MockPatient but it's private; pass null to let screen look it up
          );
        },
      ),

      // ── History / misc ─────────────────────────────────────────────
      GoRoute(
        path: Routes.history,
        builder: (context, state) => const ConsultationHistoryScreen(),
      ),
      GoRoute(
        path: Routes.pendingVerification,
        builder: (context, state) => const PendingVerificationScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: Colors.orange),
            const SizedBox(height: 16),
            Text('Route not found: ${state.uri}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(Routes.patientHome),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});

// ─────────────────────────────────────────────────────────────────────────────
// Splash screen — quickly redirects based on auth state
// ─────────────────────────────────────────────────────────────────────────────
class _SplashScreen extends ConsumerStatefulWidget {
  const _SplashScreen();

  @override
  ConsumerState<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<_SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      final auth = ref.read(authProvider);
      if (auth.isAuthenticated) {
        if (auth.role == UserRole.doctor) {
          if (auth.isDoctorVerified) {
            context.go(Routes.doctorQueue);
          } else {
            context.go(Routes.pendingVerification);
          }
        } else {
          context.go(Routes.patientHome);
        }
      } else {
        context.go(Routes.login);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF087F5B),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 48),
            ),
            const SizedBox(height: 20),
            const Text(
              'AarogyaMP',
              style: TextStyle(
                fontFamily: 'NotoSans',
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your Health, Our Priority',
              style: TextStyle(
                fontFamily: 'NotoSans',
                fontSize: 15,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Doctor Map Placeholder (M2 feature — Google Maps wired later)
// ─────────────────────────────────────────────────────────────────────────────
class _DoctorMapPlaceholder extends StatelessWidget {
  const _DoctorMapPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Map'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 48, color: Color(0xFFBDC9C1)),
            SizedBox(height: 12),
            Text('Map view — available in M2 after Google Maps integration'),
          ],
        ),
      ),
    );
  }
}
