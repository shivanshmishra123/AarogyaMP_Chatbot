"""
AarogyaMP — AI Symptom Engine (Milestone 1 + Milestone 2 prompt-quality hardening)
Person B owns this file.

This is the LLM integration layer. It runs ONLY when emergency_rule_engine returns
is_emergency=False (Stage 4 of the pipeline).

Provider: Groq (OpenAI-compatible endpoint)
  LLM_BASE_URL and LLM_MODEL from config/env.

Key contracts (Reference §9):
  - Input: raw_text + duration + vitals + fixed specialty list from specialty_map.yaml
  - Output: LLMAssessmentOutput (see schemas.py) — FROZEN JSON schema
  - risk_level in LLM output is NEVER "EMERGENCY" — that value is reserved for the
    rule engine only. LLM can only say LOW | MODERATE | HIGH.
  - On timeout/failure: ai_status="unavailable", default risk=MODERATE minimum.
  - Retry once on parse failure with "return valid JSON only" instruction.
  - Strip markdown fences before json.loads.
  - Validate with Pydantic; required fields: risk_level, possible_conditions,
    recommendation_text — if any missing, ai_status="unavailable".

Target: complete analysis in well under 10s total end-to-end.

Milestone 2 changes:
  - System prompt hardened to explicitly forbid confirmed-diagnosis language,
    require hedging/possible framing, prohibit prescriptive medication dosages,
    and mandate the non-diagnostic disclaimer in every response.
  - Audited across all synthetic personas — see scripts/audit_all_personas.py.
"""
import asyncio
import json
import logging
import re
from typing import Optional, Tuple

from openai import AsyncOpenAI
from pydantic import ValidationError

from app.config import settings
from app.schemas import LLMAssessmentOutput
from app.services.specialty_mapper import get_all_specialties

logger = logging.getLogger(__name__)


# ── LLM client (built once, reused) ──────────────────────────

def _build_client() -> AsyncOpenAI:
    return AsyncOpenAI(
        base_url=settings.LLM_BASE_URL,
        api_key=settings.LLM_API_KEY or "not-set",
        timeout=float(settings.LLM_TIMEOUT_SECONDS),
    )


_client: AsyncOpenAI = _build_client()


# ── System prompt (Reference §9, hardened at M2) ─────────────

_SYSTEM_PROMPT = """\
You are a clinical decision-support assistant helping a general patient population \
triage symptoms in a mobile health app. You are given a patient's self-reported \
symptoms, symptom duration, and (if available) vital signs.

Rules:
1. You are NOT diagnosing. NEVER state a confirmed condition. NEVER say "you have", \
"you are suffering from", "diagnosis is", or any language that implies certainty. \
Always frame output as "possible conditions" — use words like "may", "could", \
"possible", "suggests", "consistent with", "potential".
2. Base conclusions ONLY on the provided information. If information is insufficient, \
say so explicitly and lower confidence rather than guessing.
3. Pick recommended_specialty ONLY from the provided fixed specialty list. Do not \
invent specialties.
4. If anything in the input suggests a potential emergency, say so plainly in \
recommendation_text and set risk_level to HIGH at minimum — but note that a \
dedicated rule engine, not you, has final authority on declaring EMERGENCY.
5. NEVER prescribe medication, dosages, or specific treatments. You may suggest \
general self-care (rest, hydration, monitoring) but must always recommend consulting \
a doctor for any treatment decisions.
6. The disclaimer field MUST always contain: "This is an AI-generated possible-conditions \
read, not a medical diagnosis."
7. recommendation_text MUST be actionable — tell the patient what to do next \
(e.g. "consult a doctor", "monitor symptoms", "seek urgent care if X develops") — \
but never imply that you are providing a definitive medical conclusion.
8. Output STRICT JSON conforming exactly to the provided schema. No prose outside JSON."""


# ── Prompt assembly ───────────────────────────────────────────

