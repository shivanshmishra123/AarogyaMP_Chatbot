"""
AarogyaMP — AI Symptom Engine (Milestone 0 stub)
Person B owns this file.

This is the LLM integration layer. It runs ONLY when emergency_rule_engine returns
is_emergency=False (Stage 4 of the pipeline).

Provider: Groq (OpenAI-compatible endpoint)
  LLM_BASE_URL=https://api.groq.com/openai/v1
  LLM_MODEL=llama-3.3-70b-versatile

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

TODO (M1 — Person B): Full implementation.
  M0 deliverable: server/scripts/test_ai_engine.py sends one persona and
  proves the Groq → §9 JSON schema round-trip works.
"""
from typing import Optional
from app.schemas import LLMAssessmentOutput


async def analyze(
    raw_text: str,
    duration_text: Optional[str],
    temperature_f: Optional[float] = None,
    heart_rate_bpm: Optional[int] = None,
    systolic_bp: Optional[int] = None,
    diastolic_bp: Optional[int] = None,
    spo2_pct: Optional[int] = None,
    age: Optional[int] = None,
) -> tuple[Optional[LLMAssessmentOutput], str]:
    """
    Call Groq LLM with assembled prompt, parse + validate §9 JSON schema.

    Returns: (LLMAssessmentOutput or None, ai_status)
      ai_status: "ok" | "unavailable"
    """
    raise NotImplementedError("M1 — Person B")
