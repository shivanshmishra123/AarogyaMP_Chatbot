# AarogyaMP — Parallel Team Workplan

> Companion document to `AAROGYAMP-REFERENCE.md` (the full technical spec). That document says WHAT we're building; this one says WHO builds WHAT, IN WHAT ORDER, and HOW TO VERIFY each piece — designed so a small team (each possibly working with their own AI assistant) can build in one repo without stepping on each other, over an ongoing timeline rather than a single hackathon day.
>
> **Assumptions:** small team, no fixed deadline, iterating in milestones rather than hour-blocks. All architecture/API/schema decisions come from the Reference doc — do NOT redesign here.

---

## 0. Read This First: How We Parallelize One Repo

Working simultaneously in one repo is safe **only if file ownership is disjoint**. Our folder layout makes this almost automatic.

### File Ownership Map (STRICT)

| Folder/files | Owner | Nobody else touches |
|---|---|---|
| `server/app/main.py`, `config.py`, `database.py`, `models.py`, `auth.py`, `routers/auth.py`, `routers/doctors.py`, `routers/consultations.py`, `routers/admin.py`, `services/doctor_search.py`, `services/notifications.py`, `alembic/`, `Dockerfile`, `docker-compose.yml`, `requirements.txt` | **Person A** | — |
| `server/services/emergency_rule_engine.py`, `ai_symptom_engine.py`, `specialty_mapper.py`, `data/emergency_rules.yaml`, `data/specialty_map.yaml`, `routers/assessments.py`, `server/tests/` | **Person B** | — |
| `app/**` (entire Flutter codebase, both patient and doctor role screens) | **Person C** | — |
| `server/app/schemas.py` | **Person A**, but see Contract Freeze below | — |

### Contract Freeze (Milestone 0, non-negotiable)

The API request/response shapes and the LLM output schema in `AAROGYAMP-REFERENCE.md` §6, §9, §11 are **FROZEN at Milestone 0**. Everyone codes against those shapes immediately using committed fixture/mock files:

- **B never waits for A**: B develops `ai_symptom_engine.py` and `emergency_rule_engine.py` against a committed set of synthetic patient personas (`server/tests/fixtures/personas.json`, per §16 of the Reference doc), not against A's live auth/DB.
- **C never waits for A or B**: C develops the entire app against `app/lib/mocks/` (mock assessment responses, mock doctor directory, mock chat) matching §11 exactly. Mock toggle via a build flag (`--dart-define=USE_MOCKS=true`).

If anyone MUST change a frozen shape: announce it, update the Reference doc first, then code. Never silently drift.

### Git Discipline

```
main          ← always deployable/runnable; merged only at scheduled checkpoints
├── a/backend     ← Person A
├── b/ai-clinical ← Person B
├── c/app         ← Person C
```

- Commit to your personal branch regularly. Commit messages: `a: doctor search distance filter` style.
- Merge to `main` only at scheduled checkpoints (§3). Between checkpoints, `main` stays stable.
- Merge order at checkpoints: A first (backend is the dependency root), then B, then C. Resolve conflicts in YOUR OWN folder only.
- Any change to `emergency_rules.yaml` needs clinical sign-off noted in the commit message or linked review, per Reference §18 — this file does not get "quick fixed" like normal code.

### Working With Your AI (if teammates use different AI assistants)

Add an `AGENTS.md` to the repo root (already provided — see the companion file) containing:

