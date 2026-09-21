# AarogyaMP — Full Project Reference

> Use this document to understand, build, or extend AarogyaMP. It covers the full architecture, feature set, folder structure, data models, API contracts, clinical rule design, LLM integration contracts, and implementation instructions. Feed this to any AI agent or new teammate to get accurate, context-aware help without re-scanning the codebase.

**Problem statement:** AI-assisted symptom triage + verified-doctor discovery + doctor-patient consultation platform for a general patient population.

---

## 1. Project Overview

AarogyaMP is a **symptom-assessment + doctor-discovery + doctor-chat platform**, built as a single mobile app with two roles (Patient, Doctor) sharing one backend and one AI engine.

1. **Patient app (Flutter, Android/iOS)** — patient logs in, describes symptoms (text or voice), enters vitals, gets an AI-generated risk read (possible conditions + severity + recommended next step — never a confirmed diagnosis), and is routed either to emergency guidance or to a nearby verified doctor they can call, email, or chat with.
2. **Doctor app (same Flutter codebase, doctor role)** — verified doctors see incoming patients, their symptoms/vitals/AI assessment, and respond via the same chat thread.

**One-line pitch:** *"AI narrows down what it could be and how urgent it is — a verified doctor decides what it actually is."*

### Core Features (MVP scope — "full loop")

- Patient login/register (role: patient or doctor)
- Text or voice symptom input, in the patient's own words
- Structured vitals entry (temperature, heart rate, BP, optional SpO₂/age/duration) with input validation
- **AI Symptom & Risk Assessment**: possible conditions, risk level (LOW/MODERATE/HIGH/EMERGENCY), supporting symptoms, recommended next step, recommended specialty — always labeled as a possible-conditions read, never a diagnosis
- **Emergency Risk Detection**: a deterministic rule engine (not the LLM) that runs first and can short-circuit straight to emergency guidance
- Doctor directory: search/filter by specialty, distance, verified status
- Call / Email / Chat entry points from a doctor's profile
- Doctor–patient chat: text, voice messages, images/report uploads
- Doctor dashboard: incoming patient queue with symptoms + vitals + AI assessment attached, so the doctor isn't starting from zero
- Consultation history for both roles

---

## 2. Tech Stack

> **AI model provider is intentionally undecided** (local vs. hosted) — see §15. Everything downstream is built against an OpenAI-compatible chat-completion interface so the choice is a config swap, not a rewrite.

### Mobile App (`/app`) — Flutter

*Assumption: Flutter chosen over React Native for a single codebase covering Android + iOS, strong `flutter_sound`/`speech_to_text` plugins for voice, and Material widgets that suit a fast-moving team. Swap is low-cost if the team prefers RN — the API contract in §11 doesn't change either way.*

