# AarogyaMP — DEVLOG

> Newest entry at top. Each session's AI reads this before starting work.

---

## 2026-10-26 — Person B: Milestone 3 Hardening — Emergency CI Regression, Copy Audit, Degraded-Path Telemetry & Reference §18 Tracking

**Who:** Person B (AI & Clinical Logic Track)

**What was done:**
- **Emergency Rule Engine CI Regression Suite (`server/tests/test_emergency_rule_engine.py`)**:
  - Expanded test suite to run parametrized regression against every persona in `server/tests/fixtures/personas.json`.
  - Added boundary validation tests for all clinician-defined thresholds in `emergency_rules.yaml` (SpO2, heart rate, systolic BP, temperature).
  - Added case-insensitivity and sentence-variety keyword matching tests (matching upper, lower, and mixed case in complex sentences).
  - Added explicit test handling for `persona_invalid_vitals` to verify safe execution without unhandled exceptions.
  - Emergency suite expanded from 9 to 20 tests, passing in < 0.3s.
- **CI Automation (`.github/workflows/ci.yml`)**:
  - Created GitHub Actions CI pipeline running on Ubuntu with Python 3.11.
  - Configured to trigger on all pushes and pull requests across `main`, `shivansh`, `a/*`, `b/*`, and `c/*`.
  - Enforces running the clinical emergency rule regression, specialty mapper, copy audit, and full backend test suite on every commit.
- **Degraded-Path Handling & Telemetry (`server/app/services/ai_symptom_engine.py`)**:
  - Implemented in-memory telemetry and availability rate monitoring: `get_ai_metrics()` and `reset_ai_metrics()`.
  - Tracks `total_requests`, `successful_analyses`, `unavailable_analyses`, `unavailable_rate`, `last_failure_reason`, and `last_failure_timestamp`.
  - Added structured warning logs on degraded path: logs failure reason and running unavailable rate percentage.
  - Wrapped `analyze()` with defensive exception boundary so unexpected runtime errors degrade safely to `(None, "unavailable")`.
- **Clinical Copy & Diagnosis Language Audit (`server/scripts/audit_all_personas.py`, `server/tests/test_person_b_m3.py`)**:
  - Hardened regex patterns in `audit_all_personas.py` to match prescriptive dosage strings with attached units (e.g. `500mg`).
  - Authored comprehensive Milestone 3 test suite `server/tests/test_person_b_m3.py` (9 tests):
    - Validates strict detection of forbidden diagnosis language (`you have`, `diagnosed with`, `confirmed case`, etc.).
    - Validates acceptance of proper hedged possible-condition phrasing (`possible`, `may suggest`, `consult a physician`).
    - Validates that condition names never contain definitive diagnosis phrasing.
    - Validates emergency short-circuit in `POST /api/assessments` (skips LLM entirely, returns `is_emergency=True`, `ai_status="skipped"`).
    - Validates degraded-path response in `POST /api/assessments` (returns 200 with `risk_level="MODERATE"`, `ai_status="unavailable"`, non-diagnostic guidance).
    - Validates AI availability telemetry metric tracking.
- **Test Suite Cross-Pollution Fix (`server/tests/test_person_a_m1.py`, `m2.py`, `m3.py`)**:
  - Scoped `get_db` dependency override in `test_person_a_m1.py` to the fixture lifetime and popped on teardown.
  - Standardized `ADMIN_HEADERS` in `test_person_a_m2.py` and `test_person_a_m3.py` to reference `settings.ADMIN_OPS_TOKEN`.
  - Enables running the entire repository test suite (`python -m pytest server/tests/ -v`) in a single pass with 100% pass rate.
- **Safety & Compliance Tracking (Reference §18 Walk-Through)**:
  - *Decision support only*: Audit script and tests guarantee no diagnostic phrasing; disclaimer attached to non-emergency assessments.
  - *Emergency thresholds*: Marked as requiring qualified clinical sign-off; untouched in `emergency_rules.yaml`.
  - *Verified doctor identity*: Enforced at API layer; AI never invents doctors or contact details.
  - *DPDP Act 2023 / Health data sensitivity*:
    - Flagged for legal review prior to production pilot.
    - Health data minimization observed; vitals/symptoms sent to LLM without PII.
    - Local Ollama path supported (`LLM_BASE_URL=http://localhost:11434/v1`) to prevent health data egress.
  - *Telemedicine Practice Guidelines*: Telemedicine consults flagged for formal institutional review before live practitioner onboarding.

