# AarogyaMP (आरोग्यMP) 🩺

> **AI-Assisted Symptom Triage, Verified Doctor Discovery, and Consultation Platform**  
> *"AI narrows down what it could be and how urgent it is — a verified doctor decides what it actually is."*

---

## Table of Contents
- [Project Overview](#project-overview)
- [Architecture & Tech Stack](#architecture--tech-stack)
- [Prerequisites](#prerequisites)
- [Backend & AI Stack (Docker - Recommended)](#1-backend--ai-stack-docker---recommended)
  - [Single-Command Model Override](#single-command-model-override)
  - [Service Ports & Dashboards](#service-ports--dashboards)
- [Backend Manual Setup (Without Docker)](#2-backend-manual-setup-without-docker)
- [Frontend (Flutter Mobile App)](#3-frontend-flutter-mobile-app)
  - [Running with Live Backend](#running-with-live-backend)
  - [Running in Standalone Mock Mode](#running-in-standalone-mock-mode)
  - [Connecting from a Physical Phone](#connecting-from-a-physical-phone-on-local-wi-fi)
- [Testing & Verification](#testing--verification)
- [Demo Credentials](#demo-credentials)
- [Repository Structure](#repository-structure)

---

## Project Overview

AarogyaMP is a full-loop medical triage and consultation ecosystem featuring:
1. **Patient App (Flutter)**: Input symptoms via natural voice or text, enter vital signs with inline validation, receive a calibrated AI assessment (possible causes + risk tier), and directly connect with nearby verified doctors via live chat, call, or email.
2. **Deterministic Emergency Gatekeeper**: A rules engine that intercepts life-threatening red flags (chest pain, stroke symptoms, respiratory distress) instantly (<1ms), bypassing LLM inference entirely and directing the patient to emergency guidance.
3. **Doctor Portal (Flutter)**: Verified doctors receive patient intake summaries, vital records, and AI triage assessments directly in their queue to conduct live WebSocket-based consultations.
4. **Self-Hosted AI & Infra**: Designed to run 100% locally with zero external API dependencies (no OpenAI/Groq or Firebase accounts required).

---

## Architecture & Tech Stack

| Layer | Technology | Details |
|---|---|---|
| **Frontend** | Flutter (Dart 3.x) | State management via Riverpod, navigation via `go_router`, real-time WebSockets |
| **Backend API** | FastAPI (Python 3.11+) | Asynchronous REST endpoints, JWT auth, WebSocket chat rooms |
| **Local AI Engine** | Ollama | OpenAI-compatible inference server running `llama3.1:8b` (customizable up to 70B) |
| **Database** | PostgreSQL 16 / SQLite | Relational persistence with SQLAlchemy & psycopg |
| **Notifications** | ntfy | Self-hosted, lightweight push notification server (no Firebase needed) |

---

## Prerequisites

Make sure the following are installed on your system:
- [Docker](https://docs.docker.com/get-docker/) & Docker Compose (v2.0+)
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.19+)
- [Python](https://www.python.org/) 3.11+ (only needed if running backend outside Docker)

---

## 1. Backend & AI Stack (Docker - Recommended)

The easiest way to run the entire backend (API server, PostgreSQL database, Ollama local AI engine, and ntfy push notification server) is using Docker Compose.

```bash
# 1. Navigate to the server directory
cd server

# 2. Copy the environment template
cp .env.example .env

# 3. Start the entire self-hosted stack
docker compose up -d
```

On the first run, the `ollama-pull` container will automatically download the default **`llama3.1:8b`** model (~4.7 GB). You can watch the download progress:

```bash
docker compose logs -f ollama-pull
```

Once ready, all doctors are automatically seeded and the server is live!

### Single-Command Model Override
You can switch the underlying AI model on the fly using a single command:

```bash
# High-precision clinical model (recommended for 64GB RAM or GPU servers):
OLLAMA_MODEL=llama3.1:70b-instruct-q4_K_M docker compose up -d

# Ultra-lightweight model (ideal for quick dev loops on 8GB/16GB laptops):
OLLAMA_MODEL=llama3.2:3b-instruct docker compose up -d

# Deep multilingual model (optimized for Hindi and regional languages):
OLLAMA_MODEL=qwen2.5:72b-instruct-q8_0 docker compose up -d
```

### Service Ports & Dashboards

| Service | Address | Description |
|---|---|---|
| **API Server** | `http://localhost:8000` | FastAPI server (`http://localhost:8000/docs` for Swagger UI) |
| **Local AI (Ollama)** | `http://localhost:11434` | OpenAI-compatible endpoint at `/v1` |
| **Push Notifications (ntfy)** | `http://localhost:8080` | Web dashboard & topic stream |
| **PostgreSQL** | `localhost:5432` | DB: `aarogyamp`, User: `aarogya`, Pass: `aarogya` |

---

## 2. Backend Manual Setup (Without Docker)

If you prefer to run the backend natively without Docker:

```bash
cd server

# Create and activate Python virtual environment
python3 -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Configure environment (uses local SQLite demo.db by default)
cp .env.example .env

# Seed verified doctor records
python scripts/seed_doctors.py

# Launch API server
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

---

## 3. Frontend (Flutter Mobile App)

### Running with Live Backend

```bash
cd app

# Fetch Flutter dependencies
flutter pub get

# Run on your connected device, simulator, or browser
flutter run
```

### Running in Standalone Mock Mode
If the backend is not running, you can run the entire mobile app in mock mode with zero server dependencies:

```bash
cd app
flutter run --dart-define=USE_MOCKS=true
```

### Connecting from a Physical Phone (on Local Wi-Fi)
1. Find your host machine's local IP address (`ipconfig` on Windows or `ifconfig` / `ip a` on Mac/Linux, e.g. `192.168.1.15`).
2. Update the `baseUrl` in [`app/lib/core/api/api_client.dart`](app/lib/core/api/api_client.dart) to:
   ```dart
   static const String baseUrl = 'http://192.168.1.15:8000';
   ```
3. Run `flutter run` with your phone connected via USB or wireless debugging.

---

## Testing & Verification

### Running Server Tests
Run the backend automated test suite:

```bash
# Run isolated unit & integration tests
PYTHONPATH=server ./.venv/bin/pytest server/tests/ -v
```

### Testing Emergency Rule Engine
Verify that the emergency detection system flags critical conditions:

```bash
PYTHONPATH=server ./.venv/bin/pytest server/tests/test_emergency_rule_engine.py -v
```

### Persona Clinical Audit
To audit AI triage output against the synthetic patient personas:

```bash
PYTHONPATH=server python -m server.scripts.test_ai_engine --persona moderate_fever
```

---

## Demo Credentials

The database seeds multiple verified doctors across various specialties. You can log in using these pre-seeded accounts:

| Role | Phone | Password | Specialty |
|---|---|---|---|
| **Doctor** | `9876543210` | `doctor123` | General Physician |
| **Doctor** | `9876543211` | `doctor123` | Cardiologist |
| **Doctor** | `9876543212` | `doctor123` | Pediatrician |
| **Patient** | Register any 10-digit number | Any password | — |

*Admin Operations Token (for verifying doctors via API): `CHANGE_ME_BEFORE_PRODUCTION` (or as configured in `.env`).*

---

## Repository Structure

```
arogya/
├── app/                        # Flutter mobile application
│   ├── lib/
│   │   ├── core/               # API clients, auth services, routing, state models
│   │   ├── features/           # Symptom intake, triage result, chat, doctor directory
│   │   └── mocks/              # Offline test mocks for standalone UI dev
├── server/                     # FastAPI backend
│   ├── app/
│   │   ├── routers/            # Auth, consultations, assessments, admin endpoints
│   │   ├── services/           # AI symptom engine, emergency rules, doctor search
│   │   ├── data/               # Clinical emergency rules and specialty mapping YAMLs
│   │   └── models.py           # SQLAlchemy database schemas
│   ├── scripts/                # Seeding utilities, clinical persona test scripts
│   ├── tests/                  # Pytest test suites (M1, M2, emergency engine)
│   ├── docker-compose.yml      # Complete self-hosted production stack (Postgres + Ollama + ntfy + API)
│   └── .env.example            # Environment configuration template
├── docs/                       # Technical specs, architecture decisions, and setup guides
│   └── LOCAL_AI_SETUP.md       # Detailed guide for self-hosted local AI inference
├── DEVLOG.md                   # Session-by-session engineering changelog
├── AAROGYAMP-REFERENCE.md      # Full architecture specification and frozen API contracts
└── AAROGYAMP-WORKPLAN.md       # Team milestone responsibilities and file ownership map
```

---

## Safety & Compliance Note

> **AarogyaMP is designed as a clinical decision-support and triage triage aid, NOT a diagnostic medical device.**  
> All AI-generated outputs represent preliminary assessments and possible conditions to be evaluated by a licensed, verified medical professional. Emergency clinical rules are governed deterministically and cannot be overridden by generative AI outputs.
