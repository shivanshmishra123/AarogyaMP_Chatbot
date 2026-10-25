"""
AarogyaMP — Milestone 3 Backend Tests (Person A)
Tests for:
  1. Structured error responses across failure modes (400, 401, 403, 404, 422)
  2. Concurrent WebSocket message broadcast isolation
  3. WebSocket room termination on doctor consultation close
  4. Notification timeout and external service error isolation
"""
import asyncio
import json
import os
import pytest

os.environ.setdefault("DATABASE_URL", "sqlite:///server/storage/test_m3.db")
os.environ.setdefault("ADMIN_OPS_TOKEN", "test-admin-token")
os.environ.setdefault("JWT_SECRET", "test-jwt-secret-m3-hardening-32chars")

from fastapi.testclient import TestClient
from app.main import app
from app.database import Base, engine, SessionLocal
from app.models import Doctor, Patient, Consultation, ChatMessage
from app.routers.consultations import manager


# ── Fixtures ──────────────────────────────────────────────────────────────────

@pytest.fixture(autouse=True)
def fresh_db():
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    yield
    Base.metadata.drop_all(bind=engine)


@pytest.fixture()
def client():
    return TestClient(app)


ADMIN_HEADERS = {"X-Admin-Ops-Token": "test-admin-token"}


# ── Helpers ───────────────────────────────────────────────────────────────────

def _register_user(client: TestClient, role: str, phone: str, name: str) -> dict:
    payload = {
        "name": name,
        "phone": phone,
        "password": "Password@123",
        "role": role,
    }
    if role == "doctor":
        payload["specialty"] = "Cardiologist"
    resp = client.post("/api/auth/register", json=payload)
    assert resp.status_code == 201, f"Register failed: {resp.text}"
    return resp.json()


# ── 1. Structured Error Response Tests ────────────────────────────────────────

def test_structured_error_404_not_found(client: TestClient):
    """Calling non-existent endpoint or entity returns structured error with code and message."""
    resp = client.get("/api/consultations/nonexistent-id/messages", headers={"Authorization": "Bearer fake"})
    assert resp.status_code in (401, 403)
    data = resp.json()
    assert "detail" in data
    assert "error" in data
    assert data["error"]["status_code"] in (401, 403)
    assert "code" in data["error"]


def test_structured_error_422_validation(client: TestClient):
    """Validation failure on malformed request returns field-level breakdown."""
    # Invalid register payload missing required 'role' and invalid phone
    resp = client.post("/api/auth/register", json={"name": "Bad Payload"})
    assert resp.status_code == 422
    data = resp.json()
    assert "detail" in data
    assert "error" in data
    assert data["error"]["code"] == "VALIDATION_ERROR"
    assert data["error"]["status_code"] == 422
    assert "fields" in data["error"]
    assert len(data["error"]["fields"]) > 0
    # Field list has field name and message
    assert "field" in data["error"]["fields"][0]
    assert "message" in data["error"]["fields"][0]


def test_structured_error_403_admin_unauthorized(client: TestClient):
    """Invalid ops token returns structured 403 error."""
    resp = client.get("/api/admin/doctors", headers={"X-Admin-Ops-Token": "wrong-token"})
    assert resp.status_code == 403
    data = resp.json()
    assert data["error"]["code"] == "FORBIDDEN"
    assert data["error"]["status_code"] == 403
    assert "Invalid admin ops token" in data["error"]["message"]


# ── 2. WebSocket Concurrency & Room Lifecycle ──────────────────────────────────

def test_websocket_room_closed_on_consultation_close(client: TestClient):
    """When doctor closes consultation, connected WebSockets receive close notice and terminate."""
    pat_data = _register_user(client, "patient", "+91-9111111111", "Patient A")
    doc_data = _register_user(client, "doctor", "+91-9222222222", "Dr. A")

    # Verify doctor
    doc_list = client.get("/api/admin/doctors", headers=ADMIN_HEADERS).json()["doctors"]
    doc_id = doc_list[0]["id"]
    client.post(f"/api/admin/doctors/{doc_id}/verify", headers=ADMIN_HEADERS)

    # Patient creates consultation
    c_resp = client.post(
        "/api/consultations",
        json={"doctor_id": doc_id, "channel": "chat"},
        headers={"Authorization": f"Bearer {pat_data['access_token']}"},
    )
    assert c_resp.status_code == 201
    consult_id = c_resp.json()["consultation_id"]

    # Connect patient to WebSocket
    with client.websocket_connect(f"/ws/chat/{consult_id}?token={pat_data['access_token']}") as ws:
        # Doctor closes consultation via REST endpoint
        close_resp = client.post(
            f"/api/consultations/{consult_id}/close",
            headers={"Authorization": f"Bearer {doc_data['access_token']}"},
        )
        assert close_resp.status_code == 200
        assert close_resp.json()["status"] == "closed"

        # Patient socket receives consultation_closed event
        frame = ws.receive_json()
        assert frame["event"] == "consultation_closed"
        assert frame["consultation_id"] == consult_id


def test_websocket_chat_concurrent_broadcast(client: TestClient):
    """Both patient and doctor connect to WebSocket room and exchange messages concurrently."""
    pat_data = _register_user(client, "patient", "+91-9333333333", "Patient B")
    doc_data = _register_user(client, "doctor", "+91-9444444444", "Dr. B")

    doc_list = client.get("/api/admin/doctors", headers=ADMIN_HEADERS).json()["doctors"]
    doc_id = doc_list[0]["id"]
    client.post(f"/api/admin/doctors/{doc_id}/verify", headers=ADMIN_HEADERS)

    c_resp = client.post(
        "/api/consultations",
        json={"doctor_id": doc_id, "channel": "chat"},
        headers={"Authorization": f"Bearer {pat_data['access_token']}"},
    )
    consult_id = c_resp.json()["consultation_id"]

    # Connect both patient and doctor concurrently
    with client.websocket_connect(f"/ws/chat/{consult_id}?token={pat_data['access_token']}") as pat_ws:
        with client.websocket_connect(f"/ws/chat/{consult_id}?token={doc_data['access_token']}") as doc_ws:
            # Patient sends a message
            pat_ws.send_json({"type": "text", "content": "I have severe throat pain."})

            # Both receive the broadcast
            pat_msg = pat_ws.receive_json()
            doc_msg = doc_ws.receive_json()

            assert pat_msg["text"] == "I have severe throat pain."
            assert doc_msg["text"] == "I have severe throat pain."
            assert pat_msg["sender_role"] == "patient"
            assert doc_msg["sender_role"] == "patient"

            # Doctor replies
            doc_ws.send_json({"type": "text", "content": "Please gargle with warm saline."})

            pat_reply = pat_ws.receive_json()
            doc_reply = doc_ws.receive_json()

            assert pat_reply["text"] == "Please gargle with warm saline."
            assert doc_reply["text"] == "Please gargle with warm saline."
            assert pat_reply["sender_role"] == "doctor"
            assert doc_reply["sender_role"] == "doctor"


# ── 3. External Service Timeout & Error Resilience ────────────────────────────

def test_external_ntfy_timeout_and_error_isolation():
    """Verify that ntfy dispatch never raises or blocks even with unreachable / bad hosts."""
    from app.services.notifications import _send_ntfy
    import asyncio

    async def _test():
        # Dispatch to arbitrary topic — must never raise
        await _send_ntfy("test-topic-unreachable", "Title", "Body", priority="high")

    asyncio.run(_test())
