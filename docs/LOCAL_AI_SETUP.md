# AarogyaMP — Self-Hosted Local AI Setup Guide

> **Status: Implemented.** The `server/docker-compose.yml` now includes Ollama (local LLM),
> PostgreSQL, and ntfy (push notifications). No external API keys required.

---

## Quick Start (for anyone who clones the repo)

```bash
# 1. Clone and enter server directory
cd server

# 2. Copy the env template
cp .env.example .env

# 3. Edit .env — change JWT_SECRET and ADMIN_OPS_TOKEN to random strings
#    The LLM, DB, and ntfy settings are auto-configured by docker-compose

# 4. Start everything (first run downloads the model ~4.7 GB — takes ~2-5 min)
docker compose up -d

# 5. Watch the model download progress
docker compose logs -f ollama-pull

# 6. Once ready, check the server
curl http://localhost:8000/health
# → {"status":"ok","version":"0.2.0"}

# 7. Check the ntfy dashboard
open http://localhost:8080
```

That's it. No Groq account. No Firebase. No external API keys needed.

---

## Model Selection & Single-Command Override

The default is **`llama3.1:8b`** (~4.7 GB download, ~2-5 second response time, runs smoothly on any 16GB laptop or server).

### How to change the model via a single command:

You can override the model on the fly without editing any files:

```bash
# Run with 70B clinical model (on a 64GB machine):
OLLAMA_MODEL=llama3.1:70b-instruct-q4_K_M docker compose up -d

# Or run with lightweight 3B model (for ultra-fast local testing):
OLLAMA_MODEL=llama3.2:3b-instruct docker compose up -d

# Or run with Qwen 72B for deep Hindi/multilingual capability:
OLLAMA_MODEL=qwen2.5:72b-instruct-q8_0 docker compose up -d
```

### Or change it permanently in `server/.env`:

```env
OLLAMA_MODEL=llama3.1:8b
```

---

## Model Reference Table

| RAM Available | Model Tag | Download Size | Response Time | Best For |
|---|---|---|---|---|
| **16 GB – 32 GB** | `llama3.1:8b` | ~4.7 GB | **2–5s** | **Default. Fast, balanced triage.** |
| **8 GB – 16 GB** | `llama3.2:3b-instruct` | ~2.0 GB | **1–3s** | Quick testing & low-RAM laptops |
| **64 GB** | `llama3.1:70b-instruct-q4_K_M` | ~40 GB | ~6–15s (GPU) / ~30s (CPU) | High clinical precision |
| **128 GB** | `qwen2.5:72b-instruct-q8_0` | ~80 GB | ~8–20s | Best multilingual (Hindi, Marathi) |
docker compose logs -f ollama-pull  # watch progress
```

---

## Concurrency: 100–200 Peak Users

Ollama is configured with:
- `OLLAMA_NUM_PARALLEL=4` — processes up to 4 LLM requests simultaneously
- `OLLAMA_MAX_QUEUE=20` — queues up to 20 more while the 4 slots are busy
- `OLLAMA_KEEP_ALIVE=24h` — model stays loaded in RAM, no cold start per request

At 100–200 peak users, most requests will be brief (assessment takes ~15-30s on 70B Q4 CPU-only,
~5-10s if a GPU is available). The queue handles bursts. The rule-based emergency engine
is entirely synchronous and never hits the LLM, so emergency triage is always instant.

**If you have a GPU:** Ollama automatically uses it. No configuration needed. This reduces
inference time from ~30s to ~3-5s and dramatically increases throughput.

---

## Architecture Diagram

```
[Android/iOS App]
      │
      │ HTTP/WebSocket
      ▼
[AarogyaMP API :8000]   ← auto-seeded with synthetic doctors on first start
      │          │
      │          │ SQL
      │          ▼
      │      [PostgreSQL :5432]
      │
      │ OpenAI-compatible HTTP
      ▼
[Ollama :11434]          ← Llama 3.1 70B or Qwen 2.5 72B running locally
  (no internet needed)
      
[ntfy :8080]             ← push notifications (doctors & patients)
  (subscribed by app)
```

---

## What PERSON A needs to do: Wire ntfy

The `notifications.py` file currently uses Firebase FCM (which is a no-op stub when
`FCM_SERVER_KEY` is empty). To fully activate push notifications with ntfy:

### Changes needed in `server/app/services/notifications.py` (Person A owns this):

```python
# Replace FCM calls with ntfy HTTP calls:
# ntfy topic convention:
#   Doctor notifications → topic: "aarogyamp-doctor-{doctor_id}"
#   Patient notifications → topic: "aarogyamp-patient-{patient_id}"

import httpx
import os

NTFY_BASE_URL = os.getenv("NTFY_BASE_URL", "http://localhost:8080")

async def _send_ntfy(topic: str, title: str, body: str, priority: str = "default") -> None:
    """Fire-and-forget ntfy notification. Never raises."""
    try:
        async with httpx.AsyncClient(timeout=3.0) as client:
            await client.post(
                f"{NTFY_BASE_URL}/{topic}",
                headers={
                    "Title": title,
                    "Priority": priority,
                    "Tags": "hospital",
                },
                content=body.encode("utf-8"),
            )
    except Exception as exc:
        logger.warning(f"[ntfy] Failed to send notification: {exc!r}")


# Then replace _send_fcm calls:
# send_new_message_notification → _send_ntfy(f"aarogyamp-doctor-{doctor_id}", ...)
# send_queue_notification       → _send_ntfy(f"aarogyamp-doctor-{doctor_id}", ...)
# send_doctor_responded_notification → _send_ntfy(f"aarogyamp-patient-{patient_id}", ...)
```

### Flutter app changes needed to subscribe to ntfy (Person C owns app/):
- Add `ntfy_flutter` or use `http` + SSE to subscribe to `http://<server-ip>:8080/aarogyamp-patient-{userId}/sse`
- This replaces the FCM token registration flow entirely

---

## Config changes needed in `server/app/config.py` (Person A owns this):

```python
# Add to Settings class:
NTFY_BASE_URL: str = "http://localhost:8080"
```

---

## What's Already Done (no code changes needed)

- ✅ `docker-compose.yml` — Ollama + PostgreSQL + ntfy + API server, all wired together
- ✅ `.env.example` — updated with model selection instructions, no external keys
- ✅ `ntfy.yml` — ntfy server configuration
- ✅ LLM config — `LLM_BASE_URL=http://ollama:11434/v1` already works with the existing
  `openai` Python SDK (it's OpenAI-compatible). Zero code changes to `ai_symptom_engine.py`.

---

## Keeping DEVLOG / Workplan in sync

After Person A wires ntfy, update:
1. `LLM_PROVIDER_DECISION.md` — mark local Ollama as the new decision
2. `DEVLOG.md` — session entry for the change
3. `server/.env.example` — already updated
