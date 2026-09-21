"""
AarogyaMP — Emergency Rule Engine (Milestone 0 stub)
Person B owns this file.

⚠️  SAFETY-CRITICAL FILE — READ BEFORE EDITING:
    - This is the deterministic safety floor. It runs BEFORE the LLM (Stage 3 of pipeline).
    - If this returns is_emergency=True, the LLM is SKIPPED ENTIRELY (ai_status="skipped").
    - A crash, timeout, or unavailable LLM must NEVER suppress an emergency flag.
    - Thresholds and keyword lists in emergency_rules.yaml must be authored/approved
      by a qualified clinician — see AGENTS.md rule 4 and Reference §18.
    - Never invent or guess thresholds. Flag the requirement; don't fill in values.

Rules are loaded from server/app/data/emergency_rules.yaml at startup.

TODO (M1 — Person B): Implement deterministic rule checks.
  REQUIRED: Unit tests in server/tests/test_emergency_rule_engine.py must pass
  for every persona in fixtures/personas.json before this ships.
"""
from dataclasses import dataclass, field
from typing import List, Optional


@dataclass
class EmergencyResult:
    is_emergency: bool
    triggers: List[dict] = field(default_factory=list)   # [{rule_id, description}]


def run(
    raw_text: str,
    temperature_f: Optional[float] = None,
    heart_rate_bpm: Optional[int] = None,
    systolic_bp: Optional[int] = None,
    diastolic_bp: Optional[int] = None,
    spo2_pct: Optional[int] = None,
) -> EmergencyResult:
    """
    Deterministic emergency check. Returns immediately with is_emergency=True
    if any rule trips — no LLM call follows.

    Must complete in well under 1 second (no I/O, pure logic).
    """
    raise NotImplementedError("M1 — Person B: implement against emergency_rules.yaml")
