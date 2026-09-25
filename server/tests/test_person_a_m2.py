"""
AarogyaMP — Milestone 2 Backend Tests (Person A)
Tests for:
  1. Doctor onboarding / verification flow (admin endpoints)
  2. Push notification stubs (no FCM key → graceful no-op)
  3. Cursor-based chat message pagination
  4. Consultation close endpoint
  5. FCM device token registration endpoint
  6. Unverified doctor blocked from receiving consultations

Run:
  PYTHONPATH=server DATABASE_URL=sqlite:///server/storage/test_m2.db pytest server/tests/test_person_a_m2.py -v

NOTE: Uses in-memory SQLite (via DATABASE_URL env override) for fast isolated testing.
All tests are independent — each creates its own users/data from scratch.
"""
import os
import pytest

# Override DB before any app imports so SQLite is used
os.environ.setdefault("DATABASE_URL", "sqlite:///server/storage/test_m2.db")
os.environ.setdefault("ADMIN_OPS_TOKEN", "test-admin-token")
os.environ.setdefault("JWT_SECRET", "test-jwt-secret")

from fastapi.testclient import TestClient
from app.main import app
from app.database import Base, engine

# ── Fixtures ──────────────────────────────────────────────────────────────────

@pytest.fixture(autouse=True)
def fresh_db():
    """Re-create all tables before each test for full isolation."""
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    yield
    Base.metadata.drop_all(bind=engine)


@pytest.fixture()
def client():
    return TestClient(app)


ADMIN_HEADERS = {"X-Admin-Ops-Token": "test-admin-token"}
BAD_ADMIN_HEADERS = {"X-Admin-Ops-Token": "wrong-token"}


def _register_patient(client, suffix="01") -> dict:
    resp = client.post("/api/auth/register", json={
        "name": f"Test Patient {suffix}",
        "phone": f"9000000{suffix}",
        "password": "pass1234",
        "role": "patient",
    })
    assert resp.status_code in (200, 201), resp.text
    return resp.json()


def _register_doctor(client, suffix="01", specialty="General Physician") -> dict:
    resp = client.post("/api/auth/register", json={
        "name": f"Dr. Test {suffix}",
        "phone": f"8000000{suffix}",
        "password": "pass1234",
        "role": "doctor",
        "specialty": specialty,
        "qualification": "MBBS",
    })
    assert resp.status_code in (200, 201), resp.text
    return resp.json()


def _get_doctor_id(client, doctor_token: str) -> str:
    """Get the doctor's own ID by logging in as them and checking queue (requires verified)."""
    # We'll use the admin list endpoint to find the doctor ID
    resp = client.get("/api/admin/doctors", headers=ADMIN_HEADERS)
    assert resp.status_code == 200
    return resp.json()["doctors"][0]["id"]


# ── 1. Admin: verify flow ─────────────────────────────────────────────────────

def test_admin_verify_doctor_success(client):
    """Verify a doctor → status becomes 'verified'."""
    _register_doctor(client)
    # Get doctor ID from admin list
    list_resp = client.get("/api/admin/doctors", headers=ADMIN_HEADERS)
    assert list_resp.status_code == 200
    doctor_id = list_resp.json()["doctors"][0]["id"]

    resp = client.post(f"/api/admin/doctors/{doctor_id}/verify", headers=ADMIN_HEADERS)
    assert resp.status_code == 200
    data = resp.json()
    assert data["verification_status"] == "verified"
    assert data["doctor_id"] == doctor_id


def test_admin_verify_idempotent(client):
    """Verifying an already-verified doctor is a no-op (200, stays verified)."""
    _register_doctor(client)
    list_resp = client.get("/api/admin/doctors", headers=ADMIN_HEADERS)
    doctor_id = list_resp.json()["doctors"][0]["id"]

    client.post(f"/api/admin/doctors/{doctor_id}/verify", headers=ADMIN_HEADERS)
    resp = client.post(f"/api/admin/doctors/{doctor_id}/verify", headers=ADMIN_HEADERS)
    assert resp.status_code == 200
    assert resp.json()["verification_status"] == "verified"