| Purpose | Library/Tool |
|---|---|
| Language | Dart / Flutter 3.x |
| State management | Riverpod (or Provider — pick one, don't mix) |
| Navigation | `go_router` |
| HTTP client | `dio` |
| Realtime chat | WebSocket (`web_socket_channel`) against backend `/ws/chat/{consultation_id}` |
| Local persistence | `shared_preferences` (session token), `sqflite` (offline chat cache, optional) |
| Voice input | `speech_to_text` (device STT) or server-side STT (see §15) |
| Voice playback (doctor TTS) | `flutter_tts` |
| Maps/location | `geolocator` + `google_maps_flutter` (or an OSM alternative) |
| Push notifications | Firebase Cloud Messaging |
| Image/file picking | `image_picker`, `file_picker` |

### Backend (`/server`) — Python

| Purpose | Library/Tool |
|---|---|
| Language | Python 3.11+ |
| Framework | FastAPI + Uvicorn |
| Database | PostgreSQL via SQLAlchemy 2.0 (Alembic for migrations) |
| Validation | Pydantic v2 |
| Realtime chat | FastAPI `WebSocket` endpoint, one room per `consultation_id` |
| LLM | Any OpenAI-compatible API (OpenAI / Groq / OpenRouter / a self-hosted Ollama model) — base URL + key + model all from env, per §15 |
| Speech-to-Text (server-side option) | Whisper API (hosted) or local `faster-whisper` — see §15 |
| Auth | JWT (access + refresh), password hashing via `passlib[bcrypt]` |
| Background jobs | FastAPI `BackgroundTasks` for the assessment pipeline (upgrade to a queue only if load requires it) |
| File uploads | FastAPI `UploadFile` → local disk or object storage, path referenced in DB |
| Isolation | Docker Compose (`server` + `postgres`) for local/prod parity |

### Admin / Doctor verification (optional, small)

A minimal internal-only screen (or just direct DB/admin CLI for early stage) to mark a doctor's `verification_status` as verified — doctor contact info must never surface unverified. Doesn't need its own framework at MVP; a FastAPI admin route behind a hardcoded ops token is enough until real admin tooling is justified.

---

## 3. Architecture Overview

```
┌───────────────────────────────┐     ┌───────────────────────────────┐
│  Flutter App — Patient role   │     │  Flutter App — Doctor role    │
│                               │     │                               │
│  Login/Register               │     │  Login (verified doctor)      │
│  Symptom input (text/voice)   │     │  Incoming patient queue       │
│  Vitals entry                 │     │  Patient detail + AI card     │
│  AI Assessment card           │     │  Chat window                  │
│  Doctor directory + map       │     │  Consultation history         │
│  Call / Email / Chat          │     │                               │
│  Chat window                  │     │                               │
└───────────────┬───────────────┘     └───────────────┬───────────────┘
                │             REST + WebSocket (JSON)   │
                └──────────────────┬────────────────────┘
                                   ▼
                    ┌───────────────────────────────┐
                    │        FastAPI Backend         │
                    │        (Docker Compose)        │
                    │                                │
                    │  Auth (JWT, role-based)         │
                    │  POST /api/assessments          │
                    │  GET  /api/assessments/{id}     │
                    │  GET  /api/doctors               │
                    │  POST /api/consultations         │
                    │  WS   /ws/chat/{consultation_id} │
                    │  ...                             │
                    │                                │
                    │  Assessment pipeline (BackgroundTask):
                    │   1. validate_vitals            │
                    │   2. emergency_rule_engine.py   │
                    │      (deterministic, runs first)│
                    │   3. ai_symptom_engine.py (LLM) │
                    │   4. specialty_mapper.py        │
                    │   5. persist AI_Assessment row  │
                    └───────┬───────────────┬─────────┘
                            ▼               ▼
                  ┌──────────────┐   ┌──────────────────┐
                  │  PostgreSQL   │   │  LLM API          │
                  │  (patients,   │   │  (OpenAI-compat,  │
                  │  doctors,     │   │  local or hosted) │
                  │  chats, ...)  │   └──────────────────┘
                  └──────────────┘
```

### Key Design Decisions

- **Emergency detection is rule-based and runs BEFORE the LLM, not instead of a doctor.** A crash, timeout, or "unavailable" LLM must never suppress an emergency flag — the deterministic rule engine is the safety floor, exactly the way a fraud-score floor works when an AI layer degrades. The LLM enriches the *possible-conditions narrative*; it never gates the emergency path.
- **The system never states a confirmed diagnosis.** Every AI-facing output is framed as "possible conditions" + "risk level" + "recommended next step." This is a hard product rule, not just a wording preference — see §18.
- **Doctor contact info and directory listings come from verified provider records, never from the LLM.** The LLM must not be allowed to invent or "recall" a doctor, clinic, phone number, or address.
- **LLM failure tolerance:** if no API key is configured or the call fails/times out, the assessment still ships with `ai_status: "unavailable"` and a rule-based risk level; the UI clearly states AI narrative is temporarily unavailable and defaults to "recommend seeing a doctor" rather than downgrading urgency.
- **Chat is realtime (WebSocket) once a consultation exists, but call/email are just deep-links** (`tel:`, `mailto:`) — no telephony backend needed at MVP.

---

## 4. Folder Structure

```
aarogyamp/
├── app/                                  # Flutter app (single codebase, role-based routing)
│   ├── lib/
│   │   ├── main.dart
│   │   ├── core/
│   │   │   ├── api/
│   │   │   │   ├── api_client.dart       # dio instance, base URL, auth interceptor
│   │   │   │   └── endpoints.dart        # mirrors §11 exactly
│   │   │   ├── models/                   # Dart mirrors of backend schemas.py
│   │   │   ├── router/
│   │   │   │   └── app_router.dart       # go_router, role-based redirect guards
│   │   │   └── theme/
│   │   ├── features/
│   │   │   ├── auth/
│   │   │   ├── symptom_intake/
│   │   │   │   ├── symptom_text_input.dart
│   │   │   │   ├── symptom_voice_input.dart
│   │   │   │   └── vitals_form.dart
│   │   │   ├── assessment/
│   │   │   │   ├── assessment_result_screen.dart   # possible conditions + risk card
│   │   │   │   └── emergency_screen.dart           # full-screen, no dismiss-and-forget
│   │   │   ├── doctor_directory/
│   │   │   │   ├── doctor_list_screen.dart
│   │   │   │   ├── doctor_map_screen.dart
│   │   │   │   └── doctor_profile_screen.dart      # Call / Email / Chat entry points
│   │   │   ├── chat/
│   │   │   │   ├── chat_screen.dart
│   │   │   │   └── voice_message_widget.dart
│   │   │   ├── doctor_dashboard/                   # doctor-role only
│   │   │   │   ├── patient_queue_screen.dart
│   │   │   │   └── patient_detail_screen.dart
│   │   │   └── history/
│   │   │       └── consultation_history_screen.dart
│   │   └── widgets/                                # shared widgets (RiskBadge, VitalsChip...)
│   └── pubspec.yaml
├── server/
│   ├── app/
│   │   ├── __init__.py
│   │   ├── main.py                       # FastAPI app factory, CORS, routes + WS mount
│   │   ├── config.py                     # pydantic-settings, reads .env
│   │   ├── database.py                   # SQLAlchemy engine/session (Postgres)
│   │   ├── models.py                     # ORM: Patient, Doctor, Symptom, Vitals, AI_Assessment, Consultation, ChatMessage
│   │   ├── schemas.py                    # Pydantic request/response schemas — FROZEN (§6, §11)
│   │   ├── auth.py                       # JWT issue/verify, password hashing, role guard deps
│   │   ├── routers/
│   │   │   ├── __init__.py
│   │   │   ├── auth.py                   # /api/auth/*
│   │   │   ├── assessments.py            # /api/assessments/*
│   │   │   ├── doctors.py                # /api/doctors/*
│   │   │   ├── consultations.py          # /api/consultations/* + WS chat
│   │   │   └── admin.py                  # doctor verification (ops-token gated)
│   │   ├── services/
│   │   │   ├── __init__.py
│   │   │   ├── vitals_validator.py       # range checks, obviously-invalid flags
│   │   │   ├── emergency_rule_engine.py  # THE safety floor — deterministic, loads emergency_rules.yaml
│   │   │   ├── ai_symptom_engine.py      # THE GenAI layer: prompt assembly + JSON parsing
│   │   │   ├── specialty_mapper.py       # possible conditions → recommended specialty
│   │   │   ├── doctor_search.py          # distance calc, specialty/verification filters
│   │   │   └── notifications.py          # FCM push on new message / new patient in queue
│   │   └── data/
│   │       ├── emergency_rules.yaml      # ALL emergency thresholds live here (edit freely)
│   │       └── specialty_map.yaml        # symptom/condition keyword → specialty
│   ├── storage/
│   │   ├── voice_messages/               # gitignored
│   │   └── chat_attachments/             # gitignored
│   ├── tests/
│   │   └── test_emergency_rule_engine.py # MUST pass before any rule-file edit ships
│   ├── alembic/                          # migrations
│   ├── Dockerfile
│   ├── docker-compose.yml
│   ├── requirements.txt
│   └── .env
└── docs/
    └── demo-script.md
```

---

## 5. Environment Variables

### Backend (`server/.env`)

```env
PORT=8000
DATABASE_URL=postgresql+psycopg://aarogya:aarogya@postgres:5432/aarogyamp
JWT_SECRET=
JWT_ACCESS_EXPIRE_MINUTES=30
JWT_REFRESH_EXPIRE_DAYS=14
STORAGE_DIR=./storage
MAX_UPLOAD_MB=25
CORS_ORIGINS=*

# LLM — provider undecided; both shapes below are OpenAI-compatible so this is a config swap
LLM_BASE_URL=https://api.openai.com/v1        # or a local Ollama URL, e.g. http://localhost:11434/v1
LLM_API_KEY=                                   # blank/unused for local models
LLM_MODEL=gpt-4o-mini                          # or e.g. llama3.1:8b for local
LLM_TIMEOUT_SECONDS=30

# Speech-to-Text — only needed if doing server-side STT instead of on-device
STT_PROVIDER=device                            # device | whisper_api | local_whisper
STT_API_KEY=

# Push
FCM_SERVER_KEY=

# Ops
ADMIN_OPS_TOKEN=
```

### Mobile app (`app/lib/core/config.dart` or `--dart-define`)

```env
API_BASE_URL=http://<backend-host>:8000
WS_BASE_URL=ws://<backend-host>:8000
GOOGLE_MAPS_API_KEY=
```

> **Networking note for local dev on a physical phone:** point `API_BASE_URL` at the machine's LAN IP, bind uvicorn to `0.0.0.0`, and confirm the phone and backend are on the same network (or use a tunnel like ngrok).

---

## 6. Data Model

```python
class Patient(Base):
    __tablename__ = "patients"
    id: Mapped[str]                 # uuid4
    name: Mapped[str]
    age: Mapped[Optional[int]]
    gender: Mapped[Optional[str]]
    phone: Mapped[str]
    email: Mapped[Optional[str]]
    password_hash: Mapped[str]
    home_location: Mapped[Optional[str]]   # last-known lat/lng, JSON
    created_at: Mapped[datetime]

class Doctor(Base):
    __tablename__ = "doctors"
    id: Mapped[str]
    name: Mapped[str]
    specialty: Mapped[str]
    qualification: Mapped[Optional[str]]
    phone: Mapped[str]
    email: Mapped[Optional[str]]
    hospital: Mapped[Optional[str]]
    address: Mapped[Optional[str]]
    latitude: Mapped[Optional[float]]
    longitude: Mapped[Optional[float]]
    languages: Mapped[Optional[str]]        # JSON list
    availability: Mapped[Optional[str]]     # JSON: hours/days
    verification_status: Mapped[str]        # pending | verified | rejected
    password_hash: Mapped[str]              # doctor also logs into the app
    created_at: Mapped[datetime]

class SymptomReport(Base):
    __tablename__ = "symptom_reports"
    id: Mapped[str]
    patient_id: Mapped[str]
    input_mode: Mapped[str]                 # text | voice
    raw_text: Mapped[str]                   # transcript if voice
    duration_text: Mapped[Optional[str]]    # "2 days" — free text, normalized in schema too
    created_at: Mapped[datetime]

class Vitals(Base):
    __tablename__ = "vitals"
    id: Mapped[str]
    symptom_report_id: Mapped[str]
    temperature_f: Mapped[Optional[float]]
    heart_rate_bpm: Mapped[Optional[int]]
    systolic_bp: Mapped[Optional[int]]
    diastolic_bp: Mapped[Optional[int]]
    spo2_pct: Mapped[Optional[int]]
    flagged_invalid: Mapped[Optional[str]]  # JSON list of field names that failed range check
    source: Mapped[str]                     # manual | device (future)
    timestamp: Mapped[datetime]

class AIAssessment(Base):
    __tablename__ = "ai_assessments"
    id: Mapped[str]
    symptom_report_id: Mapped[str]
    risk_level: Mapped[str]                 # LOW | MODERATE | HIGH | EMERGENCY
    is_emergency: Mapped[bool]              # set by emergency_rule_engine, independent of LLM
    emergency_triggers: Mapped[Optional[str]]  # JSON: [{rule_id, description}] — always populated if is_emergency
    possible_conditions: Mapped[Optional[str]] # JSON: [{name, likelihood}]
    recommended_specialty: Mapped[Optional[str]]
    recommendation_text: Mapped[Optional[str]]
    ai_status: Mapped[str]                  # ok | unavailable | skipped
    raw_ai_response: Mapped[Optional[str]]  # JSON, full LLM output (schema §9), for audit/debug
    created_at: Mapped[datetime]

class Consultation(Base):
    __tablename__ = "consultations"
    id: Mapped[str]
    patient_id: Mapped[str]
    doctor_id: Mapped[str]
    symptom_report_id: Mapped[Optional[str]]  # link back to what prompted this consult, if any
    channel: Mapped[str]                    # call | email | chat
    status: Mapped[str]                     # open | closed
    started_at: Mapped[datetime]
    ended_at: Mapped[Optional[datetime]]

class ChatMessage(Base):
    __tablename__ = "chat_messages"
    id: Mapped[str]
    consultation_id: Mapped[str]
    sender_role: Mapped[str]                # patient | doctor
    message_type: Mapped[str]               # text | voice | image | document
    text: Mapped[Optional[str]]
    file_path: Mapped[Optional[str]]
    timestamp: Mapped[datetime]
```

### Risk Level Bands (must match `app/lib/widgets/risk_badge.dart`)

| Risk level | Meaning | Color | UI behavior |
|---|---|---|---|
| EMERGENCY | Rule engine tripped an emergency indicator | Red, full-screen | Blocks normal flow, shows emergency guidance immediately, no scrolling past it |
| HIGH | AI + rules suggest urgent-but-not-emergency | Orange | Strongly prompts booking a doctor now |
| MODERATE | Some concern, not urgent | Yellow | Suggests a doctor visit, gives self-care guidance where safe |
| LOW | Mild/self-limiting pattern | Green | Reassurance + "see a doctor if it worsens" |

---

## 7. Emergency & Specialty Rules (`server/app/data/`)

This is the safety-critical, explainable layer — same principle as a weighted rules engine: every emergency flag must be traceable to a named rule, never to "the AI felt like it."

### `emergency_rules.yaml` (shape, not exhaustive medical content — a clinician must review and own the actual thresholds before this ships)

```yaml
emergency_rules:
  - id: EMG_VITALS_CRITICAL
    description: "Vitals fall outside clinician-approved emergency thresholds"
    condition: vitals_outside_safe_range   # implemented in vitals_validator.py against clinician-set bounds
  - id: EMG_KEYWORD_MATCH
    description: "Patient's own words match a clinician-approved emergency symptom list"
    condition: raw_text_matches_emergency_keywords   # e.g. severe chest pain, can't breathe, unconscious — exact list owned by a clinician, not invented in code
  - id: EMG_COMBINATION
    description: "A specific combination of symptoms + vitals meets an emergency pattern"
    condition: symptom_vitals_combo_match
```

**Non-negotiable process rule:** the actual keyword lists, vital-sign thresholds, and combination logic in this file must be authored or signed off by a qualified clinician, not guessed by an engineer or an LLM. Treat this file the way APK Sentinel treats `rules.yaml` — the single source of truth for "why did we flag this" — except here a wrong threshold has direct patient-safety consequences, so it needs a real medical review step before every change ships, not just a code review.

### `specialty_map.yaml`

```yaml
specialty_rules:
  - keywords: [fever, cough, cold, body pain, general weakness]
    specialty: General Physician
  - keywords: [chest pain, palpitations, high blood pressure]
    specialty: Cardiologist
  - keywords: [rash, itching, skin]
    specialty: Dermatologist
  - keywords: [child, infant, pediatric]
    specialty: Pediatrician
  - keywords: [ear pain, throat, sinus, hearing]
    specialty: ENT Specialist
  - keywords: [joint pain, fracture, back pain]
    specialty: Orthopedic Specialist
  - keywords: [headache, numbness, seizure, dizziness]
    specialty: Neurologist
  - keywords: [anxiety, depression, sleep, mood]
    specialty: Mental Health Professional
```

The AI layer (§9) is asked to pick a specialty from this fixed list — it does not get to invent specialties.

---

## 8. Symptom Assessment Pipeline (`pipeline` orchestration inside `assessments.py` + `services/`)

```
Stage 1  intake                    → save SymptomReport (raw_text, input_mode, duration)
Stage 2  vitals_validator.run()    → save Vitals; flag obviously-invalid values (e.g. HR=0, temp=150°F)
                                      back to the patient for correction before proceeding
Stage 3  emergency_rule_engine.run()  → deterministic check against emergency_rules.yaml
                                      if EMERGENCY: short-circuit — return immediately with
                                      is_emergency=true, emergency guidance, SKIP the LLM call
                                      entirely (speed matters more than narrative here)
Stage 4  ai_symptom_engine.analyze()  → only runs if NOT already emergency; LLM call → JSON (§9)
Stage 5  specialty_mapper.resolve()   → cross-checks LLM's suggested specialty against
                                      specialty_map.yaml; falls back to General Physician
                                      if LLM's pick isn't in the fixed list
Stage 6  persist AIAssessment row     → status=completed; push notification not needed here
                                      (patient is actively waiting in-app)
```

**Timeout discipline:** wrap the LLM call with `LLM_TIMEOUT_SECONDS`. On timeout/failure: `ai_status="unavailable"`, `risk_level` falls back to whatever the rule engine + vitals already indicate (never silently "LOW" by default — default to at least MODERATE with "AI narrative unavailable, please consult a doctor" if nothing else could be determined).

Target end-to-end time: **under 10 seconds** for a non-emergency assessment (emergency path should return in well under 1 second since it never touches the LLM).

---

## 9. AI Layer Contract (`ai_symptom_engine.py`) — MOST IMPORTANT FILE TO GET RIGHT

### Input assembly

```
SymptomReport.raw_text + duration
  + Vitals (temperature, HR, BP, SpO2, age if provided)
  + fixed specialty list from specialty_map.yaml (so the model picks FROM this list)
  → assemble prompt: system instructions + patient data block + output schema instruction
```

Edge cases:
- **Emergency already detected in Stage 3** → this layer is skipped entirely (`ai_status="skipped"`); do not spend a call confirming what the rule engine already answered.
- **Missing vitals** → proceed with symptoms + duration alone; the model should lower confidence and say so rather than guessing vitals.
- **Non-English / mixed-language input** (e.g. Hindi transcribed via voice) → pass the raw transcript through as-is; the model should respond in the fixed schema shape but can mirror the patient's language in `behavior_summary`-equivalent free text fields. Full multi-language support is tracked as a roadmap item (§17) — don't silently mistranslate for MVP.

### Prompt skeleton (system prompt)

```
You are a clinical decision-support assistant helping a general patient population
triage symptoms in a mobile health app. You are given a patient's self-reported
symptoms, symptom duration, and (if available) vital signs.

Rules:
- You are NOT diagnosing. Never state a confirmed condition. Always frame output as
  "possible conditions" with a risk level and a recommended next step.
- Base conclusions ONLY on the provided information. If information is insufficient,
  say so and lower confidence rather than guessing.
- Pick recommended_specialty ONLY from the provided fixed specialty list.
- If anything in the input suggests a potential emergency, say so plainly in
  recommendation_text and set risk_level to HIGH at minimum — but note that a
  dedicated rule engine, not you, has final authority on declaring EMERGENCY.
- Output STRICT JSON conforming exactly to the provided schema. No prose outside JSON.
```

### Required output schema (enforce with JSON mode/function calling if the provider supports it; otherwise parse robustly)

```json
{
  "risk_level": "LOW | MODERATE | HIGH",
  "confidence": "high | medium | low",
  "possible_conditions": [
    { "name": "Viral/febrile illness", "likelihood": "high" },
    { "name": "Influenza-like illness", "likelihood": "medium" }
  ],
  "supporting_symptoms": ["fever", "headache", "body pain"],
  "recommended_specialty": "General Physician",
  "recommendation_text": "Consult a physician; seek urgent care if breathing difficulty, chest pain, or confusion develop.",
  "disclaimer": "This is an AI-generated possible-conditions read, not a medical diagnosis."
}
```

Note: `risk_level` here never includes `EMERGENCY` — that value is reserved for the deterministic rule engine's output field (`AIAssessment.is_emergency` / the merged risk level shown to the patient), so the LLM can never itself declare an emergency and the two signals stay clearly separable in the data model and in any audit trail.

### Robustness requirements (do not skip)

- Strip markdown fences before `json.loads`; retry once with "return valid JSON only" on parse failure.
- Validate with Pydantic against the schema above; on validation failure, keep whatever fields parsed and mark `ai_status="ok"` only if the required fields (`risk_level`, `possible_conditions`, `recommendation_text`) are all present — otherwise `ai_status="unavailable"`.
- Reject and retry once if `recommended_specialty` isn't in the fixed list from `specialty_map.yaml`; on second failure, default to General Physician.
- Log the raw response for debugging/audit — health-data logging must follow the retention/consent rules in §18, not just dumped to a plain file indefinitely.

---

## 10. Patient-Facing Output Format (`assessment_result_screen.dart`)

The merged result (rule engine + AI) shown to the patient, structured, not a paragraph dump:

```
┌───────────────────────────────────────────┐
│  🟡 MODERATE RISK                          │
│  Based on your symptoms & vitals            │
├───────────────────────────────────────────┤
│  Possible causes                           │
│  • Viral/febrile illness (high)            │
│  • Influenza-like illness (medium)         │
├───────────────────────────────────────────┤
│  Recommendation                            │
│  Consult a physician. Seek urgent care if  │
│  breathing difficulty, chest pain, or      │
│  confusion develop.                        │
├───────────────────────────────────────────┤
│  ⚠ This is an AI-generated read, not a     │
│  diagnosis. A doctor makes the final call. │
├───────────────────────────────────────────┤
│  [ Find a General Physician near me ]      │
└───────────────────────────────────────────┘
```

The disclaimer line is **not optional UI copy** — it must render every time an assessment (LOW/MODERATE/HIGH) is shown. The EMERGENCY screen (§9, §18) is a different, full-screen component with no "possible causes" list at all — just clear guidance to seek immediate emergency care.

---

## 11. Backend API Reference

Base URL: `http://<host>:8000`. All responses JSON. Auth: JWT bearer token except `/api/auth/*`.

#### `POST /api/auth/register` / `POST /api/auth/login`
Standard email+password (or phone+OTP later). Returns `{ access_token, refresh_token, role }`. `role` is `patient` or `doctor`.

#### `POST /api/assessments`
Submit a symptom report + vitals, run the pipeline synchronously (it's fast — no polling needed for the non-emergency path; still return quickly even in the rare slow case).

**Request:**
```json
{
  "input_mode": "text",
  "raw_text": "I have fever since two days, headache and body pain.",
  "duration_text": "2 days",
  "vitals": { "temperature_f": 102, "heart_rate_bpm": 98, "systolic_bp": 145, "diastolic_bp": 92, "spo2_pct": 96, "age": 42 }
}
```

**Response `200`:**
```json
{
  "assessment_id": "9f1c...",
  "is_emergency": false,
  "risk_level": "MODERATE",
  "possible_conditions": [{ "name": "Viral/febrile illness", "likelihood": "high" }],
  "recommended_specialty": "General Physician",
  "recommendation_text": "Consult a physician...",
  "ai_status": "ok"
}
```

**Emergency response `200`** (LLM skipped entirely):
```json
{
  "assessment_id": "9f1c...",
  "is_emergency": true,
  "emergency_triggers": [{ "rule_id": "EMG_VITALS_CRITICAL", "description": "..." }],
  "risk_level": "EMERGENCY",
  "recommendation_text": "Seek immediate emergency medical care. Do not wait for a chat response.",
  "ai_status": "skipped"
}
```

Errors: `400` invalid/missing vitals shape, `422` validation error.

#### `GET /api/assessments/{assessment_id}`
Fetch a past assessment (patient's own, or the linked doctor's, only).

#### `GET /api/doctors?specialty=&lat=&lng=&radius_km=`
Nearby verified doctors only (`verification_status=verified` enforced server-side, never client-side).

**Response `200`:**
```json
{ "doctors": [ { "id": "...", "name": "Dr. A Sharma", "specialty": "General Physician", "distance_km": 2.4, "phone": "...", "email": "...", "hospital": "...", "availability": {...} } ] }
```

#### `POST /api/consultations`
Start a call/email/chat consultation from a doctor profile. `{ "doctor_id": "...", "channel": "chat", "symptom_report_id": "..." }` → `{ "consultation_id": "..." }`.

#### `WS /ws/chat/{consultation_id}`
Bidirectional. Client sends `{ "type": "text"|"voice"|"image", "content": "..." }`; server broadcasts to both participants and persists as `ChatMessage`. Auth via token in the connection query string or an initial auth frame.

#### `GET /api/consultations/{id}/messages?before=&limit=`
Paginated chat history (for reconnects / doctor dashboard load).

#### `GET /api/doctor/queue` (doctor role only)
Doctor's incoming patients: consultation + linked symptom report + vitals + AI assessment, so the doctor dashboard never has to stitch that together client-side.

#### `POST /api/admin/doctors/{id}/verify` (ops-token gated)
Flip a doctor to `verified`. Placeholder until real admin tooling exists.

---

## 12. App Screens & Components (Flutter)

| Screen | Route | Description | Key widgets |
|---|---|---|---|
| Splash / Login / Register | `/`, `/login`, `/register` | Role selection (patient/doctor) baked into register | — |
| Patient Home | `/home` | "How are you feeling today?" + text/voice toggle + recent history | `SymptomInputToggle` |
| Symptom Input — Text | `/symptoms/text` | Free-text box | — |
| Symptom Input — Voice | `/symptoms/voice` | Mic button → STT → editable transcript before submit (always let the patient review/edit what was heard) | `VoiceCaptureWidget` |
| Vitals Entry | `/vitals` | Form with inline validation, flags obviously-invalid values before submit | `VitalsForm` |
| Assessment Result | `/assessment/:id` | The card in §10 | `RiskBadge`, `ConditionList` |
| Emergency Screen | `/emergency` | Full-screen, no possible-causes list, clear action guidance, no dismiss-and-forget path | `EmergencyBanner` |
| Doctor Directory (list) | `/doctors` | Filter by specialty/distance/verified | `DoctorCard` |
| Doctor Directory (map) | `/doctors/map` | Same data, map pins | `DoctorMapView` |
| Doctor Profile | `/doctors/:id` | Call / Email / Chat buttons | `ContactButtonsRow` |
| Chat | `/chat/:consultationId` | Text/voice/image, mic button | `ChatBubble`, `VoiceMessageWidget` |
| Doctor Queue (doctor role) | `/doctor/queue` | Incoming patients list | `PatientQueueCard` |
| Patient Detail (doctor role) | `/doctor/patient/:id` | Symptoms + vitals + AI assessment + chat entry | `PatientSummaryCard` |
| Consultation History | `/history` | Both roles, filtered by role | `HistoryListTile` |

---

## 13. End-to-End User Flow

### Patient
```
1. Login/Register → Home ("How are you feeling today?")
2. Choose text or voice → enter symptoms → enter vitals (validated inline)
3. Submit → pipeline runs (§8)
4a. Emergency → full-screen emergency guidance, no further AI chat offered
4b. Non-emergency → Assessment Result card (§10) → "Find a [specialty] near me"
5. Doctor Directory → pick a doctor → Call (tel: deep link) / Email (prefilled structured
   message: symptoms, vitals, AI read) / Chat (opens/creates a Consultation)
6. Chat window: text/voice/images ↔ doctor responds
7. Consultation closes when doctor marks it resolved (or patient leaves it — history retained either way)
```

### Doctor
```
1. Login (verified only — unverified accounts see a "pending verification" screen, nothing else)
2. Doctor Queue: new patients with symptom report + vitals + AI assessment attached
3. Open Patient Detail → review AI assessment (labeled as AI-generated, not fact)
4. Respond via Chat (or the patient reaches them via Call/Email outside the app)
5. Mark consultation resolved → moves to History
```

---

## 14. Mobile App Implementation Notes

### Permissions (Android manifest / iOS Info.plist)
```
RECORD_AUDIO           # voice symptom input, voice chat messages
ACCESS_FINE_LOCATION    # nearby doctor search
INTERNET
CAMERA / READ_MEDIA_IMAGES   # attaching photos/reports in chat
POST_NOTIFICATIONS      # Android 13+, for chat/queue push
```

### Gotchas (read before coding)

- **Always let the patient review/edit an STT transcript before submitting.** Symptom descriptions are safety-relevant; a misheard "no chest pain" → "chest pain" (or vice versa) is not a cosmetic bug.
- **Never render a doctor's contact info for an unverified doctor**, even if the API accidentally returns one — treat `verification_status` as required to check client-side too, defense in depth.
- **WebSocket reconnect logic**: on drop, re-fetch `GET /api/consultations/{id}/messages` since the last known message id before resuming the socket, to avoid gaps.
- **Location permission denial must not block the whole app** — degrade to "enter your city/pincode manually" for doctor search rather than a dead end.
- **Voice messages**: cap length (e.g. 2 minutes) and show a visible waveform/duration before sending, same as any chat app — don't ship a silent-record UX.
- **Keep patient and doctor flows in one app with role-based routing**, not two separate apps — simpler to maintain at this scope, and it's what "mobile app only" for the full loop implies. Revisit only if doctor-side needs diverge enough to justify a split.

---

## 15. Third-Party Services Setup

### LLM provider — **UNDECIDED, design for either**
Everything in §9 targets an OpenAI-compatible `/chat/completions`-style call, configured purely via `LLM_BASE_URL` / `LLM_API_KEY` / `LLM_MODEL`. Two real paths, no code fork needed:
- **Hosted:** OpenAI `gpt-4o-mini`, Groq `llama-3.3-70b-versatile`, or OpenRouter — fast to start, needs an API key and a data-handling review (health data leaving the device/server, see §18).
- **Local:** Ollama serving a model like `llama3.1:8b` or a medical-tuned open model, `LLM_BASE_URL=http://localhost:11434/v1` — no data leaves the infrastructure, but needs a GPU-capable host and slower iteration; JSON-mode reliability varies by model, lean harder on the robust-parsing/retry path in §9 if going local.

Decide this by: whether patient symptom text is allowed to leave your own infrastructure at all (compliance question, §18) — that answer picks the path, not raw model quality.

### Speech-to-Text / Text-to-Speech
- **Device-side (`STT_PROVIDER=device`, recommended to start):** `speech_to_text` Flutter plugin, zero backend cost, works offline on many devices, but language coverage depends on the OS.
- **Server-side (`whisper_api` or `local_whisper`):** better accuracy for regional languages/accents, costs a network round trip and (for the hosted option) sends audio off-device — same compliance question as the LLM choice.

### Maps / Location
Google Maps Platform (Geocoding + Places or your own doctor DB with lat/lng) — or an OpenStreetMap-based stack (Nominatim + a free tile provider) if avoiding Google's pricing/ToS is a priority.

### Push Notifications
Firebase Cloud Messaging — new chat message, doctor accepted/responded, queue updates for doctors.

### Doctor verification data
Doctor records (name, qualification, registration number, specialty, contact) must come from a verified source — a manual onboarding/verification process at minimum, ideally cross-checked against a state medical council registry where available. **Never let the AI layer generate or infer a doctor record.**

---

## 16. Demo / Test Data Strategy

- **Never use real patient health data for development, demos, or automated tests.** Build a small set of synthetic patient personas (fabricated names, symptom sets, vitals) covering: a LOW-risk case, a MODERATE case, a HIGH case, and at least one EMERGENCY-triggering case, plus one deliberately-invalid-vitals case to test the validator.
- Build a synthetic doctor directory (5–10 fake doctors across the specialties in `specialty_map.yaml`) with placeholder-but-realistic contact info (fake numbers/emails clearly marked as test data) so the directory/call/email/chat flow can be demoed end-to-end without depending on real doctor onboarding being finished.
- Emergency-path test persona is as important as the "happy path" ones — it's the one flow that must never regress silently; keep `test_emergency_rule_engine.py` running in CI against all synthetic personas.

---

## 17. What's Intentionally Not Built (v1 / roadmap)

Valid "what would you build next?" answers:

- **Video consultations** — chat + voice messages cover MVP; live video is a real feature but a much bigger telemedicine-compliance lift
- **Wearable/device vital integration** — vitals are manually entered at v1; auto-capture from supported devices is the PDF's own stated "future version" item
- **E-prescriptions / medication ordering** — deliberately out of scope; this is a triage-and-connect product, not a pharmacy or prescribing platform
- **Payments / insurance billing** — none at v1
- **EHR interoperability** — consultation history lives in AarogyaMP only for now; exporting to external health records is a later integration
- **Full multi-language AI reasoning** — voice/text capture can take regional-language input, but the AI schema and specialty list are English-first at v1; broad regional-language *reasoning* (not just transcription) is roadmap
- **Doctor auto-matching/ranking algorithm** — v1 is filter + distance sort; anything ML-ranked is later
- **A trained clinical ML risk classifier** — v1 deliberately uses rules (safety floor) + LLM (narrative), same rationale APK-style projects use rules+GenAI over a custom classifier: explainability and speed of iteration, with the added reason here that a black-box risk classifier is a much harder thing to get a clinician to sign off on

---

## 18. Safety & Compliance Notes (read before building the AI or emergency layers)

- **This is decision support, not a diagnostic device.** Every possible-conditions output must carry the disclaimer in §10. If this product is ever positioned as diagnostic, that's a materially different regulatory category — don't let scope creep there silently.
- **Emergency detection thresholds and keyword lists must be authored/approved by a qualified clinician**, not invented by engineers or generated by the LLM (§7). Treat any change to `emergency_rules.yaml` as requiring the same sign-off as the original thresholds, not just a normal PR review.
- **The LLM never has the final word on an emergency.** Its role is narrative/possible-conditions enrichment on the non-emergency path only (§8, §9).
- **Doctor identity and contact details are verified data, not AI output.** Never let the assessment or chat layer fabricate a provider.
- **Patient health data is sensitive personal data.** In India this falls under the Digital Personal Data Protection Act, 2023 (consent, purpose limitation, breach notification) — get real legal review before launch; this reference doc is not a compliance sign-off. Practical defaults in the meantime: encrypt data at rest and in transit, minimize what's sent to any third-party LLM/STT provider, keep raw AI logs access-controlled and time-limited, and get explicit patient consent before sharing symptom/vitals data with a doctor or third-party AI provider.
- **If the LLM path is hosted/third-party, symptom and vitals text is leaving your infrastructure** — this needs an explicit decision and disclosure, not a default. It's the main variable behind the local-vs-hosted AI choice mentioned as still open.
- **Telemedicine practice itself may be separately regulated** (e.g. India's Telemedicine Practice Guidelines govern how registered doctors may consult remotely) — the chat/consultation feature should be reviewed against those before doctors are treated as "practicing" through the app, not just an engineering concern.

---

## 19. Team Split & Ownership

See the companion `AAROGYAMP-WORKPLAN.md` for the full milestone plan, file-ownership map, and per-person kickoff prompts. Summary:

| Track | Owns |
|---|---|
| **Person A — Backend Core** | `server/app/` minus `services/ai_symptom_engine.py`; auth, data model, doctor search, consultations/WS, migrations |
| **Person B — AI & Clinical Logic** | `services/ai_symptom_engine.py`, `services/emergency_rule_engine.py`, `services/specialty_mapper.py`, `data/emergency_rules.yaml`, `data/specialty_map.yaml` |
| **Person C — Mobile App** | `app/` (all of it — both patient and doctor role screens) |

---

## Quick Start

### Backend
```bash
cd server
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env          # fill DB URL + LLM config
docker compose up -d postgres
alembic upgrade head
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
# Swagger at http://localhost:8000/docs
```

### Mobile App
```bash
cd app
flutter pub get
flutter run --dart-define=API_BASE_URL=http://<laptop-lan-ip>:8000 --dart-define=WS_BASE_URL=ws://<laptop-lan-ip>:8000
```

### Docker Compose (backend + db together)
```bash
docker compose up --build
```

---

*Keep this document in sync with actual implementation. When you change an API shape, the LLM schema, or an emergency rule — update it here first (and get clinical sign-off on rule changes), then code.*