```markdown
# Repo instructions
1. Before ANY work, read AAROGYAMP-REFERENCE.md (full spec) and AAROGYAMP-WORKPLAN.md (who owns what).
2. You are assisting ONE person. Only modify files listed under their ownership in AAROGYAMP-WORKPLAN.md §File Ownership Map. If a needed change falls outside, STOP and tell the human to coordinate.
3. API shapes and the LLM JSON schema are frozen per Reference doc §6, §9, §11. Do not invent new fields.
4. Never modify server/app/data/emergency_rules.yaml thresholds without an explicit human instruction that clinical sign-off has been obtained — flag this requirement rather than assuming it.
5. Do not add features listed in Reference doc §17 (out of scope) or state/imply a confirmed diagnosis anywhere in UI copy, prompts, or docs — see Reference §18.
6. After changes, run the verification command for that milestone from AAROGYAMP-WORKPLAN.md and paste results.
7. At the end of every session, add an entry to DEVLOG.md (newest at top) summarizing what was done, how, and any gotchas — the next person's AI reads it before starting.
```

Each milestone below ends with a **"Kickoff prompt"** you can paste into your AI assistant at the start of that milestone.

---

## 1. Personas & Tracks

| | Person A — Backend Core | Person B — AI & Clinical Logic | Person C — Mobile App |
|---|---|---|---|
| Language | Python | Python | Dart/Flutter |
| Owns | Auth, data model, doctor search, consultations + chat WS | Emergency rules, AI symptom engine, specialty mapping | Entire app, both patient and doctor roles |
| Deliverable | Login → doctor directory → chat all work against real DB | Assessment pipeline returns correct risk level + narrative, emergency path never touches the LLM | Full app flow, first on mocks then wired live |
| Needs from others | Nothing to start (works from spec) | Nothing to start (works from synthetic personas) | A's API live + B's assessment endpoint before final wiring milestone |

> Why B can start instantly: the AI/rules layer only needs (a) synthetic personas as input and (b) the frozen output schema. Fixtures are committed at Milestone 0 so B is never blocked by A's auth/DB work.

---

## 2. Milestone Roadmap

| Milestone | Theme | Ends with |
|---|---|---|
| M0 — Setup | Repo, branches, fixtures/mocks committed, contract freeze confirmed | Everyone can run their own slice against fixtures/mocks |
| M1 — Independent cores | A: auth + data model + doctor search work standalone. B: rule engine + AI engine return correct schema against synthetic personas. C: full app UI built against mocks | Each track demoable in isolation |
| ✅ CP1 — First integration | Real assessment submission → real risk level on a real (non-mocked) app screen | Patient can submit symptoms+vitals and see a real (not mocked) AI Assessment card |
| M2 — Doctor loop | Doctor directory (real data), doctor login/verification, call/email deep links, chat (WS) wired end-to-end | Patient can go from assessment → find a doctor → chat, live |
| ✅ CP2 — Full E2E | Both roles live: patient submits → sees assessment → contacts doctor → doctor sees queue + AI card → responds in chat | Full loop works with synthetic personas + synthetic doctor directory |
| M3 — Hardening & compliance pass | Timeouts/error paths, emergency-path regression tests green, disclaimer copy audited everywhere, data-handling review against Reference §18 | No confirmed-diagnosis language anywhere; emergency path tested against every synthetic emergency persona |
| M4 — Beta readiness | Deployed backend, TestFlight/internal-track build, real doctor onboarding process defined, clinical sign-off obtained on `emergency_rules.yaml` | Ready to onboard a small real pilot group |

There's no fixed hour budget — move to the next milestone when the previous one's exit criteria are met, not on a clock. Keep `main` releasable at every checkpoint even if features beyond it aren't built yet.

---

## 3. Milestone-by-Milestone Detail

### MILESTONE 0 — Setup

**ALL (together, first):**
- [ ] Create repo; add `AAROGYAMP-REFERENCE.md` + `AAROGYAMP-WORKPLAN.md` + `AGENTS.md` at root
- [ ] Create branch structure (`a/backend`, `b/ai-clinical`, `c/app`)
- [ ] Create `.gitignore`: `.env`, `**/build/`, `.dart_tool/`, `server/storage/`, `*.db`
- [ ] **Contract freeze announcement** — confirm everyone has read Reference §6, §9, §11
- [ ] Commit `server/tests/fixtures/personas.json` — at minimum: one LOW, one MODERATE, one HIGH, one EMERGENCY (vitals-triggered), one EMERGENCY (keyword-triggered), one invalid-vitals persona (per Reference §16)
- [ ] Commit `app/lib/mocks/` — mock assessment responses (one per persona above) + a mock doctor directory (5–10 synthetic verified doctors across specialties)