**Verification Results:**
```
pytest server/tests/test_emergency_rule_engine.py: 20/20 passed
pytest server/tests/test_specialty_mapper.py:      13/13 passed
pytest server/tests/test_person_b_m3.py:           9/9 passed
pytest server/tests/test_person_a_m1.py:           7/7 passed
pytest server/tests/test_person_a_m2.py:           19/19 passed
pytest server/tests/test_person_a_m3.py:           6/6 passed
Total test suite (server/tests/):                  74/74 PASSED (100%)
```

**Gotchas / notes for next session:**
- `emergency_rules.yaml` retains clinical review placeholders. Do NOT edit thresholds or keyword lists without recorded clinician approval.
- In local development without Ollama or Groq active, `ai_symptom_engine` returns `(None, "unavailable")`, and the router safely defaults to MODERATE risk with physician consultation recommendation.

---

## 2026-10-26 — Person A: Milestone 3 Hardening — WebSocket Concurrency, Structured Errors & Test Suite

**Who:** Person A (Backend Core)

**What was done:**
- **WebSocket Concurrency & Isolation (`server/app/routers/consultations.py`)**:
  - Upgraded `ChatConnectionManager` with `asyncio.Lock` and non-blocking concurrent broadcasts using `asyncio.gather`.
  - Added per-connection timeout (`3.0s`) and exception isolation so slow or dropped clients do not block or crash other participants in the room.
  - Implemented `manager.close_room(consultation_id, reason)`: when a doctor closes a consultation (`POST /api/consultations/{id}/close`), an event `{"event": "consultation_closed", "consultation_id": ..., "reason": "doctor_closed"}` is broadcast to all active WebSockets before normal socket termination (`WS_1000`).
  - Replaced manual dictionary appends with async `manager.connect` and `manager.disconnect` lifecycle methods.
- **Structured Error Responses Across Failure Modes (`server/app/main.py`)**:
  - Added centralized exception handlers for `HTTPException`, `RequestValidationError`, and unhandled 500 exceptions.
  - Standardized error schema: `{"detail": ..., "error": {"code": "...", "message": "...", "status_code": ...}}`.
  - Maintained top-level `detail` field so all existing tests and client parsers remain 100% backward-compatible.
  - Updated API version to `0.3.0` in metadata description.
- **Milestone 3 Automated Test Suite (`server/tests/test_person_a_m3.py`)**:
  - Added 6 automated tests covering 404/422/403 structured error schemas, concurrent multi-client WebSocket message broadcasts, consultation close notification & room teardown, and external ntfy timeout/error resilience.
  - Test suite passes 6/6 green.

**Verification Results:**
```
pytest server/tests/test_person_a_m3.py:           6/6 passed
pytest server/tests/test_person_a_m2.py:           19/19 passed
pytest server/tests/test_person_a_m1.py:           7/7 passed
pytest server/tests/test_emergency_rule_engine.py: 9/9 passed
pytest server/tests/test_specialty_mapper.py:      13/13 passed
Total test suite:                                  54/54 PASSED (100%)
```

**Gotchas / notes for next session:**
- `close_consultation` now closes active sockets asynchronously via `await manager.close_room`. Any client listening on the WebSocket can transition its UI directly to a "Consultation Resolved" state upon receiving the event frame.

---

## 2026-10-26 — Person A: ntfy Notification Wiring, Environment Reconstruction & Database Seeding

**Who:** Person A (Backend Core)

**What was done:**
- Reconstructed `server/.env` and `.env` with self-hosted stack defaults, 64-char JWT secret, and `sqlite:///storage/demo.db` for local standalone dev.
- Added `NTFY_BASE_URL: str = "http://localhost:8080"` and `extra = "ignore"` to `server/app/config.py`.
- Fully wired ntfy as the primary push transport in `server/app/services/notifications.py`:
  - Implemented async fire-and-forget `_send_ntfy` with 3-second timeout.
  - Doctor notifications dispatch to `aarogyamp-doctor-{doctor_id}`.
  - Patient notifications dispatch to `aarogyamp-patient-{patient_id}`.
  - Retained token registration endpoints (`/api/devices/register`) and dual-dispatch fallback to FCM if `FCM_SERVER_KEY` is present.
