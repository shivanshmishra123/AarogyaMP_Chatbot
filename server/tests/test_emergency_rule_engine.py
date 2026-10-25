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

# ── All Personas Parametrization (Milestone 3 requirement) ────

@pytest.mark.parametrize(
    "persona_id,expected_emergency,expected_trigger",
    [
        ("persona_low", False, None),
        ("persona_moderate", False, None),
        ("persona_high", False, None),
        ("persona_emergency_vitals", True, "EMG_VITALS_CRITICAL"),
        ("persona_emergency_keyword", True, "EMG_KEYWORD_MATCH"),
    ],
)
def test_all_personas_emergency_classification(persona_id, expected_emergency, expected_trigger, personas):
    """
    Parametrized regression test running every persona from fixtures/personas.json
    against the deterministic emergency rule engine. Must stay green in CI.
    """
    persona = personas[persona_id]
    result = run(raw_text=persona["raw_text"], **_vitals_kwargs(persona))
    assert result.is_emergency is expected_emergency, (
        f"Persona '{persona_id}' failed: expected is_emergency={expected_emergency}, got {result.is_emergency}"
    )
    if expected_trigger:
        assert any(t["rule_id"] == expected_trigger for t in result.triggers), (
            f"Persona '{persona_id}' missing expected trigger rule '{expected_trigger}'"
        )
    else:
        assert len(result.triggers) == 0, (
            f"Persona '{persona_id}' should have 0 emergency triggers, got: {result.triggers}"
        )


def test_invalid_vitals_persona_rule_behavior(personas):
    """
    persona_invalid_vitals has extreme values (temp=0, HR=0).
    In the pipeline, Stage 2 (vitals_validator) stops these before reaching Stage 3.
    If passed directly to the rule engine, it executes safely without crashing.
    """
    persona = personas["persona_invalid_vitals"]
    result = run(raw_text=persona["raw_text"], **_vitals_kwargs(persona))
    assert isinstance(result.is_emergency, bool)
    assert isinstance(result.triggers, list)


# ── Threshold Boundary Tests (Reference §7 & emergency_rules.yaml) ────

def test_spo2_boundary():
    """SpO2 min threshold is 90%: < 90 trips emergency; >= 90 does not."""
    assert run(raw_text="normal", spo2_pct=89).is_emergency is True
    assert run(raw_text="normal", spo2_pct=90).is_emergency is False
    assert run(raw_text="normal", spo2_pct=98).is_emergency is False


def test_heart_rate_boundaries():
    """Heart rate bounds: max 130 bpm, min 40 bpm."""
    # Upper bound
    assert run(raw_text="normal", heart_rate_bpm=131).is_emergency is True
    assert run(raw_text="normal", heart_rate_bpm=130).is_emergency is False
    # Lower bound
    assert run(raw_text="normal", heart_rate_bpm=39).is_emergency is True
    assert run(raw_text="normal", heart_rate_bpm=40).is_emergency is False


def test_systolic_bp_boundaries():
    """Systolic BP bounds: max 180 mmHg, min 80 mmHg."""
    # Upper bound
    assert run(raw_text="normal", systolic_bp=181).is_emergency is True
    assert run(raw_text="normal", systolic_bp=180).is_emergency is False
    # Lower bound
    assert run(raw_text="normal", systolic_bp=79).is_emergency is True
    assert run(raw_text="normal", systolic_bp=80).is_emergency is False


def test_temperature_boundaries():
    """Temperature bounds: max 104.0°F, min 95.0°F."""
    # Upper bound
    assert run(raw_text="normal", temperature_f=104.1).is_emergency is True
    assert run(raw_text="normal", temperature_f=104.0).is_emergency is False
    # Lower bound
    assert run(raw_text="normal", temperature_f=94.9).is_emergency is True
    assert run(raw_text="normal", temperature_f=95.0).is_emergency is False


def test_keyword_matching_variations():
    """Emergency keywords must match case-insensitively across various sentence structures."""
    assert run(raw_text="Patient reported UNCONSCIOUS after a fall").is_emergency is True
    assert run(raw_text="Severe Chest Pain starting this morning").is_emergency is True
    assert run(raw_text="I CANNOT BREATHE!").is_emergency is True
    assert run(raw_text="Patient observed with severe bleeding").is_emergency is True
    assert run(raw_text="Possible signs of stroke observed").is_emergency is True
    # Non-emergency text
    assert run(raw_text="Mild knee pain when jogging").is_emergency is False
    assert run(raw_text="Slight cough with no other symptoms").is_emergency is False


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