**Person A:**
- [x] Scaffold `server/app/` per Reference §4; database setup; `uvicorn app.main:app --reload` serves `GET /health`
- [x] `models.py` + table initialization for all tables in Reference §6

**Person B:**
- [ ] Get an LLM provider working end-to-end for a throwaway prompt (pick hosted or local per Reference §15 — this is a real decision to make now, not defer)
- [ ] Write a script that sends one persona through a draft prompt and demands the §9 JSON schema back, parsed with Pydantic
- [ ] Commit the script as `server/scripts/test_ai_engine.py`

**Person C:**
- [ ] Flutter project scaffold per Reference §4 folder layout; confirm `flutter run` works on a real device/emulator
- [ ] Build the mic permission + basic voice capture flow early — same rationale as APK Sentinel's "risk spike first": if `speech_to_text` integration is going to be painful, find out now, not late

**Milestone 0 exit criteria:** A's server boots and migrations apply · B parses a real LLM JSON response for at least one persona · C's app runs and can request mic permission successfully.

---

### MILESTONE 1 — Independent Cores

**Person A:**
- [x] Auth: register/login, JWT issue/verify, role-based route guards (patient vs doctor)
- [x] Doctor search: `GET /api/doctors` with specialty/distance/verified filters against seeded synthetic doctor data
- [x] Consultation creation + WebSocket chat (`/ws/chat/{consultation_id}`), persisted `ChatMessage` rows
- [x] `GET /api/doctor/queue` for the doctor dashboard

**Person B:**
- [ ] `emergency_rule_engine.py` against `emergency_rules.yaml` — deterministic, unit-tested against every persona in `personas.json`, especially the two emergency ones
- [ ] `ai_symptom_engine.py`: prompt assembly, JSON-mode or robust-parse fallback, retry-once-on-parse-failure, schema validation via Pydantic
- [ ] `specialty_mapper.py`: cross-checks LLM's specialty pick against `specialty_map.yaml`, falls back to General Physician
- [ ] `routers/assessments.py`: wires Stages 1–6 from Reference §8 together, runnable standalone against `personas.json` without needing A's DB/auth (use a lightweight in-memory or SQLite store for this milestone if useful, swap to real DB at integration)

**Person B verification (alone):**
```bash
python -m server.scripts.test_ai_engine --persona emergency_vitals
# PASS = is_emergency=true, ai_status="skipped", correct emergency_triggers, in well under 1s
python -m server.scripts.test_ai_engine --persona moderate_fever
# PASS = valid schema JSON, risk_level="MODERATE", recommended_specialty in the fixed list
```

**Person C:**
- [ ] Build every screen in Reference §12 against `app/lib/mocks/`, both patient and doctor roles
- [ ] Symptom text/voice input, vitals form with inline validation
- [ ] Assessment Result card (§10) and a separate, distinct Emergency screen — visually and structurally different, not the same widget with a red color swap
- [ ] Doctor directory (list + map) + doctor profile with Call/Email/Chat buttons (deep-link `tel:`/`mailto:`, chat opens a mocked thread)
- [ ] Doctor-role screens: queue + patient detail + chat

**Person C verification (alone):**
```bash
flutter run --dart-define=USE_MOCKS=true
# Click through: login (either role) → full patient flow → full doctor flow
# PASS = zero dead buttons, every persona's mock renders its correct risk level/UI variant
```

**Milestone 1 exit criteria:** A's auth+directory+chat work standalone against seeded data · B's pipeline returns correct output for every persona in under the target time · C's app is feature-complete on mocks for both roles.