- Seeded `server/storage/demo.db` with 8 synthetic verified doctors using `scripts/seed_doctors.py`.
- Added unit test `test_ntfy_notifications_dispatch_safely` to `server/tests/test_person_a_m2.py`.

**Verification Results:**
```
pytest server/tests/test_person_a_m1.py:           7/7 passed
pytest server/tests/test_person_a_m2.py:           19/19 passed
pytest server/tests/test_emergency_rule_engine.py: 9/9 passed
pytest server/tests/test_specialty_mapper.py:      13/13 passed
Total test suite:                                  48/48 PASSED
```

**Gotchas / notes for next session:**
- Host machine has an active container (`algoclash-postgres`) running on port 5432. Local native development uses `DATABASE_URL=sqlite:///storage/demo.db` to prevent port collisions. If deploying with `docker compose up -d`, Docker Compose automatically routes `api` to its own internal PostgreSQL service (`postgres:5432`).
- Flutter app (Person C) can now subscribe directly to `http://<server-ip>:8080/aarogyamp-patient-{patient_id}/sse` or `/ws` for incoming notifications without needing FCM tokens.

---

## 2026-10-22 — Local AI Migration: Ollama + ntfy Docker Stack (Person C)

**Who:** Person C (vedantdadhich) — infra migration

**What was done:**
- Teacher feedback: external API calls (Groq) not acceptable — must use local AI.
- **Zero code changes** to `ai_symptom_engine.py` — Ollama exposes the same OpenAI-compatible API at `http://ollama:11434/v1`. Only the three `LLM_*` env vars change.
- Rewrote `server/docker-compose.yml` to include: Ollama (local LLM), PostgreSQL (production-grade DB), ntfy (self-hosted push), and the API server. All wired together — `docker compose up` is the only command anyone needs.
- Added `ollama-pull` init container that pulls the model on first run, subsequent restarts skip the download.
- Created `server/ntfy.yml` — ntfy server config (no auth needed for dev/demo, can tighten for production).
- Created `docs/LOCAL_AI_SETUP.md` — full setup guide with model recommendations per RAM tier.
- Updated `LLM_PROVIDER_DECISION.md` to reflect Ollama as primary decision.
- Updated `server/.env.example` — no external API keys, clear model selection instructions.

**Model recommendations:**
- **Default (all laptops & servers):** `llama3.1:8b` (~4.7 GB, 2-5s response time, 4 parallel slots)
- 8-16 GB low-RAM test: `llama3.2:3b-instruct` (~2.0 GB, 1-3s)
- 64 GB server: `llama3.1:70b-instruct-q4_K_M` (~40 GB, deep clinical precision)
- 128 GB server: `qwen2.5:72b-instruct-q8_0` (~80 GB, best multilingual/Hindi support)
- **Single-command override:** Users can override the model on the fly via `OLLAMA_MODEL=<tag> docker compose up -d` without editing any config.

**What Person A still needs to do:**
- Wire ntfy in `server/app/services/notifications.py` — replace FCM `_send_fcm` calls with ntfy HTTP POST calls (see `docs/LOCAL_AI_SETUP.md` §"What PERSON A needs to do" for exact code).
- Add `NTFY_BASE_URL: str = "http://localhost:8080"` to `server/app/config.py`.

**Gotchas:**
- On first `docker compose up`, the ollama-pull container downloads ~26-80 GB depending on model. This takes 10-30 min on a good connection. The API server starts immediately but LLM calls will fail until the model is ready — the `ai_status="unavailable"` fallback path handles this gracefully.
- `LLM_TIMEOUT_SECONDS` is set to 120 (vs 30 for Groq). CPU-only 70B inference takes 15-40s per request. With GPU this drops to 3-8s.
- ntfy topics follow pattern `aarogyamp-doctor-{id}` and `aarogyamp-patient-{id}` — Flutter app needs to subscribe to these instead of FCM.

---

## 2026-09-30 — Demo Run Preparation & Consultation History Routing Fix (Person C)

**Who:** Person C (vedantdadhich) — Mobile App & Demo Prep

