"""
AarogyaMP — Milestone 3 Tests: Person B (AI & Clinical Logic Track)
Hardening, Emergency CI Regression, Disclaimer/Diagnosis Copy Audit, and Degraded-Path Telemetry

Test coverage:
  1. Emergency Rule Engine CI Regression (all personas in fixtures/personas.json)
  2. Clinical Copy Audit: forbidden diagnosis language scanning & required hedging verification
  3. Assessment Router Emergency Short-Circuit (LLM skipped, deterministic < 1s)
  4. Assessment Router Degraded-Path Handling (ai_status="unavailable", fallback MODERATE)
  5. AI Symptom Engine Telemetry & Availability Rate Tracking
"""
import asyncio
import json
from pathlib import Path
from unittest.mock import AsyncMock, patch

import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.schemas import LLMAssessmentOutput, PossibleCondition
from app.services import ai_symptom_engine, emergency_rule_engine
from scripts.audit_all_personas import (
    scan_conditions_for_diagnosis,
    scan_for_diagnosis_language,
)

FIXTURES_PATH = Path(__file__).parent / "fixtures" / "personas.json"


@pytest.fixture
def personas():
    with open(FIXTURES_PATH, encoding="utf-8") as f:
        data = json.load(f)
    return {p["id"]: p for p in data["personas"]}


@pytest.fixture
def client():
    return TestClient(app)


# ── 1. Emergency CI Regression for Every Persona ─────────────

def test_every_persona_tested_against_emergency_expectation(personas):
    """
    Every persona fixture with defined expected.is_emergency must match exactly.
    This guarantees no emergency persona slips through as non-emergency,
    and no low/moderate persona is falsely flagged.
    """
    for persona_id, p in personas.items():
        expected = p.get("expected", {})
        if "is_emergency" not in expected:
            continue
        v = p.get("vitals", {})
        result = emergency_rule_engine.run(
            raw_text=p["raw_text"],
            temperature_f=v.get("temperature_f"),
            heart_rate_bpm=v.get("heart_rate_bpm"),
            systolic_bp=v.get("systolic_bp"),
            diastolic_bp=v.get("diastolic_bp"),
            spo2_pct=v.get("spo2_pct"),
        )
        assert result.is_emergency is expected["is_emergency"], (
            f"Persona '{persona_id}' failed: expected is_emergency={expected['is_emergency']}, "
            f"got {result.is_emergency} (triggers={result.triggers})"
        )
        if expected["is_emergency"]:
            expected_trigger = expected.get("emergency_triggers_should_include")
            if expected_trigger:
                assert any(t["rule_id"] == expected_trigger for t in result.triggers)


# ── 2. Clinical Copy Audit & Diagnosis Language Scanner ────────

def test_forbidden_diagnosis_patterns_are_flagged():
    """
    Ensure the diagnosis-language detector strictly catches all definitive diagnosis
    and prescriptive statements (Reference §18).
    """
    forbidden_samples = [
        "You have acute bronchitis.",
        "You are suffering from malaria.",
        "You are diagnosed with pneumonia.",
        "The diagnosis is bacterial sinusitis.",
        "This is a confirmed case of typhoid.",
        "You definitely have a cardiac condition.",
        "Take 500mg paracetamol every 6 hours.",
        "I prescribe antibiotics for this.",
    ]
    for sample in forbidden_samples:
        violations, _ = scan_for_diagnosis_language(sample)
        assert len(violations) > 0, f"Failed to flag forbidden statement: '{sample}'"


def test_safe_hedged_recommendation_language_passes():
    """
    Actionable next-step guidance with proper hedging must pass without violations.
    """
    safe_samples = [
        "Possible viral upper respiratory illness. Consult a general physician. Seek immediate care if breathing worsens.",
        "Symptoms may suggest mild tension headache. Monitor symptoms and schedule a doctor visit if pain persists.",
        "Potential signs of allergic dermatitis. Consider consulting a dermatologist for evaluation.",
    ]
    for sample in safe_samples:
        violations, warnings = scan_for_diagnosis_language(sample)
        assert len(violations) == 0, f"False-positive violation on safe text: '{sample}': {violations}"
        assert len(warnings) == 0, f"Unexpected warning on well-hedged text: '{sample}': {warnings}"


def test_condition_names_diagnosis_scan():
    """Condition names must describe potential conditions without saying 'You have X'."""
    bad_conditions = [
        {"name": "You have hypertension", "likelihood": "high"},
        {"name": "Diagnosis: Asthma", "likelihood": "medium"},
    ]
    violations = scan_conditions_for_diagnosis(bad_conditions)
    assert len(violations) == 2, f"Failed to detect diagnosis in condition names: {violations}"

    good_conditions = [
        {"name": "Viral upper respiratory tract infection", "likelihood": "high"},
        {"name": "Acute tension headache", "likelihood": "medium"},
    ]
    violations = scan_conditions_for_diagnosis(good_conditions)
    assert len(violations) == 0, f"False positive on condition names: {violations}"


# ── 3. Assessment Router: Emergency Short-Circuit ─────────────

