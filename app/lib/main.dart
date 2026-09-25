// AarogyaMP — App entry point
// Person C owns this file.
//
// Reads USE_MOCKS build flag:
//   flutter run --dart-define=USE_MOCKS=true   → uses app/lib/mocks/
//   flutter run --dart-define=USE_MOCKS=false  → wires live API
//
// Routes are defined in core/router/app_router.dart (go_router)
// Theme is defined in core/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

// Build flag — toggle mocks vs. live API
const bool kUseMocks = bool.fromEnvironment('USE_MOCKS', defaultValue: true);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Lock to portrait
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  // TODO (M2 — Person C): Initialize Firebase if USE_MOCKS=false
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
    // Apply Noto Sans via google_fonts to the generated theme
    final baseTheme = AppTheme.light;
    final theme = baseTheme.copyWith(
      textTheme: GoogleFonts.notoSansTextTheme(baseTheme.textTheme),
    );
    return MaterialApp.router(
      title: 'AarogyaMP',
      theme: theme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
