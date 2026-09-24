# AarogyaMP — DEVLOG

> Newest entry at top. Each session's AI reads this before starting work.

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
- `emergency_rules.yaml` thresholds remain placeholders pending clinical sign-off per Reference §18 / AGENTS.md rule 4. 2 unit tests in `test_emergency_rule_engine.py` will pass once approved values are populated.
- Person B's Milestone 1 exit criteria are met: pipeline logic, schemas, and live LLM integration are verified.
- Next integration step is Checkpoint 1 (CP1) once Person A's DB/auth core is ready to persist assessment records.

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
