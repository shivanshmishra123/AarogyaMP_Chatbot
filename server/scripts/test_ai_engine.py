#!/usr/bin/env python3
"""
AarogyaMP — AI Engine Test Script (Milestone 0 deliverable for Person B)

Usage:
    python -m server.scripts.test_ai_engine --persona moderate_fever
    python -m server.scripts.test_ai_engine --persona emergency_vitals

This script is Person B's M0 exit criterion: prove Groq → §9 JSON schema round-trip
works before building the full pipeline.

It reads a persona from fixtures/personas.json, sends it directly to the Groq API
(bypassing the rule engine — this is just for testing the AI layer), and validates
the response against the LLMAssessmentOutput Pydantic schema.

TODO (M0 — Person B): Implement this script.
"""
import argparse
import json
import sys
from pathlib import Path

# Add server root to path so we can import app modules
sys.path.insert(0, str(Path(__file__).parent.parent.parent))


def main():
    parser = argparse.ArgumentParser(description="Test AI engine against a persona")
    parser.add_argument(
        "--persona",
        required=True,
        choices=["persona_low", "persona_moderate", "persona_high", "persona_emergency_vitals", "persona_emergency_keyword", "persona_invalid_vitals"],
        help="Persona ID from fixtures/personas.json"
    )
    args = parser.parse_args()

    # Load persona
    fixtures_path = Path(__file__).parent.parent / "tests" / "fixtures" / "personas.json"
    with open(fixtures_path) as f:
        personas = {p["id"]: p for p in json.load(f)["personas"]}

    persona = personas.get(args.persona)
    if not persona:
        print(f"ERROR: Persona '{args.persona}' not found")
        sys.exit(1)

    print(f"\n{'='*60}")
    print(f"Testing persona: {persona['label']}")
    print(f"{'='*60}")
    print(f"Input: {persona['raw_text']}")
    print(f"Vitals: {persona.get('vitals', {})}")
    print(f"{'='*60}\n")

    # TODO (M0 — Person B):
    # 1. Load config (LLM_BASE_URL, LLM_API_KEY, LLM_MODEL from .env)
    # 2. Call ai_symptom_engine.analyze() with persona data
    # 3. Print the result
    # 4. Validate against LLMAssessmentOutput schema
    # 5. Print PASS/FAIL

    print("TODO: Implement AI engine call (Person B M0 task)")
    print("Expected: Valid JSON matching LLMAssessmentOutput schema from schemas.py §9")


if __name__ == "__main__":
    main()
