# AarogyaMP — LLM Provider Decision

> Milestone 2 deliverable (Person B). Required by AAROGYAMP-WORKPLAN.md §M2:
> "Decide and document final LLM provider choice (Reference §15) if not already locked in at M0."

---

## Decision: Groq (Hosted)

**Provider:** Groq  
**Endpoint:** `https://api.groq.com/openai/v1` (OpenAI-compatible)  
**Model:** `openai/gpt-oss-120b`  
**Decision date:** 2026-09-30  
**Decision maker:** Person B (AI & Clinical Logic track)

---

## Why Groq

| Criterion | Groq | Alternative: Local Ollama |
|---|---|---|
| **Latency** | ~2–5s for full assessment (well under the 10s target in Reference §8) | Variable; depends on host GPU. Can exceed 10s on consumer hardware. |
| **JSON reliability** | Excellent — consistently returns valid §9 schema JSON on first attempt | Model-dependent; smaller open models often need 2+ retries for valid JSON |
| **Setup complexity** | API key only — zero infrastructure to manage | Requires a GPU-capable host, model download, Ollama daemon |
| **Cost** | Free tier sufficient for development + early pilot; paid tier for scale | Free at runtime, but GPU hardware cost |
| **Model quality** | 120B parameter model produces consistently actionable, well-hedged triage output | Smaller open models (8B-13B) struggle with nuanced clinical framing |

### Why not OpenAI directly?

OpenAI's `gpt-4o-mini` would also work (same OpenAI-compatible interface), but Groq's free tier made it the practical choice for development. The architecture supports switching with a single config change (`LLM_BASE_URL` + `LLM_MODEL` in `server/.env`), so migrating to OpenAI, OpenRouter, or a local model requires zero code changes.

---

## Data-Handling Rationale (Reference §15, §18)

### What data leaves our infrastructure

When a non-emergency assessment runs, the following is sent to Groq's API:

1. **Patient's self-reported symptom text** (free-text, in the patient's own words)
2. **Symptom duration** (e.g., "2 days")
3. **Vital signs** (temperature, heart rate, BP, SpO₂, age)

This is **sensitive personal health data** under India's Digital Personal Data Protection Act, 2023 (DPDP Act).

### Mitigations in place

| Risk | Mitigation |
|---|---|
| **Data leaves infrastructure** | Acknowledged and accepted for development/pilot phase. For production, this requires explicit patient consent disclosure (see §18). |
| **No PII sent** | The prompt contains only symptoms, duration, and vitals — no patient name, phone, email, or ID is ever sent to the LLM. |
| **Groq data retention** | Groq's API does not train on user data by default. Verify current data retention policy before production launch. |
| **Fallback if unavailable** | `ai_status="unavailable"` path is fully implemented and tested — the app degrades gracefully to a rule-based MODERATE risk assessment with "consult a doctor" guidance. |
| **Emergency path never touches LLM** | The deterministic rule engine short-circuits emergencies before the LLM is called. Patient safety does not depend on the LLM being available or correct. |

### Before production launch (gating items)

- [ ] Obtain explicit patient consent for sending symptom data to a third-party AI provider (DPDP Act compliance)
- [ ] Review Groq's current data retention and processing terms
- [ ] Decide whether to migrate to a self-hosted model (Ollama) to keep all data on-premises — this is a compliance decision, not a technical one
- [ ] If staying with Groq: document the data flow in a patient-facing privacy notice

---

## Swap path (if provider needs to change)

The entire LLM integration is behind three environment variables:

```env
LLM_BASE_URL=https://api.groq.com/openai/v1
LLM_API_KEY=<key>
LLM_MODEL=openai/gpt-oss-120b
```

To switch to any other OpenAI-compatible provider:

| Target | Change |
|---|---|
| **OpenAI** | `LLM_BASE_URL=https://api.openai.com/v1`, `LLM_MODEL=gpt-4o-mini` |
| **OpenRouter** | `LLM_BASE_URL=https://openrouter.ai/api/v1`, `LLM_MODEL=<any supported model>` |
| **Local Ollama** | `LLM_BASE_URL=http://localhost:11434/v1`, `LLM_MODEL=llama3.1:8b`, `LLM_API_KEY=` (blank) |

Zero code changes required. The `ai_symptom_engine.py` uses the standard `openai` Python SDK which works with any compatible endpoint.

---

## Monitoring (M4 readiness)

Per AAROGYAMP-WORKPLAN.md §M4, Person B must monitor `ai_status="unavailable"` rate in production. Implementation plan:

- Log every `ai_status` value at INFO level (already done in `ai_symptom_engine.py`)
- At M4: add a simple counter/metric that tracks `ok` vs `unavailable` vs `skipped` rates
- Alert threshold: if `unavailable` rate exceeds 10% over a rolling 1-hour window, investigate provider issues

---

*This document is the authoritative record of the LLM provider decision for AarogyaMP. Update it here if the decision changes — do not silently swap providers without updating this file and notifying all tracks.*