def _build_user_prompt(
    raw_text: str,
    duration_text: Optional[str],
    temperature_f: Optional[float],
    heart_rate_bpm: Optional[int],
    systolic_bp: Optional[int],
    diastolic_bp: Optional[int],
    spo2_pct: Optional[int],
    age: Optional[int],
) -> str:
    """Assemble the user message with patient data and output schema instruction."""
    specialties = get_all_specialties()

    parts = [f"Patient symptoms: {raw_text}"]

    if duration_text:
        parts.append(f"Duration: {duration_text}")

    # Vitals block
    vitals_parts = []
    if temperature_f is not None:
        vitals_parts.append(f"Temperature: {temperature_f}°F")
    if heart_rate_bpm is not None:
        vitals_parts.append(f"Heart rate: {heart_rate_bpm} bpm")
    if systolic_bp is not None and diastolic_bp is not None:
        vitals_parts.append(f"Blood pressure: {systolic_bp}/{diastolic_bp} mmHg")
    if spo2_pct is not None:
        vitals_parts.append(f"SpO2: {spo2_pct}%")
    if age is not None:
        vitals_parts.append(f"Age: {age}")

    if vitals_parts:
        parts.append("Vitals: " + ", ".join(vitals_parts))
    else:
        parts.append("Vitals: not provided")

    parts.append(
        "Fixed specialty list (pick ONLY from this list): "
        + ", ".join(specialties)
    )

    parts.append("""
Output STRICT JSON matching this exact schema (no other text):
{
  "risk_level": "LOW | MODERATE | HIGH",
  "confidence": "high | medium | low",
  "possible_conditions": [
    { "name": "condition name", "likelihood": "high | medium | low" }
  ],
  "supporting_symptoms": ["symptom1", "symptom2"],
  "recommended_specialty": "from the fixed list above",
  "recommendation_text": "actionable next-step advice for the patient",
  "disclaimer": "This is an AI-generated possible-conditions read, not a medical diagnosis."
}""")

    return "\n".join(parts)


# ── Response parsing ──────────────────────────────────────────

def _strip_markdown_fences(text: str) -> str:
    """Remove ```json ... ``` or ``` ... ``` wrapping if present, and repair missing closing brace."""
    text = text.strip()
    pattern = r"^```(?:json)?\s*\n?(.*?)\n?\s*```$"
    match = re.match(pattern, text, re.DOTALL)
    if match:
        text = match.group(1).strip()
    else:
        # Also check for embedded markdown code blocks
        sub_pattern = r"```(?:json)?\s*\n?(.*?)\n?\s*```"
        sub_match = re.search(sub_pattern, text, re.DOTALL)
        if sub_match:
            text = sub_match.group(1).strip()

    # Repair if starts with { but missing trailing }
    if text.startswith("{") and not text.endswith("}"):
        text = text + "\n}"
    return text


def _parse_and_validate(raw_response: str) -> Optional[LLMAssessmentOutput]:
    """
    Parse JSON string and validate against LLMAssessmentOutput schema.
    Returns None if parsing or validation fails.
    """
    cleaned = _strip_markdown_fences(raw_response)
    try:
        data = json.loads(cleaned)
    except json.JSONDecodeError as e:
        logger.warning("JSON parse failed: %s", e)
        return None

    try:
        return LLMAssessmentOutput(**data)
    except ValidationError as e:
        logger.warning("Pydantic validation failed: %s", e)
        return None


# ── LLM call ──────────────────────────────────────────────────

async def _call_llm(user_prompt: str) -> Optional[str]:
    """Make the actual LLM API call. Returns raw content string or None on failure."""
    try:
        response = await asyncio.wait_for(
            _client.chat.completions.create(
                model=settings.LLM_MODEL,
                messages=[
                    {"role": "system", "content": _SYSTEM_PROMPT},
                    {"role": "user", "content": user_prompt},
                ],
                temperature=0.3,
                max_tokens=500,
            ),
            timeout=float(settings.LLM_TIMEOUT_SECONDS),
        )
        content = response.choices[0].message.content
        logger.info("LLM raw response: %s", content)
        return content
    except Exception as e:
        logger.error("LLM call failed: %s", e)
        return None


# ── Telemetry & Degraded-Path Metrics (Milestone 3 / 4) ───────

_ai_metrics: dict = {
    "total_requests": 0,
    "successful_analyses": 0,
    "unavailable_analyses": 0,
    "last_failure_reason": None,
    "last_failure_timestamp": None,
}


