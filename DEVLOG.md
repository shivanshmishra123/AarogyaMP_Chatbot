# AarogyaMP — DEVLOG

> Newest entry at top. Each session's AI reads this before starting work.

---

## 2026-09-25 — Milestone 2: Backend Doctor Loop (Person A)

**Who:** Person A (Backend Core) on branch `shivansh`.

**What was done:**

### 1. Doctor Onboarding / Verification Flow (`server/app/routers/admin.py`)
Enhanced admin router with full onboarding lifecycle:
- `POST /api/admin/doctors/{id}/verify` — approve (idempotent, logs, no-ops if already verified)
- `POST /api/admin/doctors/{id}/reject` — reject with optional reason string (logged for audit)
- `POST /api/admin/doctors/{id}/reset` — revert verified/rejected → pending (for correcting mistakes)
- `GET  /api/admin/doctors/pending` — list all pending applications needing action
- `GET  /api/admin/doctors?verification_status=` — full list with optional status filter
- Consultation creation now enforces `verification_status == "verified"` — 403 returned for unverified doctors, defense-in-depth over client-side checks alone.

### 2. Push Notifications (`server/app/services/notifications.py`)
Implemented FCM Legacy HTTP API integration (fire-and-forget pattern):
- `send_new_message_notification(doctor_id, patient_name, preview)` — patient → doctor push
- `send_queue_notification(doctor_id, patient_name)` — new patient in queue → doctor push
- `send_doctor_responded_notification(patient_id, doctor_name, preview)` — doctor reply → patient push
- In-process FCM token store (`_doctor_fcm_tokens`, `_patient_fcm_tokens` dicts) mirrors DB-backed pattern for easy swap at M4
- All errors caught and logged; push failure never propagates up to break a chat message

### 3. Device Token Registration (`server/app/main.py`)
New endpoint `POST /api/devices/register` (JWT auth required, both roles):
- App calls this on login and when OS rotates FCM token
- Routes to `register_doctor_token` or `register_patient_token` based on JWT role

### 4. Cursor-based Chat Pagination (`server/app/routers/consultations.py`)
Rewrote `GET /api/consultations/{id}/messages` with proper cursor-based pagination:
- `?before=<message_id>` returns messages strictly older than that message (chronologically ordered)
- No cursor = most recent `limit` messages (chronological order)
- Implements the Reference §14 WebSocket reconnect pattern exactly: re-fetch since last known ID before resuming WS
- 400 returned on invalid/nonexistent cursor ID

### 5. Consultation Close (`server/app/routers/consultations.py`)
New `POST /api/consultations/{id}/close` (doctor-only):
- Sets `status = "closed"`, persists `ended_at` timestamp
- Closed consultations block WS reconnect (clients get `{"error": "consultation_closed"}` frame)
- Move-to-history flow on the app side can now be driven by this endpoint

### 6. WebSocket improvements
- Bidirectional push notifications (doctor reply → patient, patient message → doctor)
- Error frames sent back to client on invalid message format (instead of silent drop)
- Closed-consultation guard at WS connect time

**Tests: `server/tests/test_person_a_m2.py` — 18/18 PASSED**

```
server/tests/test_person_a_m2.py::test_admin_verify_doctor_success PASSED
server/tests/test_person_a_m2.py::test_admin_verify_idempotent PASSED
server/tests/test_person_a_m2.py::test_admin_reject_doctor PASSED
server/tests/test_person_a_m2.py::test_admin_reset_doctor PASSED
server/tests/test_person_a_m2.py::test_admin_list_pending PASSED
server/tests/test_person_a_m2.py::test_admin_bad_token_forbidden PASSED
server/tests/test_person_a_m2.py::test_admin_verify_nonexistent_doctor PASSED
server/tests/test_person_a_m2.py::test_consultation_blocked_for_unverified_doctor PASSED
server/tests/test_person_a_m2.py::test_consultation_allowed_for_verified_doctor PASSED
server/tests/test_person_a_m2.py::test_get_messages_empty PASSED
server/tests/test_person_a_m2.py::test_get_messages_limit PASSED
server/tests/test_person_a_m2.py::test_get_messages_cursor_pagination PASSED
server/tests/test_person_a_m2.py::test_get_messages_bad_cursor PASSED
server/tests/test_person_a_m2.py::test_close_consultation_as_doctor PASSED
server/tests/test_person_a_m2.py::test_close_consultation_as_patient_forbidden PASSED
server/tests/test_person_a_m2.py::test_register_device_token_patient PASSED
server/tests/test_person_a_m2.py::test_register_device_token_doctor PASSED
server/tests/test_person_a_m2.py::test_register_device_token_unauthenticated PASSED
==================== 18 passed in 12.85s =====================
```

**Gotchas / notes for next session:**
- FCM token store is in-process (lost on server restart). For M3/M4, add `fcm_token` column to `Doctor` and `Patient` models (or a separate `DeviceToken` table per session) and populate on `/api/devices/register`.
- The FCM Legacy HTTP API (`https://fcm.googleapis.com/fcm/send`) will be deprecated by Google — plan to migrate to FCM HTTP v1 API (uses service account JSON, not server key) at M4.
- `httpx` is already in `requirements.txt` — no new dependency added.
- `datetime.utcnow()` deprecation warnings exist (Python 3.14 prefers timezone-aware datetimes). Safe to defer to M3 hardening pass — functional impact is zero for now.
- Swagger UI at `http://localhost:8000/docs` shows all new endpoints under `Admin`, `Consultations`, and `Devices` tags.

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
