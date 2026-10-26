// AarogyaMP — Global Language / Locale Provider (Person C)
// Default: English (false). Toggles to Hindi (true) via StitchHeader pill.
// Persisted in SharedPreferences so user choice is preserved across screens and restarts.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'shared_preferences_provider.dart';

const String _kIsHindiKey = 'app_language_is_hindi';

final isHindiProvider = StateNotifierProvider<IsHindiNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final saved = prefs.getBool(_kIsHindiKey) ?? false; // Default: English
  return IsHindiNotifier(prefs, saved);
});

class IsHindiNotifier extends StateNotifier<bool> {
  final SharedPreferences _prefs;
  IsHindiNotifier(this._prefs, bool initial) : super(initial);

  void toggle() {
    state = !state;
    _prefs.setBool(_kIsHindiKey, state);
  }

  void setHindi(bool value) {
    state = value;
    _prefs.setBool(_kIsHindiKey, state);
  }
}

/// Helper extension on bool to pick between Hindi and English text cleanly.
extension BilingualText on bool {
  String tr({required String en, required String hi}) => this ? hi : en;
}
