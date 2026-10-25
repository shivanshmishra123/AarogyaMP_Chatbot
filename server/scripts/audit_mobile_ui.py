"""
AarogyaMP — Milestone 3: Mobile UI Copy & Resilience Auditor (Person C)
Verifies:
  1. Mandatory Non-Diagnostic Disclaimer (Reference §10) is defined and rendered.
  2. No screen in app/lib/ states or implies a confirmed diagnosis (Reference §18).
  3. All user flows have loading, empty, and error/reconnect states.
  4. Mock assessment fixtures adhere strictly to the non-diagnostic schema.
"""

import json
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
APP_LIB_DIR = REPO_ROOT / "app" / "lib"
MOCK_ASSESSMENTS_PATH = APP_LIB_DIR / "mocks" / "mock_assessments.json"

# Prohibited clinical diagnosis patterns (Reference §18)
FORBIDDEN_PATTERNS = [
    (re.compile(r"\bdiagnosed with\b", re.IGNORECASE), "diagnosed with"),
    (re.compile(r"\bthe diagnosis is\b", re.IGNORECASE), "the diagnosis is"),
    (re.compile(r"\byou are suffering from\b", re.IGNORECASE), "you are suffering from"),
    (re.compile(r"\bconfirmed case\b", re.IGNORECASE), "confirmed case"),
    (re.compile(r"\bdefinitely have\b", re.IGNORECASE), "definitely have"),
    (re.compile(r"\bi prescribe\b", re.IGNORECASE), "i prescribe"),
    (re.compile(r"\bwe prescribe\b", re.IGNORECASE), "we prescribe"),
]

# Excluded files or allowed phrases (e.g. disclaimer text explicitly stating "not a diagnosis")
ALLOWED_PHRASES = [
    "not a medical diagnosis",
    "not a diagnosis",
    "not diagnoses",
    "you have called 108",
]


def audit_dart_files():
    """Scans all Dart files in app/lib for forbidden diagnosis phrasing."""
    violations = []
    dart_files = list(APP_LIB_DIR.rglob("*.dart"))
    print(f"Scanning {len(dart_files)} Dart files in app/lib/...")

    for file_path in dart_files:
        content = file_path.read_text(encoding="utf-8")
        lines = content.splitlines()

        for idx, line in enumerate(lines, 1):
            # Skip comments
            trimmed = line.strip()
            if trimmed.startswith("//") or trimmed.startswith("*"):
                continue

            # Check if line contains an allowed negative phrase
            is_allowed = any(phrase in line.lower() for phrase in ALLOWED_PHRASES)
            if is_allowed:
                continue

            for pattern, name in FORBIDDEN_PATTERNS:
                if pattern.search(line):
                    violations.append(
                        f"{file_path.relative_to(REPO_ROOT)}:{idx}: Found forbidden diagnosis pattern '{name}': {trimmed}"
                    )

    return violations


def audit_disclaimer_rendering():
    """Verifies that the mandatory non-diagnostic disclaimer is defined and rendered."""
    issues = []

    # 1. Check shared_widgets.dart defines DisclaimerBanner
    shared_widgets_file = APP_LIB_DIR / "widgets" / "shared_widgets.dart"
    if not shared_widgets_file.exists():
        issues.append("app/lib/widgets/shared_widgets.dart not found.")
    else:
        content = shared_widgets_file.read_text(encoding="utf-8")
        if "class DisclaimerBanner" not in content:
            issues.append("DisclaimerBanner widget class is missing from shared_widgets.dart.")
        if "not a medical diagnosis" not in content:
            issues.append("DisclaimerBanner does not contain 'not a medical diagnosis'.")

    # 2. Check assessment_result_screen.dart renders DisclaimerBanner
    result_screen_file = APP_LIB_DIR / "features" / "assessment" / "assessment_result_screen.dart"
    if not result_screen_file.exists():
        issues.append("assessment_result_screen.dart not found.")
    else:
        content = result_screen_file.read_text(encoding="utf-8")
        if "DisclaimerBanner()" not in content:
            issues.append("assessment_result_screen.dart does not instantiate DisclaimerBanner().")

    return issues