---

### ✅ CHECKPOINT 1 — First Integration

**Merge order: A → B → C. Then run together:**
1. Start A's server (real DB) with B's `assessments.py` merged in
2. C flips `USE_MOCKS=false` for the assessment flow only (doctor directory/chat can stay mocked a bit longer if not ready)
3. Submit a real symptom+vitals report from the app → confirm the real (non-mocked) risk level and possible-conditions render correctly
4. Submit the emergency persona's inputs → confirm the emergency screen appears and the LLM was skipped (check `ai_status="skipped"` in the response/logs)

**Rules for this checkpoint:** timebox it. Bug found? Owner fixes solo on their branch; don't crowd one screen. If integration reveals a schema drift, fix the Reference doc first, then code — don't patch around a silent mismatch.

---

### MILESTONE 2 — Doctor Loop

**Person A:**
- [ ] Doctor onboarding/verification flow (even if `routers/admin.py` is just an ops-token-gated endpoint for now, per Reference §3)
- [ ] Push notifications: new chat message, new patient in doctor's queue (FCM)
- [ ] `GET /api/consultations/{id}/messages` pagination for reconnects and dashboard load

**Person B:**
- [ ] Prompt-quality pass using real (synthetic) end-to-end data flowing through A's real pipeline, not just the standalone fixture script
- [ ] Confirm `recommendation_text` phrasing is consistently actionable and never states a confirmed diagnosis — do a manual audit pass across all personas
- [ ] Decide and document final LLM provider choice (Reference §15) if not already locked in at M0

**Person C:**
- [ ] Kill assessment-flow mocks fully; wire doctor directory + consultations + WebSocket chat live
- [ ] Handle WebSocket reconnect (re-fetch messages since last known id before resuming socket, per Reference §14)
- [ ] Handle location-permission-denied gracefully (manual city/pincode fallback for doctor search)
- [ ] Doctor-side: live queue + patient detail pulling real AI assessment data

**Milestone 2 exit criteria:** a synthetic patient can go from symptom submission through to a live chat reply from a synthetic doctor account, entirely on real (non-mock) endpoints.

---

### ✅ CHECKPOINT 2 — Full E2E, Both Surfaces

1. Patient: submit MODERATE-risk persona → assessment card → find doctor → start chat → send text + one voice message
2. Doctor: log in → see the patient in queue with symptoms/vitals/AI assessment attached → reply in chat
3. Patient: submit an EMERGENCY persona → confirm full-screen emergency guidance, no possible-causes list, LLM skipped
4. Confirm an unverified doctor never appears in search results or profile screens

Same checkpoint discipline as CP1: fix solo, don't crowd, re-run both flows twice to confirm stability.

---

### MILESTONE 3 — Hardening & Compliance Pass

- [ ] **A:** timeouts on every external call (LLM, STT if server-side, FCM), concurrency handling on the WebSocket layer, structured error responses for all failure modes
- [ ] **B:** `test_emergency_rule_engine.py` runs in CI against every persona and must stay green; any future edit to `emergency_rules.yaml` requires this suite to pass plus the clinical sign-off note from §0
- [ ] **C:** full UI copy audit — confirm the disclaimer from Reference §10 renders on every non-emergency assessment, confirm no screen anywhere implies a confirmed diagnosis, empty/error/loading states everywhere
- [ ] **ALL:** walk through Reference §18 (Safety & Compliance Notes) line by line and note open items (legal review, DPDP Act compliance review, telemedicine guideline review) — these are real gating items before real patients use this, not just nice-to-haves

**Milestone 3 exit criteria:** emergency-path tests green in CI · disclaimer audit passed · open compliance items are tracked, not silently skipped.

---

### MILESTONE 4 — Beta Readiness