def get_ai_metrics() -> dict:
    """
    Return in-memory telemetry on AI symptom engine requests and availability rate.
    Enables monitoring of the ai_status="unavailable" rate in production.
    """
    total = _ai_metrics["total_requests"]
    unavailable = _ai_metrics["unavailable_analyses"]
    rate = (unavailable / total) if total > 0 else 0.0
    return {
        **_ai_metrics,
        "unavailable_rate": round(rate, 4),
        "unavailable_percentage": f"{round(rate * 100, 2)}%",
    }


def reset_ai_metrics() -> None:
    """Reset telemetry counters (useful for unit tests and periodic flush)."""
    _ai_metrics["total_requests"] = 0
    _ai_metrics["successful_analyses"] = 0
    _ai_metrics["unavailable_analyses"] = 0
    _ai_metrics["last_failure_reason"] = None
    _ai_metrics["last_failure_timestamp"] = None


def _record_metric_failure(reason: str) -> None:
    import datetime
    _ai_metrics["total_requests"] += 1
    _ai_metrics["unavailable_analyses"] += 1
    _ai_metrics["last_failure_reason"] = reason
    _ai_metrics["last_failure_timestamp"] = datetime.datetime.now(datetime.timezone.utc).isoformat()
    metrics = get_ai_metrics()
    logger.warning(
        "ai_status='unavailable' [reason: %s]. Telemetry: total=%d, unavailable=%d (%s)",
        reason,
        metrics["total_requests"],
        metrics["unavailable_analyses"],
        metrics["unavailable_percentage"],
    )


def _record_metric_success() -> None:
    _ai_metrics["total_requests"] += 1
    _ai_metrics["successful_analyses"] += 1


# ── Public API ────────────────────────────────────────────────

async def analyze(
    raw_text: str,
    duration_text: Optional[str],
    temperature_f: Optional[float] = None,
    heart_rate_bpm: Optional[int] = None,
    systolic_bp: Optional[int] = None,
    diastolic_bp: Optional[int] = None,
    spo2_pct: Optional[int] = None,
    age: Optional[int] = None,
) -> Tuple[Optional[LLMAssessmentOutput], str]:
    """
    Call Groq LLM with assembled prompt, parse + validate §9 JSON schema.

    Returns: (LLMAssessmentOutput or None, ai_status)
      ai_status: "ok" | "unavailable"
    """
    try:
        # Guard: no API key configured
        if not settings.LLM_API_KEY:
            logger.warning("LLM_API_KEY not configured — returning unavailable")
            _record_metric_failure("missing_api_key")
            return None, "unavailable"

        user_prompt = _build_user_prompt(
            raw_text, duration_text,
            temperature_f, heart_rate_bpm, systolic_bp, diastolic_bp,
            spo2_pct, age,
        )

        # ── Attempt 1 ─────────────────────────────────────────────
        raw_response = await _call_llm(user_prompt)
        if raw_response is None:
            _record_metric_failure("llm_call_failed_attempt_1")
            return None, "unavailable"

        result = _parse_and_validate(raw_response)

        # ── Retry once on parse failure (Reference §9) ────────────
        if result is None:
            logger.warning("First LLM response failed parsing — retrying with strict instruction")
            retry_prompt = (
                user_prompt
                + "\n\nYour previous response was not valid JSON. "
                "Return ONLY valid JSON matching the schema above, no other text."
            )
            raw_response = await _call_llm(retry_prompt)
            if raw_response is None:
                _record_metric_failure("llm_call_failed_retry")
                return None, "unavailable"
            result = _parse_and_validate(raw_response)

        # ── Final check ───────────────────────────────────────────
        if result is None:
            logger.error("LLM response failed validation after retry")
            _record_metric_failure("schema_validation_failed")
            return None, "unavailable"

        _record_metric_success()
        return result, "ok"

    except Exception as exc:
        logger.error("Unexpected exception in ai_symptom_engine.analyze: %s", exc, exc_info=True)
        _record_metric_failure(f"unhandled_exception: {type(exc).__name__}")
        return None, "unavailable"

