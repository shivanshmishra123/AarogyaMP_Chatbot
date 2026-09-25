# AarogyaMP — DEVLOG

> Newest entry at top. Each session's AI reads this before starting work.

---

## 2026-09-25 — Milestone 1: Splash Navigation & Device Hardware Fixes (Person C)

**Who:** vedantdadhich (Person C / App)

**What was done:**
- Fixed splash screen freeze: Converted `_SplashScreen` in `app/lib/core/router/app_router.dart` to a `ConsumerStatefulWidget` with managed `Timer` lifecycle (`dispose()` cancellation), cleanly routing to `/login` or role-based landing screens after 1.5s.
- Fixed ARM Mali GPU rendering freeze on physical device (MediaTek Dimensity / Android 16) by disabling Impeller fallback (`io.flutter.embedding.android.EnableImpeller = false`) in `AndroidManifest.xml`.
- Added required Android permissions in `AndroidManifest.xml`: `INTERNET`, `RECORD_AUDIO`, `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`.
- Updated `test/widget_test.dart` to allow the splash timer to settle; `flutter test` passes (1/1 green).
- Ran `flutter analyze` — 0 errors.
- Verified milestone 1 readiness on `c/app` branch.

**Gotchas / notes for next session:**
- Wireless ADB transfers large debug APKs slowly (~5-8 mins over Wi-Fi). Recommended development loop: run locally on macOS (`flutter run -d macos --dart-define=USE_MOCKS=true`) or connect device via physical USB cable.
- Once launched with `flutter run`, use hot reload (`r`) or hot restart (`R`) in terminal instead of reinstalling APK.
- Next step: Checkpoint 1 (CP1) — merge backend/AI branches and flip `USE_MOCKS=false` for assessment triage.

---

## 2026-09-24 — Milestone 1: Flutter UI Implementation (Person C)

**Who:** vedantdadhich (Person C / App)

