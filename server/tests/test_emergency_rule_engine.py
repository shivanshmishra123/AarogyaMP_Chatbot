"""
AarogyaMP — Emergency Rule Engine Tests (Milestone 1)
Person B owns this file.

⚠️  These tests MUST pass before any edit to emergency_rules.yaml ships.
    Run: pytest server/tests/test_emergency_rule_engine.py

Test coverage:
  - Every emergency persona in fixtures/personas.json → is_emergency=True
  - Every non-emergency persona → is_emergency=False
  - Emergency path returns in under 1 second (no LLM call)
  - Rule engine works even if LLM is unavailable (no import from ai_symptom_engine)
"""
import json
import time
from pathlib import Path

import pytest

from app.services.emergency_rule_engine import run

FIXTURES_PATH = Path(__file__).parent / "fixtures" / "personas.json"


@pytest.fixture
def personas():
    with open(FIXTURES_PATH) as f:
        data = json.load(f)
    return {p["id"]: p for p in data["personas"]}


def _vitals_kwargs(persona: dict) -> dict:
    """Extract the vitals fields the rule engine expects from a persona."""
    v = persona.get("vitals", {})
    return {
        "temperature_f": v.get("temperature_f"),
        "heart_rate_bpm": v.get("heart_rate_bpm"),
        "systolic_bp": v.get("systolic_bp"),
        "diastolic_bp": v.get("diastolic_bp"),
        "spo2_pct": v.get("spo2_pct"),
    }


# ── Emergency personas SHOULD be flagged ──────────────────────

def test_emergency_vitals_is_flagged(personas):
    """persona_emergency_vitals must trigger EMG_VITALS_CRITICAL."""
    persona = personas["persona_emergency_vitals"]
    result = run(raw_text=persona["raw_text"], **_vitals_kwargs(persona))
    assert result.is_emergency is True, "Emergency vitals persona was NOT flagged"
    assert any(
        t["rule_id"] == "EMG_VITALS_CRITICAL" for t in result.triggers
    ), "EMG_VITALS_CRITICAL trigger missing"


def test_emergency_keyword_is_flagged(personas):
    """persona_emergency_keyword must trigger EMG_KEYWORD_MATCH."""
    persona = personas["persona_emergency_keyword"]
    result = run(raw_text=persona["raw_text"], **_vitals_kwargs(persona))
    assert result.is_emergency is True, "Emergency keyword persona was NOT flagged"
    assert any(
        t["rule_id"] == "EMG_KEYWORD_MATCH" for t in result.triggers
    ), "EMG_KEYWORD_MATCH trigger missing"


# ── Non-emergency personas should NOT be flagged ──────────────

def test_low_risk_not_emergency(personas):
    """persona_low must NOT be flagged as emergency."""
    persona = personas["persona_low"]
    result = run(raw_text=persona["raw_text"], **_vitals_kwargs(persona))
    assert result.is_emergency is False, f"LOW-risk persona wrongly flagged: {result.triggers}"


def test_moderate_risk_not_emergency(personas):
    """persona_moderate must NOT be flagged as emergency."""
    persona = personas["persona_moderate"]
    result = run(raw_text=persona["raw_text"], **_vitals_kwargs(persona))
    assert result.is_emergency is False, f"MODERATE-risk persona wrongly flagged: {result.triggers}"


def test_high_risk_not_emergency(personas):
    """persona_high must NOT be flagged as emergency (thresholds are clinical decisions)."""
    persona = personas["persona_high"]
    result = run(raw_text=persona["raw_text"], **_vitals_kwargs(persona))
    assert result.is_emergency is False, f"HIGH-risk persona wrongly flagged: {result.triggers}"


# ── Performance: must be fast (no LLM) ───────────────────────

def test_emergency_detection_is_fast(personas):
    """Emergency check must complete in well under 1 second — no I/O allowed."""
    persona = personas["persona_emergency_vitals"]
    start = time.time()
    run(raw_text=persona["raw_text"], **_vitals_kwargs(persona))
    elapsed = time.time() - start
    assert elapsed < 0.5, f"Emergency rule engine took {elapsed:.2f}s — too slow"


# ── Edge cases ────────────────────────────────────────────────

def test_empty_text_no_crash():
    """Engine should not crash on empty input."""
    result = run(raw_text="")
    assert result.is_emergency is False


def test_no_vitals_no_crash():
    """Engine should not crash when no vitals are provided at all."""
    result = run(raw_text="I have a headache.")
    assert result.is_emergency is False


def test_result_triggers_is_list(personas):
    """triggers field must always be a list, even when empty."""
    persona = personas["persona_low"]
    result = run(raw_text=persona["raw_text"], **_vitals_kwargs(persona))
    assert isinstance(result.triggers, list)