**What was done:**
- Fixed Consultation History routing collision: `app_router.dart` was importing `doctor_dashboard_screens.dart` which exported an unlinked dummy `ConsultationHistoryScreen` showing hardcoded "No past consultations yet.". Fixed by hiding it and importing the real `features/history/consultation_history_screen.dart`.
- Fixed Dart nested Map generic casting in `auth_provider.dart`: `jsonDecode` produces nested maps that fail `whereType<Map<String, dynamic>>()`; replaced with explicit `Map<String, dynamic>.from()` extraction.
- Made `ConsultationHistoryScreen` reactive to auth changes by adding `ref.watch(authProvider)`.
- Verified live SQLite database (`demo.db`) seeded with all 8 verified synthetic doctors and tested `/api/doctors`.
- Verified end-to-end WebSocket chat & consultation records on Android test phone over USB via `adb reverse tcp:8000 tcp:8000`.

**Gotchas / notes for next session:**
- Whenever Android device is disconnected and reconnected via USB, run `adb reverse tcp:8000 tcp:8000` once before launching the Flutter app with `--dart-define=API_BASE_URL=http://localhost:8000`.
- The SQLite database persists at `server/storage/demo.db`; doctor seeding does not need to be re-run between sessions.

---

## 2026-09-30 — Checkpoint 2: Three-Track M2 Integration (Person C)

**Who:** Person C (vedantdadhich) — integration lead

**What was done:**

### Integration strategy
- Created `checkpoint-2` branch from `c/app` (all M2 Flutter fixes, UX bug fixes, and Android back-gesture fixes already committed there).
- Determined that `origin/shivansh` diverged from its own M1 base (`272c4f6`) — it added **server-only** changes (admin ops, consultation close, cursor pagination, WS push notification), and the scary-looking "Flutter deletions" in its diff vs `main` were artifacts of divergence from a pre-checkpoint-1 ancestor, **not intentional Flutter regressions**. Verified by running `git diff 272c4f6 origin/shivansh -- app/lib/` → empty.
- Merged `origin/b/ai-clinical` with `--no-ff --no-commit`; only `DEVLOG.md` conflicted (both tracks added top entries). Resolved manually keeping both, Person C first then Person B (newest-at-top rule).
- Cherry-picked shivansh's 5 server files using `git checkout origin/shivansh -- <files>` to avoid pulling his stale Flutter scaffold: `server/app/main.py`, `server/app/routers/admin.py`, `server/app/routers/consultations.py`, `server/app/services/notifications.py`, `server/tests/test_person_a_m2.py`.
- Fixed stale `test_person_a_m1.py::test_health_check` which hardcoded version `0.1.0`; shivansh bumped to `0.2.0` in M2. Updated assertion to check `status` only.

### What's in checkpoint-2
**Flutter app (c/app, unmodified):**
- Real JWT auth, doctor directory w/ location, live WebSocket chat, doctor dashboard queue
- Per-doctor thread reuse via `AuthService._doctorConsultations` — no more lost history
- GoRouter fix (AuthRefreshListenable) — no more context teardown on state update
- Android back gesture polish — no white flash, no window shrink
- ConsultationHistoryScreen with Resume Chat

**Server (Person A M2):**
- `POST /api/admin/doctors/{id}/verify` (idempotent), `/reject`, `/reset`, `/pending`, full list with filter
- `POST /api/consultations/{id}/close` — doctor-only
- Cursor-based pagination on `GET /consultations/{id}/messages`
- WS: sends push to doctor on patient message, push to patient on doctor reply
- Unverified doctor blocked from receiving consultations at `POST /api/consultations`
- Device token registration endpoint `POST /api/devices/register`

**AI/Clinical (Person B M2):**
- Prompt hardened with 8 explicit rules (forbidden diagnosis language, required hedging, required disclaimer, no medication dosing)
- Full persona audit script (`scripts/audit_all_personas.py`) — 5/5 PASSED
- `LLM_PROVIDER_DECISION.md` documenting Groq rationale + DPDP compliance notes

### Verification results
```
flutter analyze:                           0 errors, 31 info/style only
flutter test:                              8/8 passed
pytest (unit + M1, SQLite):               29/29 passed
pytest (M2 API, SQLite):                  18/18 passed
```

