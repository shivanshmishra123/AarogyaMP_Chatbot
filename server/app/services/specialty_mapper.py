"""
AarogyaMP — Specialty Mapper (Milestone 1)
Person B owns this file.

Loads specialty_map.yaml ONCE at module import, then provides:
  - resolve(llm_specialty) → validated specialty or "General Physician" fallback
  - get_all_specialties()  → full fixed specialty list (fed to LLM prompt)

The LLM must pick recommended_specialty ONLY from this fixed list.
If its pick isn't in the list, we fall back to General Physician (Reference §9).
"""
from pathlib import Path
from typing import List, Optional

import yaml


# ── Load specialty map once at module import ─────────────────

_MAP_PATH = Path(__file__).parent.parent / "data" / "specialty_map.yaml"


def _load_specialty_map() -> dict:
    """Load specialty_map.yaml. Called once at import time."""
    with open(_MAP_PATH, encoding="utf-8") as f:
        return yaml.safe_load(f)


_MAP_DATA: dict = _load_specialty_map()
_DEFAULT_SPECIALTY: str = _MAP_DATA.get("default_specialty", "General Physician")

# Build the fixed list of valid specialties
_VALID_SPECIALTIES: List[str] = [
    rule["specialty"]
    for rule in _MAP_DATA.get("specialty_rules", [])
    if "specialty" in rule
]


# ── Public API ────────────────────────────────────────────────

def resolve(llm_specialty: Optional[str]) -> str:
    """
    Validate the LLM's specialty pick against the fixed specialty list.
    Returns the validated specialty, or "General Physician" as fallback.

    Case-insensitive comparison so minor casing differences from the LLM
    don't cause unnecessary fallbacks.
    """
    if not llm_specialty:
        return _DEFAULT_SPECIALTY

    # Build a lowercase lookup map for case-insensitive matching
    lower_map = {s.lower(): s for s in _VALID_SPECIALTIES}
    matched = lower_map.get(llm_specialty.strip().lower())

    if matched:
        return matched

    return _DEFAULT_SPECIALTY


def get_all_specialties() -> List[str]:
    """Return the full fixed specialty list from specialty_map.yaml."""
    return list(_VALID_SPECIALTIES)
