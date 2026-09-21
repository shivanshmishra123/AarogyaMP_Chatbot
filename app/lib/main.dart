/// AarogyaMP — App entry point (Milestone 0 stub)
/// Person C owns this file.
///
/// Reads USE_MOCKS build flag:
///   flutter run --dart-define=USE_MOCKS=true   → uses app/lib/mocks/
///   flutter run --dart-define=USE_MOCKS=false  → wires live API
///
/// Routes are defined in core/router/app_router.dart (go_router)
/// Theme is defined in core/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

// Build flag — toggle mocks vs. live API
const bool kUseMocks = bool.fromEnvironment('USE_MOCKS', defaultValue: true);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // TODO (M0 — Person C): Initialize Firebase if USE_MOCKS=false
  // await Firebase.initializeApp();
  runApp(
    const ProviderScope(
      child: AarogyaMPApp(),
    ),
  );
}

class AarogyaMPApp extends ConsumerWidget {
  const AarogyaMPApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'AarogyaMP',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