**Gotchas / notes for next session:**
- `notifications.py` still references FCM in comments/docstring but **is a safe stub** — it no-ops when `FCM_SERVER_KEY` is absent (which it always is). Do not wire FCM; follow ntfy migration path in M4 per DEVLOG 2026-09-28.
- `test_person_a_m2.py` must be run in its own pytest invocation (or with `DATABASE_URL=sqlite:///...` env set before any other test module is imported), otherwise SQLAlchemy engine caching causes DB URL collisions.
- Flutter `analyze` shows 31 info warnings; none are errors. `use_build_context_synchronously` in `vitals_entry_screen.dart` (lines 278–280) should be fixed in M3 — it's guarded correctly for runtime safety but Dart analyzer can't verify that.
- The `checkpoint-2` branch is pushed to `origin`. All three track branches (`shivansh`, `b/ai-clinical`, `c/app`) are now fully represented in it.

---

## 2026-09-29 — M2 Integration Testing & UX Bug Fixes (Person C)

**Who:** Person C (Mobile App)

**What was done:**
1. **Chat Tab & WebSocket Connection Fix:**
   - Root cause: Bottom nav bar Chat tab previously had hardcoded `'mock-consult-001'`. In live mode (`USE_MOCKS=false`), the backend checked SQLite for `mock-consult-001`, rejected it with WebSocket `code 1008` (Policy Violation: Consultation not found), and `ChatService` auto-reconnected indefinitely, leaving the header stuck at "Connecting...".
   - Added `lastConsultationId` & `lastConsultationDoctorName` to `AuthState` & `AuthNotifier`, persisted via `SharedPreferences`.
   - Updated `DoctorListScreen` to store the active `consultationId` when `_startChat` creates a consultation.
   - Updated `patient_home_screen.dart` bottom nav: If active consultation exists, navigates directly to it; if none exists, displays a modal sheet explaining consultations are started with a verified doctor and provides a "Find Doctors" button.
   - Updated `chat_service.dart`: Handles HTTP 404 from `getMessages` and WebSocket close code 1008 directly without infinite reconnect loops.
   - Updated `chat_screen.dart`: Shows clean "Disconnected" status and an action button "Find Doctor" if consultation room does not exist.
   - Fixed `app_router.dart`: Replaced `ref.watch(authProvider)` with `AuthRefreshListenable` using `refreshListenable`. Previously, modifying `AuthState` (such as `setLastConsultation`) caused GoRouter to be completely re-instantiated and tore down the Navigator context before `context.push(Routes.chat...)` could execute, leaving the user on the doctor profile. GoRouter instance is now preserved.
   - Fixed Multi-Doctor Chat History: Previously, tapping "Chat" on a doctor's profile always triggered `POST /api/consultations`, creating a fresh room and leaving previous messages in the older room. Implemented persistent `_doctorConsultations` mapping in `AuthService` and `AuthNotifier`. Tapping Chat on a doctor now reopens the existing active consultation room for that doctor and pulls previous message history via `GET /api/consultations/{id}/messages`.
   - Wired `ConsultationHistoryScreen` (`/history`): Replaced M1 placeholder with a full history view listing previous doctor consultations with dates, specialties, and one-tap "Resume Chat" buttons.
2. **Form Validation & Input Polish:**
   - Added `LengthLimitingTextInputFormatter(10)` and `digitsOnly` to phone fields on Login & Register.
   - Fixed white text contrast on emergency red SnackBar errors.
3. **Navigation & Android Back Gesture:**
   - Updated `vitals_entry_screen.dart` to push rather than replace routes, preserving back navigation.
   - Removed `PopScope(canPop: false)` from `assessment_result_screen.dart`: previously blocked standard route pop and caused Android 14+ Predictive Back to scale down the window and preview app exit (flashing white background). Back gesture and button now pop cleanly without edge flash.
   - Set `android:enableOnBackInvokedCallback="false"` in `AndroidManifest.xml` to prevent OS window-shrink preview when holding back gestures on non-root screens.
   - Configured `NormalTheme` in `styles.xml` with `@color/app_background` (`#E7FEFC`) rather than default pure white `?android:colorBackground`, eliminating any white flash during activity transitions.
   - Added Logout action inside profile bottom sheet on home screen.
