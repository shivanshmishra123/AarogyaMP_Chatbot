"""
AarogyaMP — Milestone 3 Tests: Person C (Mobile App Track)
Verifies:
  1. Mandatory Non-Diagnostic Disclaimer (Reference §10) is defined and rendered.
  2. No screen in app/lib/ states or implies a confirmed diagnosis (Reference §18).
  3. All mock assessment responses follow the non-diagnostic schema.
  4. Essential UI resilience states (loading, empty, error/reconnect) exist across all flows.
"""

from scripts.audit_mobile_ui import (
    audit_dart_files,
    audit_disclaimer_rendering,
    audit_mock_assessments,
    audit_resilience_states,
)


def test_ui_disclaimer_rendering():
    """Ensure the mandatory non-diagnostic disclaimer is defined and rendered."""
    issues = audit_disclaimer_rendering()
    assert len(issues) == 0, f"Disclaimer rendering audit failed: {issues}"


def test_no_diagnosis_language_in_mobile_code():
    """Ensure no Dart file contains forbidden definitive diagnosis phrasing."""
    violations = audit_dart_files()
    assert len(violations) == 0, f"Diagnosis language violations found: {violations}"


def test_mock_assessments_compliance():
    """Ensure all mock assessment fixtures adhere to the non-diagnostic schema."""
    issues = audit_mock_assessments()
    assert len(issues) == 0, f"Mock assessment audit failed: {issues}"


def test_ui_resilience_and_states():
    """Ensure loading, error, empty, and reconnect states are present across screens."""
    issues = audit_resilience_states()
    assert len(issues) == 0, f"UI resilience states audit failed: {issues}"