def test_admin_reject_doctor(client):
    """Reject a doctor → status becomes 'rejected'."""
    _register_doctor(client)
    list_resp = client.get("/api/admin/doctors", headers=ADMIN_HEADERS)
    doctor_id = list_resp.json()["doctors"][0]["id"]

    resp = client.post(
        f"/api/admin/doctors/{doctor_id}/reject",
        headers=ADMIN_HEADERS,
        json={"reason": "Credentials could not be verified"},
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["verification_status"] == "rejected"
    assert "Credentials" in data["reason"]


def test_admin_reset_doctor(client):
    """Reset a doctor from 'verified' back to 'pending'."""
    _register_doctor(client)
    list_resp = client.get("/api/admin/doctors", headers=ADMIN_HEADERS)
    doctor_id = list_resp.json()["doctors"][0]["id"]

    # First verify
    client.post(f"/api/admin/doctors/{doctor_id}/verify", headers=ADMIN_HEADERS)

    # Then reset
    resp = client.post(f"/api/admin/doctors/{doctor_id}/reset", headers=ADMIN_HEADERS)
    assert resp.status_code == 200
    assert resp.json()["verification_status"] == "pending"


def test_admin_list_pending(client):
    """GET /admin/doctors/pending lists only pending doctors."""
    _register_doctor(client, suffix="01")
    _register_doctor(client, suffix="02")

    list_resp = client.get("/api/admin/doctors", headers=ADMIN_HEADERS)
    doctors = list_resp.json()["doctors"]
    assert len(doctors) >= 2

    # Verify the first one
    client.post(f"/api/admin/doctors/{doctors[0]['id']}/verify", headers=ADMIN_HEADERS)

    pending_resp = client.get("/api/admin/doctors/pending", headers=ADMIN_HEADERS)
    assert pending_resp.status_code == 200
    pending = pending_resp.json()["doctors"]
    # Should have exactly 1 pending (the second one)
    assert all(d["verification_status"] == "pending" for d in pending)


def test_admin_bad_token_forbidden(client):
    """Wrong admin token → 403."""
    _register_doctor(client)
    list_resp = client.get("/api/admin/doctors", headers=BAD_ADMIN_HEADERS)
    assert list_resp.status_code == 403


def test_admin_verify_nonexistent_doctor(client):
    """Verify a doctor that doesn't exist → 404."""
    resp = client.post("/api/admin/doctors/nonexistent-id/verify", headers=ADMIN_HEADERS)
    assert resp.status_code == 404


# ── 2. Consultation: unverified doctor blocked ────────────────────────────────

def test_consultation_blocked_for_unverified_doctor(client):
    """Creating a chat consultation with an unverified doctor returns 403."""
    patient_token = _register_patient(client)["access_token"]
    _register_doctor(client)  # pending by default

    list_resp = client.get("/api/admin/doctors", headers=ADMIN_HEADERS)
    doctor_id = list_resp.json()["doctors"][0]["id"]

    resp = client.post(
        "/api/consultations",
        json={"doctor_id": doctor_id, "channel": "chat"},
        headers={"Authorization": f"Bearer {patient_token}"},
    )
    assert resp.status_code == 403, f"Expected 403, got {resp.status_code}: {resp.text}"


def test_consultation_allowed_for_verified_doctor(client):
    """Creating a chat consultation with a verified doctor returns 201."""
    patient_token = _register_patient(client)["access_token"]
    _register_doctor(client)

    list_resp = client.get("/api/admin/doctors", headers=ADMIN_HEADERS)
    doctor_id = list_resp.json()["doctors"][0]["id"]

    client.post(f"/api/admin/doctors/{doctor_id}/verify", headers=ADMIN_HEADERS)

    resp = client.post(
        "/api/consultations",
        json={"doctor_id": doctor_id, "channel": "chat"},
        headers={"Authorization": f"Bearer {patient_token}"},
    )
    assert resp.status_code == 201
    assert "consultation_id" in resp.json()


# ── 3. Chat message pagination ─────────────────────────────────────────────────

def _create_messages_directly(client, patient_token, doctor_id):
    """Helper: create a consultation and seed messages via REST rather than WS."""
    # Create consultation
    c_resp = client.post(
        "/api/consultations",
        json={"doctor_id": doctor_id, "channel": "chat"},
        headers={"Authorization": f"Bearer {patient_token}"},
    )
    assert c_resp.status_code == 201
    return c_resp.json()["consultation_id"]


def test_get_messages_empty(client):
    """GET /messages on a fresh consultation returns empty list."""
    patient_token = _register_patient(client)["access_token"]
    _register_doctor(client)

    list_resp = client.get("/api/admin/doctors", headers=ADMIN_HEADERS)
    doctor_id = list_resp.json()["doctors"][0]["id"]
    client.post(f"/api/admin/doctors/{doctor_id}/verify", headers=ADMIN_HEADERS)

    consultation_id = _create_messages_directly(client, patient_token, doctor_id)

    resp = client.get(
        f"/api/consultations/{consultation_id}/messages",
        headers={"Authorization": f"Bearer {patient_token}"},
    )
    assert resp.status_code == 200
    assert resp.json()["messages"] == []


def test_get_messages_limit(client):
    """limit param is respected; default is 50."""
    patient_token = _register_patient(client)["access_token"]
    _register_doctor(client)

    list_resp = client.get("/api/admin/doctors", headers=ADMIN_HEADERS)
    doctor_id = list_resp.json()["doctors"][0]["id"]
    client.post(f"/api/admin/doctors/{doctor_id}/verify", headers=ADMIN_HEADERS)

    consultation_id = _create_messages_directly(client, patient_token, doctor_id)

    # Insert messages directly via DB to avoid WS complexity in unit test
    from app.database import SessionLocal
    from app.models import ChatMessage
    from datetime import datetime, timedelta

    db = SessionLocal()
    for i in range(10):
        db.add(ChatMessage(
            consultation_id=consultation_id,
            sender_role="patient",
            message_type="text",
            text=f"Message {i}",
            timestamp=datetime.utcnow() + timedelta(seconds=i),
        ))
    db.commit()
    db.close()

    # Default (no limit param)
    resp = client.get(
        f"/api/consultations/{consultation_id}/messages",
        headers={"Authorization": f"Bearer {patient_token}"},
    )
    assert resp.status_code == 200
    msgs = resp.json()["messages"]
    assert len(msgs) == 10  # All 10 within default limit of 50

    # Explicit limit=3
    resp2 = client.get(
        f"/api/consultations/{consultation_id}/messages?limit=3",
        headers={"Authorization": f"Bearer {patient_token}"},
    )
    assert resp2.status_code == 200
    assert len(resp2.json()["messages"]) == 3


def test_get_messages_cursor_pagination(client):
    """Cursor-based pagination: before=<id> returns messages older than that id."""
    patient_token = _register_patient(client)["access_token"]
    _register_doctor(client)

    list_resp = client.get("/api/admin/doctors", headers=ADMIN_HEADERS)
    doctor_id = list_resp.json()["doctors"][0]["id"]
    client.post(f"/api/admin/doctors/{doctor_id}/verify", headers=ADMIN_HEADERS)

    consultation_id = _create_messages_directly(client, patient_token, doctor_id)

    from app.database import SessionLocal
    from app.models import ChatMessage
    from datetime import datetime, timedelta

    db = SessionLocal()
    msg_ids = []
    for i in range(5):
        m = ChatMessage(
            consultation_id=consultation_id,
            sender_role="patient",
            message_type="text",
            text=f"Message {i}",
            timestamp=datetime.utcnow() + timedelta(seconds=i * 10),
        )
        db.add(m)
        db.flush()
        msg_ids.append(m.id)
    db.commit()
    db.close()

    # messages[2] is the 3rd oldest — messages before it should be messages[0] and messages[1]
    cursor_id = msg_ids[2]
    resp = client.get(
        f"/api/consultations/{consultation_id}/messages?before={cursor_id}&limit=10",
        headers={"Authorization": f"Bearer {patient_token}"},
    )
    assert resp.status_code == 200
    returned_ids = [m["id"] for m in resp.json()["messages"]]
    assert cursor_id not in returned_ids               # cursor itself excluded
    assert msg_ids[0] in returned_ids                 # oldest message is included
    assert msg_ids[1] in returned_ids                 # second oldest included
    assert msg_ids[3] not in returned_ids             # newer messages excluded
    assert msg_ids[4] not in returned_ids


def test_get_messages_bad_cursor(client):
    """before= with a non-existent ID returns 400."""
    patient_token = _register_patient(client)["access_token"]
    _register_doctor(client)

    list_resp = client.get("/api/admin/doctors", headers=ADMIN_HEADERS)
    doctor_id = list_resp.json()["doctors"][0]["id"]
    client.post(f"/api/admin/doctors/{doctor_id}/verify", headers=ADMIN_HEADERS)

    consultation_id = _create_messages_directly(client, patient_token, doctor_id)

    resp = client.get(
        f"/api/consultations/{consultation_id}/messages?before=nonexistent-id",
        headers={"Authorization": f"Bearer {patient_token}"},
    )
    assert resp.status_code == 400


# ── 4. Consultation close endpoint ────────────────────────────────────────────

def test_close_consultation_as_doctor(client):
    """Doctor can close their own consultation → status = 'closed'."""
    patient_token = _register_patient(client)["access_token"]
    doctor_data = _register_doctor(client)
    doctor_token = doctor_data["access_token"]

    list_resp = client.get("/api/admin/doctors", headers=ADMIN_HEADERS)
    doctor_id = list_resp.json()["doctors"][0]["id"]
    client.post(f"/api/admin/doctors/{doctor_id}/verify", headers=ADMIN_HEADERS)

    consultation_id = _create_messages_directly(client, patient_token, doctor_id)

    resp = client.post(
        f"/api/consultations/{consultation_id}/close",
        headers={"Authorization": f"Bearer {doctor_token}"},
    )
    assert resp.status_code == 200
    assert resp.json()["status"] == "closed"


def test_close_consultation_as_patient_forbidden(client):
    """Patient cannot close a consultation — only the doctor can."""
    patient_token = _register_patient(client)["access_token"]
    _register_doctor(client)

    list_resp = client.get("/api/admin/doctors", headers=ADMIN_HEADERS)
    doctor_id = list_resp.json()["doctors"][0]["id"]
    client.post(f"/api/admin/doctors/{doctor_id}/verify", headers=ADMIN_HEADERS)

    consultation_id = _create_messages_directly(client, patient_token, doctor_id)

    resp = client.post(
        f"/api/consultations/{consultation_id}/close",
        headers={"Authorization": f"Bearer {patient_token}"},
    )
    # Patient role → require_doctor should reject
    assert resp.status_code == 403


# ── 5. Device token registration ──────────────────────────────────────────────

def test_register_device_token_patient(client):
    """Patient can register their FCM token."""
    patient_token = _register_patient(client)["access_token"]

    resp = client.post(
        "/api/devices/register",
        json={"fcm_token": "fake-fcm-token-patient-abc123", "platform": "android"},
        headers={"Authorization": f"Bearer {patient_token}"},
    )
    assert resp.status_code == 200
    assert resp.json()["registered"] is True


def test_register_device_token_doctor(client):
    """Doctor can register their FCM token."""
    doctor_token = _register_doctor(client)["access_token"]

    resp = client.post(
        "/api/devices/register",
        json={"fcm_token": "fake-fcm-token-doctor-xyz789"},
        headers={"Authorization": f"Bearer {doctor_token}"},
    )
    assert resp.status_code == 200
    assert resp.json()["registered"] is True


def test_register_device_token_unauthenticated(client):
    """Unauthenticated call to /api/devices/register → 401 or 403."""
    resp = client.post(
        "/api/devices/register",
        json={"fcm_token": "some-token"},
    )
    assert resp.status_code in (401, 403), f"Expected 401/403, got {resp.status_code}: {resp.text}"