- [ ] **A:** deploy backend + Postgres (Docker Compose or a managed host), production env vars set, backups configured
- [ ] **C:** internal test track build (TestFlight / Play internal testing), crash reporting wired
- [ ] **B:** final LLM provider decision documented with the data-handling rationale (Reference §15/§18), monitoring for `ai_status="unavailable"` rate in production
- [ ] **ALL:** real doctor onboarding/verification process defined (who checks credentials, how `verification_status` actually gets flipped in production — not just the ops-token placeholder), clinical sign-off obtained and recorded for `emergency_rules.yaml`

---

## 4. Testing Cheat Sheet

| Layer | Command/artifact | PASS condition |
|---|---|---|
| B: emergency rules | `pytest server/tests/test_emergency_rule_engine.py` | Every emergency persona flagged; every non-emergency persona NOT flagged |
| B: AI engine | `python -m server.scripts.test_ai_engine --persona X` | Valid schema JSON, correct risk_level, specialty in fixed list, degraded path (`ai_status="unavailable"`) doesn't crash |
| A: API | integration script hitting each endpoint in Reference §11 | All expected status codes + shapes |
| C: app (mocks) | `flutter run --dart-define=USE_MOCKS=true` + click-through | Zero dead buttons/console errors, every persona renders correctly |
| C: app (live) | CP1/CP2 flows | Real assessment + chat flow matches expected persona behavior |
| Full loop | Every synthetic persona through the real pipeline, both roles | Correct risk level, correct emergency short-circuit, chat delivers both directions |

Golden rule: **continuous solo testing on your own track, scheduled group testing only at checkpoints.**

---

## 5. Fallback / Risk Decisions

| Risk | Trigger | Fallback |
|---|---|---|
| Chosen LLM provider unreliable/down | Any milestone | Swap `LLM_BASE_URL`/`LLM_MODEL` (config-only change per Reference §15); worst case ship with `ai_status="unavailable"` handling proven and demo the rule-based floor alone |
| On-device STT poor for regional languages | M0/M1 | Fall back to server-side Whisper (Reference §15) — flagged as a data-handling decision, not just a technical swap |
| Google Maps cost/ToS a blocker | Any milestone | Swap to an OSM-based stack; doctor search API shape (Reference §11) doesn't change |
| Real doctor onboarding lags behind engineering | M2+ | Keep demoing/testing against the synthetic doctor directory (Reference §16); never block engineering progress on real onboarding completing |
| Clinical sign-off on emergency rules delayed | M3/M4 | Do not ship emergency-rule changes without it — this is the one item allowed to block a release |

---

## 6. Kickoff Prompts (paste into your AI assistant at each milestone start)

**A:** *"Read AAROGYAMP-REFERENCE.md fully. You are helping build the backend core (folders/files owned by Person A in AAROGYAMP-WORKPLAN.md §File Ownership Map). Current milestone: [MILESTONE TASKS]. Follow the frozen schemas in Reference §6/§11 exactly. Finish by running the milestone's verification and showing me output."*

**B:** *"Read AAROGYAMP-REFERENCE.md §7, §8, §9, §16, §18. You own emergency_rule_engine.py, ai_symptom_engine.py, specialty_mapper.py, the two rule/mapping YAML files, and routers/assessments.py. Current milestone: [TASKS]. The emergency rule engine is deterministic and must never depend on the LLM being available. Never let output imply a confirmed diagnosis. Flag if a rules.yaml threshold change needs clinical sign-off rather than making the change yourself."*

**C:** *"Read AAROGYAMP-REFERENCE.md §10, §11, §12, §13, §14. You own app/ (all of it, both patient and doctor roles). Current milestone: [TASKS]. While USE_MOCKS=true nothing may import from the network layer except core/api/. Always show the non-diagnostic disclaimer on assessment screens. Handle location-permission-denied and WebSocket-reconnect per §14."*

---

*Sync this file's checkboxes as work happens. When reality diverges from plan, update THIS doc — it's the shared brain for however many different AI assistants are helping build this.*
