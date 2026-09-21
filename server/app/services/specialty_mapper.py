"""
AarogyaMP — Specialty Mapper (Milestone 0 stub)
Person B owns this file.

Cross-checks the LLM's recommended_specialty against the fixed list in
specialty_map.yaml. Falls back to "General Physician" if LLM pick isn't
in the list, per Reference §9.

TODO (M1 — Person B): Load specialty_map.yaml at startup, implement resolve().
"""
from typing import Optional


def resolve(llm_specialty: Optional[str]) -> str:
    """
    Validate the LLM's specialty pick against the fixed specialty list.
    Returns the validated specialty, or "General Physician" as fallback.
    """
    raise NotImplementedError("M1 — Person B")


def get_all_specialties() -> list[str]:
    """Return the full fixed specialty list from specialty_map.yaml."""
    raise NotImplementedError("M1 — Person B")
