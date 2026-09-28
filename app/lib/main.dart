// AarogyaMP — App entry point (M2 — Person C)
//
// USE_MOCKS build flag:
//   flutter run --dart-define=USE_MOCKS=true   → uses app/lib/mocks/ (default)
//   flutter run --dart-define=USE_MOCKS=false  → wires live API
//
// SharedPreferences initialized here and injected via ProviderScope.overrides
// so all providers can access it synchronously without FutureProvider chains.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/shared_preferences_provider.dart';

const bool kUseMocks = bool.fromEnvironment('USE_MOCKS', defaultValue: true);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize persistent storage (needed for JWT token, session restore)
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        // Inject the SharedPreferences instance so any provider can watch it.
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const AarogyaMPApp(),
    ),
  );
}

class AarogyaMPApp extends ConsumerWidget {
  const AarogyaMPApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
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