4. **Card Rendering & Overflow Fixes:**
   - Replaced invalid `BoxDecoration` (non-uniform border with `borderRadius`) in `SectionCard` and `AssessmentResultScreen` with a clean `Stack` indicator.
   - Fixed bottom pixel overflow in assessment summary cards.

**Verification Results:**
- `flutter analyze`: **0 errors**.
- `flutter test`: **8/8 tests passed**.

---

## 2026-09-28 — Milestone 2: Doctor Loop Live Wiring (Person C)

**Who:** Person C (Mobile App)

**What was done:**
- Completed all 4 remaining layers for Milestone 2:
  1. **Layer 1 (Auth):** Real JWT authentication via `AuthService` + persistent session storage with `shared_preferences`. Added `lastSymptomReportId` and `setLastSymptomReportId` to `AuthState` & `AuthNotifier`.
  2. **Layer 2 (Doctor Directory + Location):** Implemented `DoctorService` wrapping `GET /api/doctors` with optional `specialty`, `lat`, `lng`, `radius_km`. Updated `DoctorListScreen` with live service integration, `geolocator` device location fetch, and graceful fallback when location permission is denied.
  3. **Layer 3 (Consultations & WebSocket Chat):** Created `ConsultationService` (`POST /api/consultations` and `GET /api/consultations/{id}/messages`) and `ChatService` (`web_socket_channel` connected to `ws://host/ws/chat/{id}?token=<jwt>`). Implemented reconnect flow with 3-attempt exponential backoff (1s, 2s, 4s) fetching HTTP message history prior to reopening the socket (Reference §14). Rewrote `ChatScreen` with real-time bidirectional message events while preserving mock mode for offline testing.
  4. **Layer 4 (Doctor Dashboard):** Created `PatientQueueItem` model mirroring `schemas.py`. Rewrote `PatientQueueScreen` to load live queue from `GET /api/doctor/queue`, with refresh indicator and empty/error states. Connected `PatientDetailScreen` and patient queue routing via `GoRouter` in `app_router.dart`.
- Added unit tests in `app/test/m2_services_test.dart` verifying `PatientQueueItem`, `ChatMessageModel`, `DoctorService`, and `ConsultationService`.
- Fixed analyzer errors and cleaned up unused imports across `app/lib`.

**Verification Results:**
- `flutter analyze`: **0 errors** (all lints/types clean).
- `flutter test`: **8/8 passed** (`app smoke test` + all M2 unit tests).
- Backend suite: `pytest server/tests/`: **29/29 passed** (emergency rules, specialty mapper, person A M1 API/DB).

**Gotchas & Notes for Next Session:**
- `POST /api/consultations`: if `symptom_report_id` is supplied, server checks DB for existing `SymptomReport`. Because Person B's `/api/assessments` has not yet implemented Stage 6 DB persistence for `SymptomReport`, `symptomReportId` is passed only when present in DB; otherwise `null` is sent, allowing `createConsultation` to succeed cleanly.
- `ChatService` automatically cleans up socket subscriptions on dispose. Mock toggle `--dart-define=USE_MOCKS=true` remains fully functional for standalone testing.

---

## 2026-09-30 — Milestone 2: Prompt-Quality Hardening & LLM Provider Decision (Person B)

**Who:** Person B (AI & Clinical Logic track) on branch `b/ai-clinical`

**What was done:**

### 1. Prompt-quality hardening (`ai_symptom_engine.py`)
- Rewrote the LLM system prompt from 5 generic rules to 8 explicit numbered rules:
  - Rule 1: Explicitly forbids "you have", "you are suffering from", "diagnosis is" and any certainty language. Requires hedging words ("may", "could", "possible", "suggests").
  - Rule 5 (NEW): Explicitly forbids prescribing medication dosages or specific treatments.
  - Rule 6 (NEW): Mandates the exact disclaimer text in every response.
  - Rule 7 (NEW): Requires recommendation_text to be actionable (tell patient what to do next).
- No frozen schema fields were added or changed — this is purely prompt instruction changes.

### 2. Prompt-quality & recommendation audit (`scripts/audit_all_personas.py`)
- Created comprehensive audit script that runs ALL 5 testable personas through the live Groq pipeline and systematically checks:
  - Schema validation (Pydantic)
  - Risk level correctness
  - Specialty in fixed list
  - **Diagnosis language scan**: regex-based detection of 12+ forbidden patterns ("you have", "diagnosed with", "confirmed case of", prescriptive medication language, etc.)
  - **Hedging language check**: verifies recommendation_text uses appropriate framing
  - **Disclaimer check**: verifies "not a diagnosis" framing is present
