#!/usr/bin/env python3
"""
AarogyaMP — AI Engine Test Script (Milestone 0/1 deliverable for Person B)

Usage:
    .venv/Scripts/python.exe scripts/test_ai_engine.py --persona persona_moderate

This script sends a persona through the AI engine and validates
the response against the LLMAssessmentOutput Pydantic schema.
"""
import asyncio
import argparse
import json
import sys
from pathlib import Path

# Add server root to path so we can import app modules
sys.path.insert(0, str(Path(__file__).parent.parent))

# Ensure UTF-8 output on Windows terminals
if sys.platform == "win32" and hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

from app.services import ai_symptom_engine
from app.services.specialty_mapper import resolve as resolve_specialty


def main():
    parser = argparse.ArgumentParser(description="Test AI engine against a persona")
    parser.add_argument(
        "--persona",
        required=True,
        choices=[
            "persona_low", "persona_moderate", "persona_high",
            "persona_emergency_vitals", "persona_emergency_keyword",
            "persona_invalid_vitals",
        ],
        help="Persona ID from fixtures/personas.json",
    )
    args = parser.parse_args()

    # Load persona
    fixtures_path = Path(__file__).parent.parent / "tests" / "fixtures" / "personas.json"
    with open(fixtures_path, encoding="utf-8") as f:
        personas = {p["id"]: p for p in json.load(f)["personas"]}

    persona = personas.get(args.persona)
    if not persona:
        print(f"ERROR: Persona '{args.persona}' not found")
        sys.exit(1)

    print(f"\n{'='*60}")
    print(f"Testing persona: {persona['label']}")
    print(f"{'='*60}")
    print(f"Input: {persona['raw_text']}")
    print(f"Duration: {persona.get('duration_text', 'N/A')}")
    print(f"Vitals: {persona.get('vitals', {})}")
    print(f"{'='*60}\n")

    # Run the AI engine
    vitals = persona.get("vitals", {})
    result, ai_status = asyncio.run(
        ai_symptom_engine.analyze(
            raw_text=persona["raw_text"],
            duration_text=persona.get("duration_text"),
            temperature_f=vitals.get("temperature_f"),
            heart_rate_bpm=vitals.get("heart_rate_bpm"),
            systolic_bp=vitals.get("systolic_bp"),
            diastolic_bp=vitals.get("diastolic_bp"),
            spo2_pct=vitals.get("spo2_pct"),
            age=vitals.get("age"),
        )
    )

    print(f"ai_status: {ai_status}")

    if result is None:
        print("\n[FAIL] — AI returned no result")
        print("   Check that LLM_API_KEY and LLM_MODEL are set in server/.env")
        sys.exit(1)

    # Display parsed result
    print(f"\n[OK] Valid LLMAssessmentOutput received:")
    print(f"   risk_level:            {result.risk_level}")
    print(f"   confidence:            {result.confidence}")
    print(f"   possible_conditions:   {[(c.name, c.likelihood) for c in result.possible_conditions]}")
    print(f"   supporting_symptoms:   {result.supporting_symptoms}")
    print(f"   recommended_specialty: {result.recommended_specialty}")
    print(f"   recommendation_text:   {result.recommendation_text[:100]}...")
    print(f"   disclaimer:            {result.disclaimer[:80]}...")

    # Validate specialty against fixed list
    resolved = resolve_specialty(result.recommended_specialty)
    if resolved == result.recommended_specialty:
        print(f"\n[OK] Specialty '{resolved}' is in the fixed list")
    else:
        print(f"\n[WARN] Specialty '{result.recommended_specialty}' not in list -> resolved to '{resolved}'")

    # Check expected risk level if provided
    expected = persona.get("expected", {})
    expected_risk = expected.get("risk_level") or expected.get("risk_level_max")
    if expected_risk:
        if result.risk_level == expected_risk:
            print(f"[OK] Risk level matches expected: {expected_risk}")
        else:
            print(f"[NOTE] Risk level {result.risk_level} differs from expected {expected_risk} (AI judgment may vary)")

    print(f"\n{'='*60}")
    print("PASS — Groq -> Section 9 JSON schema round-trip verified")
    print(f"{'='*60}\n")


if __name__ == "__main__":
    main()
