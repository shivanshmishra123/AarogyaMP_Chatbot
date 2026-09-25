# AarogyaMP — DEVLOG

> Newest entry at top. Each session's AI reads this before starting work.

---

## 2026-09-25 — Checkpoint 1: First Integration & Pipeline Verification (All Tracks)

**Who:** Person C (vedantdadhich) coordinating Checkpoint 1 integration

**What was done:**
- Merged all three Milestone 1 tracks into integration branch `checkpoint-1`:
  - Person A (`origin/shivansh`): DB models, JWT auth, doctor search, consultations, and WebSocket chat.
  - Person B (`origin/b/ai-clinical`): deterministic emergency rule engine, specialty mapper, and AI symptom engine.
  - Person C (`origin/c/app`): full 12+ Flutter screens, Riverpod auth/mock providers, and device fixes.
- Created `app/lib/core/services/assessment_service.dart` providing dual-mode assessment execution (`USE_MOCKS=true` for mock testing, `USE_MOCKS=false` for live HTTP `POST /api/assessments`).
- Connected `VitalsEntryScreen` in `app/lib/features/symptom_intake/vitals_entry_screen.dart` to `assessmentServiceProvider`.
- Wired `assessments.router` into `server/app/main.py`.
- Populated temporary developer emergency thresholds & keywords in `server/app/data/emergency_rules.yaml` per human user confirmation for testing:
  - SpO2 < 90%, Temp > 104°F, Heart rate > 130 bpm.
  - Keywords: "severe chest pain", "unconscious", "cannot breathe", "severe bleeding", "stroke".
- Configured local Python virtualenv with all requirements and `pyjwt`.
- Ran full test suite across the combined codebase:
  - `server/tests/test_emergency_rule_engine.py`: **9/9 passed** (including critical vitals & keyword triggers).
  - `server/tests/test_person_a_m1.py`: **7/7 passed** (auth, doctor search, admin verification, consultations, queue, chat).
  - `server/tests/test_specialty_mapper.py`: **13/13 passed** (exact, case-insensitive, and fallback mappings).
  - End-to-end integration test against `/api/assessments`:
    - Emergency vitals: triggered `EMG_VITALS_CRITICAL`, `ai_status="skipped"`.
    - Emergency keyword: triggered `EMG_KEYWORD_MATCH`, `ai_status="skipped"`.
    - Non-emergency: graceful fallback to `General Physician` with `ai_status="unavailable"` when no LLM key is configured.
  - Flutter test: `flutter test` **passed**, `flutter analyze` **0 errors**.

**Gotchas / notes for next session:**
- `DATABASE_URL=sqlite:///server/storage/test.db` is used for fast local testing; production uses Docker PostgreSQL.
- To run live AI engine against Groq, set `LLM_API_KEY` and `LLM_MODEL=llama-3.3-70b-versatile` in `server/.env`.
- To run app against live server:
  - Backend: `PYTHONPATH=server DATABASE_URL=sqlite:///server/storage/test.db uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload`
  - App: `flutter run -d macos --dart-define=USE_MOCKS=false --dart-define=API_BASE_URL=http://localhost:8000`

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

## 2026-09-24 — Milestone 1: AI & Clinical Logic Core Complete

**Who:** Person B (AI & Clinical Logic track)

**What was done:**
- Implemented `server/app/services/emergency_rule_engine.py`:
  - Deterministic evaluation of critical vitals, keywords, and combinations based on `emergency_rules.yaml`.
  - Runs in memory in < 0.5s; gracefully handles null thresholds/empty lists.
- Implemented `server/app/services/specialty_mapper.py`:
  - Reads `specialty_map.yaml` at module import.
  - Case-insensitive resolution against the 13 fixed specialties with `General Physician` fallback.
  - Added unit test suite `server/tests/test_specialty_mapper.py` (13/13 tests pass).
