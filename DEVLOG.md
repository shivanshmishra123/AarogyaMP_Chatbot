# AarogyaMP — DEVLOG

> Newest entry at top. Each session's AI reads this before starting work.

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
