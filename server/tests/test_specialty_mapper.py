"""
AarogyaMP — Specialty Mapper Tests (Milestone 1)
Person B owns this file.

Run: pytest server/tests/test_specialty_mapper.py -v
"""
import pytest

from app.services.specialty_mapper import get_all_specialties, resolve


# ── Valid specialties are returned as-is ──────────────────────

def test_exact_match():
    assert resolve("General Physician") == "General Physician"


def test_exact_match_cardiologist():
    assert resolve("Cardiologist") == "Cardiologist"


def test_exact_match_neurologist():
    assert resolve("Neurologist") == "Neurologist"


# ── Case-insensitive matching ─────────────────────────────────

def test_case_insensitive():
    assert resolve("general physician") == "General Physician"


def test_case_insensitive_mixed():
    assert resolve("CARDIOLOGIST") == "Cardiologist"


# ── Whitespace handling ───────────────────────────────────────

def test_whitespace_stripped():
    assert resolve("  Dermatologist  ") == "Dermatologist"


# ── Invalid / unknown specialties → fallback ──────────────────

def test_unknown_specialty_falls_back():
    assert resolve("Rocket Scientist") == "General Physician"


def test_empty_string_falls_back():
    assert resolve("") == "General Physician"


def test_none_falls_back():
    assert resolve(None) == "General Physician"


# ── get_all_specialties ───────────────────────────────────────

def test_get_all_specialties_not_empty():
    specialties = get_all_specialties()
    assert len(specialties) > 0


def test_get_all_specialties_contains_general_physician():
    assert "General Physician" in get_all_specialties()


def test_get_all_specialties_contains_cardiologist():
    assert "Cardiologist" in get_all_specialties()


def test_get_all_specialties_matches_yaml_count():
    """specialty_map.yaml has 13 specialties."""
    assert len(get_all_specialties()) == 13