- Implemented `server/app/services/ai_symptom_engine.py`:
  - Assembles prompt from symptoms, duration, vitals, and fixed specialty list.
  - Enforces non-diagnostic clinical decision support framing.
  - Enforces frozen `LLMAssessmentOutput` schema, markdown stripping, retry on parse failure, and graceful degradation (`ai_status="unavailable"`).
  - Tested live against Groq endpoint (`openai/gpt-oss-120b`) for `persona_low`, `persona_moderate`, and `persona_high` — all passed schema validation.
- Implemented `server/app/routers/assessments.py`:
  - Orchestrates Stages 1-6 of the assessment pipeline (`POST /api/assessments`).
  - Short-circuits immediately on emergency (`is_emergency=True`, `ai_status="skipped"`).
- Implemented `server/scripts/test_ai_engine.py` for standalone persona evaluation with UTF-8 support.

**Gotchas / notes for next session:**
- Person B's Milestone 1 exit criteria are met: pipeline logic, schemas, and live LLM integration are verified.
- Next integration step is Checkpoint 1 (CP1) once Person A's DB/auth core is ready to persist assessment records.

---

## 2026-09-23 — Milestone 1: Backend Core Implementation

**Who:** Person A (Backend Core) on branch `shivansh`.

**What was done:**
- Created and checked out track branch `shivansh`.
- Added `server/.env` and updated `server/app/config.py` and `database.py` with multi-environment support (local SQLite for fast standalone testing & migrations, PostgreSQL for Docker production).
- Created `server/scripts/seed_doctors.py` to seed synthetic doctors from `app/lib/mocks/mock_doctors.json` into the DB.
- Implemented `server/app/auth.py`:
  - Direct `bcrypt` password hashing (`hash_password`, `verify_password`).
  - PyJWT token generation (`create_access_token`, `create_refresh_token`, `verify_token`).
  - Dependency guards: `get_current_user`, `require_patient`, `require_doctor`.
- Implemented `server/app/routers/auth.py`:
  - `POST /api/auth/register` (handles patient and doctor registration).
  - `POST /api/auth/login` (authenticates via phone + password, issues JWT tokens).
- Implemented `server/app/services/doctor_search.py` and `server/app/routers/doctors.py`:
  - Haversine distance calculation in kilometers.
  - Server-side filter ensuring only `verification_status == "verified"` doctors are returned.
  - Distance, radius, and specialty filtering (`GET /api/doctors`).
- Implemented `server/app/routers/admin.py`:
  - `POST /api/admin/doctors/{doctor_id}/verify` gated by `X-Admin-Ops-Token`.
- Implemented `server/app/routers/consultations.py`:
  - `POST /api/consultations` (starts consultations).
  - `GET /api/consultations/{id}/messages` (paginated chat message history).
  - `GET /api/doctor/queue` (doctor dashboard patient queue with linked symptom report and AI assessment data).
  - `WS /ws/chat/{consultation_id}` (bidirectional WebSocket chat with room management, JWT auth, and `ChatMessage` DB persistence).
- Updated `server/app/main.py` with lifespan table creation and router mounting.
- Added comprehensive automated test suite `server/tests/test_person_a_m1.py`:
  - Ran `pytest server/tests/test_person_a_m1.py -v` — all 7 tests PASSED.

**Gotchas / notes for next session:**
- Python 3.14 + bcrypt 5.x has a known compatibility bug with `passlib`'s backend detector; direct `bcrypt` hashing is used in `auth.py` and `seed_doctors.py`.
- WebSocket chat endpoint is exposed at `/ws/chat/{consultation_id}` (and `/api/ws/chat/{consultation_id}` for convenience); clients pass `?token=<access_token>` in the query string or send an initial auth frame.
- Person B's assessments router (`/api/assessments`) can now seamlessly link consultations via `symptom_report_id`.

**Milestone 1 Person A exit criteria status:**
- [x] Auth: register/login, JWT issue/verify, role-based route guards (patient vs doctor)
- [x] Doctor search: GET /api/doctors with specialty/distance/verified filters against seeded synthetic doctor data
- [x] Consultation creation + WebSocket chat (/ws/chat/{consultation_id}), persisted ChatMessage rows
- [x] GET /api/doctor/queue for the doctor dashboard

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

---