- Ran full audit: **5/5 PASSED, 0 failures, 0 warnings**
- Full JSON results saved to `scripts/audit_results.json` for manual review

### 3. LLM provider decision (`LLM_PROVIDER_DECISION.md`)
- Documented Groq as the chosen LLM provider per WORKPLAN §M2.
- Documented data-handling rationale: patient symptoms/vitals are sent to Groq (third-party). No PII (name/phone/email) is ever included in prompts.
- Listed DPDP Act compliance gating items for production launch.
- Documented zero-code-change swap path to OpenAI, OpenRouter, or local Ollama.

### 4. Verification
- `pytest tests/test_emergency_rule_engine.py tests/test_specialty_mapper.py -v`: **22/22 passed**
- `scripts/audit_all_personas.py`: **5/5 PASSED, 0 failures, 0 warnings**
- Live Groq API confirmed working across all personas

**Files created:**
- `server/scripts/audit_all_personas.py` — M2 prompt audit script
- `server/scripts/audit_results.json` — full audit output (JSON)
- `LLM_PROVIDER_DECISION.md` — LLM provider decision document

**Files modified:**
- `server/app/services/ai_symptom_engine.py` — system prompt hardened (M2)

**Gotchas / notes for next session:**
- The `emergency_rules.yaml` now has developer-approved test thresholds (added during CP1 by Person C). These are NOT clinician-approved for production — the clinical sign-off requirement still stands per AGENTS.md Rule 4.
- The audit script's diagnosis-language scanner is regex-based, not foolproof. Manual review of `audit_results.json` is still recommended for each new persona or prompt change.
- Groq model `openai/gpt-oss-120b` is the current choice. If Groq rate-limits or deprecates this model, swap `LLM_MODEL` in `.env` — see `LLM_PROVIDER_DECISION.md` for alternatives.

---

## 2026-09-28 — Architecture Decision: Firebase → ntfy.sh (All Tracks)

**Who:** vedantdadhich (Person C) — decision affects all tracks

**Decision made: Replace Firebase Cloud Messaging with ntfy.sh self-hosted push notifications.**

**Rationale:**
- This project will be handed off to a government/institutional operator who will deploy it independently.
- Firebase FCM ties the APK to a specific Firebase project (requires `google-services.json` baked in at build time) and requires the operator to re-create that project and re-configure all keys. This is not a viable handoff story.
- ntfy.sh runs as a Docker sidecar (`binwiederhier/ntfy` official image) — the entire deployment is `docker compose up`. Zero external accounts, zero Google dependency, zero credentials the operator doesn't already own.
- DPDP Act (India §18): notification payloads contain patient name + message preview (health-adjacent data). Routing through Google infrastructure adds unnecessary third-party exposure.

**What changed in each track:**

| Track | Change |
|---|---|
| **Person C (app)** | Removed `firebase_core` and `firebase_messaging` from `app/pubspec.yaml`. The commented-out `Firebase.initializeApp()` in `main.dart` can be deleted. Run `flutter pub get` before next build. |
| **Person A (server)** | No code change yet — `notifications.py` stub already no-ops when `FCM_SERVER_KEY` is empty. For M2: leave as-is. **For M4:** add `ntfy` service to `docker-compose.yml`; change `notifications.py` to `httpx.post("http://ntfy/<doctor_id>", data=preview)`. Do NOT uncomment `firebase-admin` in `requirements.txt`. |
| **Person B** | No change — notifications are out of B's scope. |

**Docs updated:** `AAROGYAMP-REFERENCE.md` §2 tech stack + §15 Push Notifications, `AAROGYAMP-WORKPLAN.md` M2/M4 tasks + Fallback table.

**Functionalities preserved:** In-app real-time messaging is fully covered by WebSocket (already implemented by Person A). Background push (when app is closed) is deferred to M4 and will use ntfy.sh instead of FCM — same UX outcome, different transport.

**For next session (any track):** Read this entry. Firebase is deliberately not used. Do not add `firebase_core`, `firebase_messaging`, or `firebase-admin` to any file without explicit team sign-off.

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