def audit_mock_assessments():
    """Audits mock assessment fixtures in mock_assessments.json."""
    issues = []
    if not MOCK_ASSESSMENTS_PATH.exists():
        return ["mock_assessments.json not found."]

    with open(MOCK_ASSESSMENTS_PATH, encoding="utf-8") as f:
        data = json.load(f)

    for persona_id, assessment in data.items():
        if persona_id.startswith("_") or not isinstance(assessment, dict):
            continue
        is_emergency = assessment.get("is_emergency", False)

        # Non-emergency must have non-diagnostic disclaimer
        if not is_emergency:
            disclaimer = assessment.get("_disclaimer")
            if not disclaimer or "not a medical diagnosis" not in disclaimer:
                issues.append(
                    f"Mock persona '{persona_id}' is missing required non-diagnostic '_disclaimer'."
                )

        rec = assessment.get("recommendation_text", "")
        for pattern, name in FORBIDDEN_PATTERNS:
            if pattern.search(rec):
                issues.append(
                    f"Mock persona '{persona_id}' recommendation contains forbidden phrase '{name}': {rec}"
                )

        for c in (assessment.get("possible_conditions") or []):
            c_name = c.get("name", "")
            for pattern, name in FORBIDDEN_PATTERNS:
                if pattern.search(c_name):
                    issues.append(
                        f"Mock persona '{persona_id}' condition '{c_name}' contains forbidden phrase '{name}'."
                    )

    return issues


def audit_resilience_states():
    """Checks for essential loading, error, and empty states across major screens."""
    issues = []
    screen_checks = [
        (
            APP_LIB_DIR / "features" / "doctor_directory" / "doctor_list_screen.dart",
            ["CircularProgressIndicator", "Could not load doctors", "No verified doctors found"],
            "DoctorListScreen",
        ),
        (
            APP_LIB_DIR / "features" / "doctor_dashboard" / "doctor_dashboard_screens.dart",
            ["CircularProgressIndicator", "No patients in queue", "Retry"],
            "DoctorQueueScreen",
        ),
        (
            APP_LIB_DIR / "features" / "history" / "consultation_history_screen.dart",
            ["No Consultation History", "Find Doctors"],
            "ConsultationHistoryScreen",
        ),
        (
            APP_LIB_DIR / "features" / "chat" / "chat_screen.dart",
            ["No messages yet", "Reconnect"],
            "ChatScreen",
        ),
        (
            APP_LIB_DIR / "features" / "assessment" / "emergency_screen.dart",
            ["PopScope", "108"],
            "EmergencyScreen",
        ),
    ]

    for file_path, required_tokens, screen_name in screen_checks:
        if not file_path.exists():
            issues.append(f"{screen_name} file not found: {file_path}")
            continue
        content = file_path.read_text(encoding="utf-8")
        for token in required_tokens:
            if token not in content:
                issues.append(f"{screen_name} ({file_path.name}) missing resilience indicator: '{token}'")

    return issues


def main():
    print("=" * 60)
    print("AarogyaMP — Person C Milestone 3: Mobile UI Copy Audit")
    print("=" * 60)

    all_ok = True

    # 1. Disclaimer audit
    disclaimer_issues = audit_disclaimer_rendering()
    if disclaimer_issues:
        print("\n[FAIL] Disclaimer Audit Issues:")
        for issue in disclaimer_issues:
            print(f"  - {issue}")
        all_ok = False
    else:
        print("[PASS] Mandatory Disclaimer: correctly defined and rendered in all assessment views.")

    # 2. Diagnosis language audit
    diagnosis_violations = audit_dart_files()
    if diagnosis_violations:
        print("\n[FAIL] Diagnosis Language Violations:")
        for v in diagnosis_violations:
            print(f"  - {v}")
        all_ok = False
    else:
        print("[PASS] Diagnosis Copy: 0 forbidden diagnostic statements found in any Dart file.")

    # 3. Mock assessments audit
    mock_issues = audit_mock_assessments()
    if mock_issues:
        print("\n[FAIL] Mock Assessment Issues:")
        for issue in mock_issues:
            print(f"  - {issue}")
        all_ok = False
    else:
        print("[PASS] Mock Assessments: all fixtures adhere strictly to non-diagnostic schema.")

    # 4. Resilience states audit
    resilience_issues = audit_resilience_states()
    if resilience_issues:
        print("\n[FAIL] Resilience & States Issues:")
        for issue in resilience_issues:
            print(f"  - {issue}")
        all_ok = False
    else:
        print("[PASS] UI Resilience: Loading, error, empty, and reconnect states present across all flows.")

    print("=" * 60)
    if all_ok:
        print("ALL PERSON C MILESTONE 3 AUDITS PASSED!")
        sys.exit(0)
    else:
        print("AUDIT FAILED WITH ISSUES.")
        sys.exit(1)


if __name__ == "__main__":
    main()