def test_assessment_endpoint_emergency_vitals_short_circuits(client, personas):
    """
    Emergency persona sent to POST /api/assessments must return immediately
    with is_emergency=True, risk_level=EMERGENCY, and ai_status=skipped.
    The LLM must never be invoked.
    """
    persona = personas["persona_emergency_vitals"]
    payload = {
        "raw_text": persona["raw_text"],
        "input_mode": persona["input_mode"],
        "duration_text": persona.get("duration_text"),
        "vitals": persona.get("vitals"),
    }
    with patch("app.services.ai_symptom_engine.analyze") as mock_analyze:
        resp = client.post("/api/assessments", json=payload)
        assert resp.status_code == 200
        data = resp.json()
        assert data["is_emergency"] is True
        assert data["risk_level"] == "EMERGENCY"
        assert data["ai_status"] == "skipped"
        assert data["possible_conditions"] is None
        assert data["recommended_specialty"] is None
        assert len(data["emergency_triggers"]) > 0
        # Verification that LLM was skipped
        mock_analyze.assert_not_called()


def test_assessment_endpoint_emergency_keyword_short_circuits(client, personas):
    """
    Emergency keyword persona must short-circuit without calling the LLM.
    """
    persona = personas["persona_emergency_keyword"]
    payload = {
        "raw_text": persona["raw_text"],
        "input_mode": persona["input_mode"],
        "duration_text": persona.get("duration_text"),
        "vitals": persona.get("vitals"),
    }
    with patch("app.services.ai_symptom_engine.analyze") as mock_analyze:
        resp = client.post("/api/assessments", json=payload)
        assert resp.status_code == 200
        data = resp.json()
        assert data["is_emergency"] is True
        assert data["risk_level"] == "EMERGENCY"
        assert data["ai_status"] == "skipped"
        mock_analyze.assert_not_called()


# ── 4. Assessment Router: Degraded Path (ai_status="unavailable")

def test_assessment_endpoint_degraded_path_on_llm_failure(client, personas):
    """
    When the LLM engine fails or is unavailable, the router must NOT crash with 500.
    It must return 200 with risk_level=MODERATE minimum, ai_status=unavailable,
    and a safe physician consultation recommendation.
    """
    persona = personas["persona_moderate"]
    payload = {
        "raw_text": persona["raw_text"],
        "input_mode": persona["input_mode"],
        "duration_text": persona.get("duration_text"),
        "vitals": persona.get("vitals"),
    }
    with patch("app.services.ai_symptom_engine.analyze", return_value=(None, "unavailable")):
        resp = client.post("/api/assessments", json=payload)
        assert resp.status_code == 200
        data = resp.json()
        assert data["is_emergency"] is False
        assert data["risk_level"] == "MODERATE"
        assert data["ai_status"] == "unavailable"
        assert data["recommended_specialty"] == "General Physician"
        assert data["possible_conditions"] is None
        assert "temporarily unavailable" in data["recommendation_text"]
        # Audit recommendation text
        violations, _ = scan_for_diagnosis_language(data["recommendation_text"])
        assert len(violations) == 0


def test_assessment_endpoint_successful_ai_flow(client, personas):
    """
    When AI returns valid output, the router structures the response and
    cross-references the specialty from specialty_map.yaml.
    """
    persona = personas["persona_moderate"]
    payload = {
        "raw_text": persona["raw_text"],
        "input_mode": persona["input_mode"],
        "duration_text": persona.get("duration_text"),
        "vitals": persona.get("vitals"),
    }
    mock_ai_output = LLMAssessmentOutput(
        risk_level="MODERATE",
        confidence="medium",
        possible_conditions=[
            PossibleCondition(name="Viral/febrile illness", likelihood="high"),
            PossibleCondition(name="Influenza-like illness", likelihood="medium"),
        ],
        supporting_symptoms=["fever", "body pain", "headache"],
        recommended_specialty="General Physician",
        recommendation_text="Consult a general physician for evaluation. Rest and stay hydrated.",
        disclaimer="This is an AI-generated possible-conditions read, not a medical diagnosis.",
    )
    with patch("app.services.ai_symptom_engine.analyze", return_value=(mock_ai_output, "ok")):
        resp = client.post("/api/assessments", json=payload)
        assert resp.status_code == 200
        data = resp.json()
        assert data["is_emergency"] is False
        assert data["risk_level"] == "MODERATE"
        assert data["ai_status"] == "ok"
        assert data["recommended_specialty"] == "General Physician"
        assert len(data["possible_conditions"]) == 2
        # Check diagnosis audit on recommendation_text
        violations, _ = scan_for_diagnosis_language(data["recommendation_text"])
        assert len(violations) == 0


# ── 5. AI Telemetry & Availability Rate Monitoring ─────────────

def test_ai_telemetry_metrics_tracking():
    """
    Verify that AI symptom engine telemetry accurately tracks total requests,
    successes, failures, and calculated unavailable rate.
    """
    ai_symptom_engine.reset_ai_metrics()
    initial = ai_symptom_engine.get_ai_metrics()
    assert initial["total_requests"] == 0
    assert initial["unavailable_rate"] == 0.0

    # Simulate 3 successful and 1 failed calls
    ai_symptom_engine._record_metric_success()
    ai_symptom_engine._record_metric_success()
    ai_symptom_engine._record_metric_success()
    ai_symptom_engine._record_metric_failure("connection_timeout")

    metrics = ai_symptom_engine.get_ai_metrics()
    assert metrics["total_requests"] == 4
    assert metrics["successful_analyses"] == 3
    assert metrics["unavailable_analyses"] == 1
    assert metrics["unavailable_rate"] == 0.25
    assert metrics["unavailable_percentage"] == "25.0%"
    assert metrics["last_failure_reason"] == "connection_timeout"
    assert metrics["last_failure_timestamp"] is not None

    # Reset metrics
    ai_symptom_engine.reset_ai_metrics()
    cleared = ai_symptom_engine.get_ai_metrics()
    assert cleared["total_requests"] == 0