**What was done:**
- Built full M1 Flutter UI across all Milestone 1 screens:
  - `core/theme/app_theme.dart` — full design system (Deep Emerald #087F5B, Noto Sans via google_fonts, all Material 3 component themes, risk badge colors matching Reference §6)
  - `core/providers/auth_provider.dart` — mock auth state notifier (login, register, logout, role, doctor verification gate)
  - `core/services/mock_service.dart` — loads mock JSON assets, simulates assessment routing (emergency keyword/vitals detection), verified-only doctor filter
  - `core/router/app_router.dart` — wired all routes to real screens with auth redirect guards; no more placeholder stubs
  - `widgets/shared_widgets.dart` — RiskBadge, DisclaimerBanner, VerifiedBadge, SectionCard, LoadingOverlay, AppBottomNav
  - `features/auth/login_screen.dart` — role selector, form validation, login flow
  - `features/auth/register_screen.dart` — role selector, doctor warning banner, register flow  
  - `features/auth/patient_home_screen.dart` — emerald header, time-based greeting, text/voice CTA cards, quick actions
  - `features/symptom_intake/symptom_input_screens.dart` — SymptomTextInputScreen + SymptomVoiceInputScreen + StepIndicator (made public)
  - `features/symptom_intake/vitals_entry_screen.dart` — 6 vitals fields with inline validation, skip option
  - `features/assessment/assessment_result_screen.dart` — risk band card, possible conditions, mandatory DisclaimerBanner, doctor CTA
  - `features/assessment/emergency_screen.dart` — full-screen red, pulsing icon, 108 SOS button, PopScope confirmation, trigger explanation
  - `features/doctor_directory/doctor_list_screen.dart` — specialty filter chips, verified-only sort by distance; DoctorProfileScreen with Call/Email/Chat
  - `features/chat/chat_screen.dart` — mock chat with typing indicator
  - `features/doctor_dashboard/doctor_dashboard_screens.dart` — PatientQueueScreen, PatientDetailScreen, PendingVerificationScreen, ConsultationHistoryScreen
- Added `url_launcher` and `google_fonts` to pubspec.yaml
- Declared mock JSON files as Flutter assets
- Ran `flutter analyze` — **0 errors**, 42 info/style warnings only

**Gotchas / notes for next session:**
- `_MockPatient` in doctor_dashboard_screens is private; router passes null for `patient` param and the screen looks it up by id from the const list. Fix for M2: move to a proper repository pattern.
- `StepIndicator` was renamed from `_StepIndicator` to allow cross-file import.
- `withOpacity` deprecation warnings exist throughout; these are style-only and safe to defer to M2 (replace with `.withValues(alpha: ...)`).
- Chat WebSocket is mock-only (delayed reply); real WS wired at M2 by Person B/C.
- Google Maps (doctor map view) is a placeholder — wired at M2 after Maps key setup.
- To run: `flutter run -d <device-id> --dart-define=USE_MOCKS=true`

---

## 2026-09-23 — Milestone 0: Android Toolchain & Wireless Debugging Setup

**Who:** vedantdadhich (Person C / App)

**What was done:**
- Configured wireless ADB debugging between Mac and physical Android device (`A015`).
- Pre-cached Gradle 9.3.1 distribution to prevent Java URLConnection socket timeout during initial Gradle wrapper download.
- Completed one-time Android toolchain setup (NDK r28c, Android SDK platforms 35 & 36, CMake 3.22.1).
- Updated `file_picker` to `^10.3.10` in `app/pubspec.yaml` to ensure native compatibility with modern compileSdk 36 (resolving AAR metadata validation failures).
- Verified `assembleDebug` compiles cleanly (`build/app/outputs/apk/debug/app-debug.apk` generated, 156 MB).
- Freed RAM by terminating background Gradle/Kotlin compiler daemons after build.

**Gotchas / notes for next session:**
- Background `GradleDaemon` and `KotlinCompileDaemon` stay resident in memory after builds (standard Gradle behavior). If freeing memory is needed between long sessions, run `./gradlew --stop`.
- `file_picker` is now locked to modern 10.x compatible with Android SDK 36.
- To run on device with mocks: `flutter run -d <device-id> --dart-define=USE_MOCKS=true`.

---

## 2026-09-21 — Milestone 0: Repo & Scaffold Setup

**Who:** vedantdadhich (Person C / App) setting up the repo for all three tracks.

**What was done:**
- Created GitHub repo `shivanshmishra123/AarogyaMP_Chatbot`, initialized local git, pushed initial commit.
- Added `AAROGYAMP-REFERENCE.md`, `AAROGYAMP-WORKPLAN.md`, `AGENTS.md` at root.
- Created complete Milestone 0 folder structure:
  - `server/` — FastAPI backend scaffold (stubs only, no real logic)
  - `app/` — Flutter app scaffold (all features stubbed, mocks committed)
  - `server/tests/fixtures/personas.json` — 6 synthetic personas per Reference §16
  - `app/lib/mocks/` — mock assessment + doctor responses matching §11
  - `server/app/data/specialty_map.yaml` — from Reference §7
  - `server/app/data/emergency_rules.yaml` — shape only (NO thresholds, clinical sign-off needed before these are set)
- LLM provider chosen: **Groq** (`llama-3.3-70b-versatile`)
- STT: device-side (`speech_to_text` Flutter plugin)
- Maps: Google Maps Flutter

**Gotchas / notes for next session:**
- `emergency_rules.yaml` has placeholder rules but **NO real thresholds** — these must be authored/approved by a clinician per Reference §18 and AGENTS.md rule 4. Do NOT invent values.
- `schemas.py` is frozen per §6/§11 — do not add new fields without announcing + updating the Reference doc first.
- Person B (AI track) should start with `server/scripts/test_ai_engine.py` to validate Groq → §9 JSON schema round-trip before M1.
- Person C (app) should start on `app/lib/mocks/` and build all screens against mocks first.
- Real doctor data: only synthetic doctors are in `app/lib/mocks/mock_doctors.json` — never use the LLM to generate doctor contact info.

**Milestone 0 exit criteria status:**
- [ ] A's server boots and migrations apply
- [ ] B parses a real LLM JSON response for at least one persona
- [ ] C's app runs and can request mic permission successfully

---
