"""
AarogyaMP — Emergency Rule Engine (Milestone 1)
Person B owns this file.

⚠️  SAFETY-CRITICAL FILE — READ BEFORE EDITING:
    - This is the deterministic safety floor. It runs BEFORE the LLM (Stage 3 of pipeline).
    - If this returns is_emergency=True, the LLM is SKIPPED ENTIRELY (ai_status="skipped").
    - A crash, timeout, or unavailable LLM must NEVER suppress an emergency flag.
    - Thresholds and keyword lists in emergency_rules.yaml must be authored/approved
      by a qualified clinician — see AGENTS.md rule 4 and Reference §18.
    - Never invent or guess thresholds. Flag the requirement; don't fill in values.

Rules are loaded from server/app/data/emergency_rules.yaml ONCE at module import
(pure in-memory logic after that — no repeated file I/O).
"""
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Optional

import yaml


# ── Result dataclass ──────────────────────────────────────────

@dataclass
class EmergencyResult:
    is_emergency: bool
    triggers: List[dict] = field(default_factory=list)   # [{rule_id, description}]


# ── Load rules once at module import ─────────────────────────

_RULES_PATH = Path(__file__).parent.parent / "data" / "emergency_rules.yaml"


def _load_rules() -> List[dict]:
    """Load emergency rules from YAML. Called once at import time."""
    with open(_RULES_PATH, encoding="utf-8") as f:
        data = yaml.safe_load(f)
    return data.get("emergency_rules", [])


_RULES: List[dict] = _load_rules()


def _get_rule(rule_id: str) -> dict:
    """Look up a rule by its ID from the pre-loaded rules list."""
    for rule in _RULES:
        if rule.get("id") == rule_id:
            return rule
    return {}


# ── Individual rule checks ───────────────────────────────────

def _check_vitals_critical(
    temperature_f: Optional[float],
    heart_rate_bpm: Optional[int],
    systolic_bp: Optional[int],
    diastolic_bp: Optional[int],
    spo2_pct: Optional[int],
) -> Optional[dict]:
    """
    EMG_VITALS_CRITICAL: compare each provided vital against the
    clinician-approved thresholds in emergency_rules.yaml.
    Returns a trigger dict if ANY vital breaches a threshold, else None.
    If thresholds are null/missing, no trigger fires (safe default).
    """
    rule = _get_rule("EMG_VITALS_CRITICAL")
    thresholds: Dict = rule.get("thresholds", {})
    if not thresholds:
        return None

    reasons: List[str] = []

    # Temperature
    if temperature_f is not None:
        t_max = thresholds.get("temperature_f_max")
        t_min = thresholds.get("temperature_f_min")
        if t_max is not None and temperature_f > t_max:
            reasons.append(f"Temperature {temperature_f}°F exceeds {t_max}°F")
        if t_min is not None and temperature_f < t_min:
            reasons.append(f"Temperature {temperature_f}°F below {t_min}°F")

    # Heart rate
    if heart_rate_bpm is not None:
        hr_max = thresholds.get("heart_rate_bpm_max")
        hr_min = thresholds.get("heart_rate_bpm_min")
        if hr_max is not None and heart_rate_bpm > hr_max:
            reasons.append(f"Heart rate {heart_rate_bpm} bpm exceeds {hr_max} bpm")
        if hr_min is not None and heart_rate_bpm < hr_min:
            reasons.append(f"Heart rate {heart_rate_bpm} bpm below {hr_min} bpm")

    # Systolic BP
    if systolic_bp is not None:
        sbp_max = thresholds.get("systolic_bp_max")
        sbp_min = thresholds.get("systolic_bp_min")
        if sbp_max is not None and systolic_bp > sbp_max:
            reasons.append(f"Systolic BP {systolic_bp} mmHg exceeds {sbp_max} mmHg")
        if sbp_min is not None and systolic_bp < sbp_min:
            reasons.append(f"Systolic BP {systolic_bp} mmHg below {sbp_min} mmHg")

    # SpO2
    if spo2_pct is not None:
        spo2_min = thresholds.get("spo2_pct_min")
        if spo2_min is not None and spo2_pct < spo2_min:
            reasons.append(f"SpO2 {spo2_pct}% below {spo2_min}%")

    if reasons:
        return {
            "rule_id": "EMG_VITALS_CRITICAL",
            "description": "Vitals indicate potential emergency: " + "; ".join(reasons),
        }
    return None


def _check_keyword_match(raw_text: str) -> Optional[dict]:
    """
    EMG_KEYWORD_MATCH: check if the patient's own words contain any
    clinician-approved emergency keywords.
    Returns a trigger dict if ANY keyword matches, else None.
    If keyword list is empty, no trigger fires (safe default).
    """
    rule = _get_rule("EMG_KEYWORD_MATCH")
    keywords: List[str] = rule.get("keywords", [])
    if not keywords:
        return None

    text_lower = raw_text.lower()
    matched = [kw for kw in keywords if kw.lower() in text_lower]

    if matched:
        return {
            "rule_id": "EMG_KEYWORD_MATCH",
            "description": (
                "Patient description matches emergency keywords: "
                + ", ".join(matched)
            ),
        }
    return None


def _check_combination(
    raw_text: str,
    temperature_f: Optional[float],
    heart_rate_bpm: Optional[int],
    systolic_bp: Optional[int],
    diastolic_bp: Optional[int],
    spo2_pct: Optional[int],
) -> Optional[dict]:
    """
    EMG_COMBINATION: check if a specific combination of symptoms + vitals
    meets an emergency pattern defined by a clinician.
    Returns a trigger dict if any combination matches, else None.
    If combinations list is empty, no trigger fires (safe default).
    """
    rule = _get_rule("EMG_COMBINATION")
    combinations: List[dict] = rule.get("combinations", [])
    if not combinations:
        return None

    # Combination logic will be implemented once a clinician defines
    # the specific patterns. Structure is ready to receive them.
    return None


# ── Public API ────────────────────────────────────────────────

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

    Must complete in well under 1 second (no I/O, pure logic after module load).
    """
    triggers: List[dict] = []

    # Rule 1: Critical vitals
    vitals_trigger = _check_vitals_critical(
        temperature_f, heart_rate_bpm, systolic_bp, diastolic_bp, spo2_pct,
    )
    if vitals_trigger:
        triggers.append(vitals_trigger)

    # Rule 2: Emergency keyword match
    keyword_trigger = _check_keyword_match(raw_text)
    if keyword_trigger:
        triggers.append(keyword_trigger)

    # Rule 3: Symptom + vitals combination
    combo_trigger = _check_combination(
        raw_text, temperature_f, heart_rate_bpm, systolic_bp, diastolic_bp, spo2_pct,
    )
    if combo_trigger:
        triggers.append(combo_trigger)

    return EmergencyResult(
        is_emergency=len(triggers) > 0,
        triggers=triggers,
    )
