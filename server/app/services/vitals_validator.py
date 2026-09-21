"""
AarogyaMP — Vitals Validator (Milestone 0 stub)
Person A owns this file (it validates range/sanity, not clinical thresholds).

Purpose: flag obviously-invalid vitals (e.g. HR=0, temp=150°F) BEFORE the pipeline
runs — send back to patient for correction, don't silently pass garbage to the LLM.

Clinical thresholds for emergency detection live in emergency_rule_engine.py + emergency_rules.yaml
and are owned by Person B.

TODO (M1 — Person A): Implement range checks.
"""
from typing import List, Optional
from dataclasses import dataclass, field


@dataclass
class VitalsValidationResult:
    is_valid: bool
    flagged_fields: List[str] = field(default_factory=list)
    messages: List[str] = field(default_factory=list)


def validate_vitals(
    temperature_f: Optional[float] = None,
    heart_rate_bpm: Optional[int] = None,
    systolic_bp: Optional[int] = None,
    diastolic_bp: Optional[int] = None,
    spo2_pct: Optional[int] = None,
) -> VitalsValidationResult:
    """
    Range-check vitals for obviously-invalid values.
    This is NOT the clinical emergency-threshold check — see emergency_rule_engine.py.

    Returns flagged field names and human-readable messages for the patient.
    """
    raise NotImplementedError("M1 — Person A")
