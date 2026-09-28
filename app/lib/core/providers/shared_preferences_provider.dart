// AarogyaMP — Shared SharedPreferences provider
// Person C owns this file.
//
// Initialized in main() and injected via ProviderScope.overrides.
// Any provider that needs persistent storage reads from this.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Override this in ProviderScope with the real SharedPreferences instance.
/// See main.dart for the initialization pattern.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in ProviderScope.\n'
    'Add: SharedPreferences.getInstance() in main() and pass via overrides.',
  );
});
