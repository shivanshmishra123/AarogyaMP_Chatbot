"""
AarogyaMP — Milestone 1 Backend Core Test Suite
Owned by: Person A

Verifies:
1. Health endpoint
2. Patient & Doctor Registration + Login + JWT tokens
3. Role guards (patient vs doctor permissions)
4. Doctor search by specialty, coordinates, radius, and verified-only enforcement
5. Admin verification of doctors via ops token
6. Consultation creation
7. Doctor queue listing with patient details
8. WebSocket chat connection, message broadcasting, and database persistence
"""
import json
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.config import settings
from app.database import Base, get_db
from app.main import app
from app.models import ChatMessage, Consultation, Doctor, Patient
from scripts.seed_doctors import seed_doctors

# Setup test DB (isolated in-memory with StaticPool so all threads/sessions share it)
SQLALCHEMY_DATABASE_URL = "sqlite:///:memory:"
test_engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=test_engine)


def override_get_db():
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()


app.dependency_overrides[get_db] = override_get_db


@pytest.fixture(autouse=True)
def setup_database():
    Base.metadata.drop_all(bind=test_engine)
    Base.metadata.create_all(bind=test_engine)
    # Seed doctors using testing session
    db = TestingSessionLocal()
    # Add a verified doctor and an unverified doctor
    doc_verified = Doctor(
        id="doc_test_verified",
        name="Dr. Verified Cardiologist",
        specialty="Cardiologist",
        phone="+91-9999900001",
        latitude=23.2500,
        longitude=77.4100,
        verification_status="verified",
        password_hash="$2b$12$7z.P.rG0LdO9o1dF6wH12.rFmB2x09/jM1B51P6W.3w1Q7M0Qp6e6",
    )
    doc_unverified = Doctor(
        id="doc_test_unverified",
        name="Dr. Unverified Quack",
        specialty="Cardiologist",
        phone="+91-9999900002",
        latitude=23.2510,
        longitude=77.4110,
        verification_status="pending",
        password_hash="$2b$12$7z.P.rG0LdO9o1dF6wH12.rFmB2x09/jM1B51P6W.3w1Q7M0Qp6e6",
    )
    doc_gp = Doctor(
        id="doc_test_gp",
        name="Dr. Verified GP",
        specialty="General Physician",
        phone="+91-9999900003",
        latitude=23.3500,  # ~11km away from 23.2500, 77.4100
        longitude=77.4100,
        verification_status="verified",
        password_hash="$2b$12$7z.P.rG0LdO9o1dF6wH12.rFmB2x09/jM1B51P6W.3w1Q7M0Qp6e6",
    )
    db.add_all([doc_verified, doc_unverified, doc_gp])
    db.commit()
    db.close()
    yield


@pytest.fixture
def client():
    with TestClient(app) as c:
        yield c


def test_health_check(client):
    res = client.get("/health")
    assert res.status_code == 200
    assert res.json() == {"status": "ok", "version": "0.1.0"}


def test_auth_register_and_login_patient(client):
    # 1. Register patient
    reg_payload = {
        "name": "Ramesh Kumar",
        "phone": "+91-9876543210",
        "email": "ramesh@example.com",
        "password": "Password@123",
        "role": "patient",
    }
    reg_res = client.post("/api/auth/register", json=reg_payload)
    assert reg_res.status_code == 201, reg_res.text
    data = reg_res.json()
    assert "access_token" in data
    assert "refresh_token" in data
    assert data["role"] == "patient"

    # Duplicate phone rejection
    dup_res = client.post("/api/auth/register", json=reg_payload)
    assert dup_res.status_code == 400

    # 2. Login patient
    login_res = client.post("/api/auth/login", json={"phone": "+91-9876543210", "password": "Password@123"})
    assert login_res.status_code == 200
    login_data = login_res.json()
    assert login_data["role"] == "patient"
    assert "access_token" in login_data


def test_auth_register_and_login_doctor(client):
    reg_payload = {
        "name": "Dr. Sunita Patel",
        "phone": "+91-9876500000",
        "email": "sunita@example.com",
        "password": "Password@123",
        "role": "doctor",
        "specialty": "Dermatologist",
        "qualification": "MBBS, MD",
    }
    reg_res = client.post("/api/auth/register", json=reg_payload)
    assert reg_res.status_code == 201
    data = reg_res.json()
    assert data["role"] == "doctor"

    # Login
    login_res = client.post("/api/auth/login", json={"phone": "+91-9876500000", "password": "Password@123"})
    assert login_res.status_code == 200
    assert login_res.json()["role"] == "doctor"


def test_doctor_search_filters(client):
    # Unverified doctor must NEVER be returned
    res = client.get("/api/doctors")
    assert res.status_code == 200
    doctors = res.json()["doctors"]
    assert len(doctors) == 2  # doc_verified and doc_gp
    doctor_ids = [d["id"] for d in doctors]
    assert "doc_test_verified" in doctor_ids
    assert "doc_test_gp" in doctor_ids
    assert "doc_test_unverified" not in doctor_ids  # STRICT: unverified never shown

    # Filter by specialty
    res_cardio = client.get("/api/doctors?specialty=Cardiologist")
    cardio_docs = res_cardio.json()["doctors"]
    assert len(cardio_docs) == 1
    assert cardio_docs[0]["id"] == "doc_test_verified"

    # Distance calculation & radius filter
    # Near (23.2500, 77.4100): doc_verified is 0.0km away, doc_gp is ~11.1km away
    res_nearby = client.get("/api/doctors?lat=23.2500&lng=77.4100&radius_km=5")
    nearby_docs = res_nearby.json()["doctors"]
    assert len(nearby_docs) == 1
    assert nearby_docs[0]["id"] == "doc_test_verified"
    assert nearby_docs[0]["distance_km"] == 0.0

    res_all_radius = client.get("/api/doctors?lat=23.2500&lng=77.4100&radius_km=20")
    all_radius_docs = res_all_radius.json()["doctors"]
    assert len(all_radius_docs) == 2


def test_admin_doctor_verification(client):
    # Unverified doctor cannot be found
    res = client.get("/api/doctors")
    assert "doc_test_unverified" not in [d["id"] for d in res.json()["doctors"]]

    # Attempt without valid ops token
    bad_verify = client.post(
        "/api/admin/doctors/doc_test_unverified/verify",
        headers={"x-admin-ops-token": "wrong_token"},
    )
    assert bad_verify.status_code == 403

    # Verify with correct ops token
    good_verify = client.post(
        "/api/admin/doctors/doc_test_unverified/verify",
        headers={"x-admin-ops-token": settings.ADMIN_OPS_TOKEN},
    )
    assert good_verify.status_code == 200
    assert good_verify.json()["verification_status"] == "verified"

    # Now doctor appears in search results
    res_after = client.get("/api/doctors")
    assert "doc_test_unverified" in [d["id"] for d in res_after.json()["doctors"]]


def test_consultations_and_doctor_queue(client):
    # Register patient
    patient_res = client.post(
        "/api/auth/register",
        json={"name": "Patient A", "phone": "+91-1111111111", "password": "Pass@123", "role": "patient"},
    )
    patient_token = patient_res.json()["access_token"]

    # Register doctor
    doctor_res = client.post(
        "/api/auth/register",
        json={"name": "Dr. Queue", "phone": "+91-2222222222", "password": "Pass@123", "role": "doctor", "specialty": "ENT Specialist"},
    )
    doctor_token = doctor_res.json()["access_token"]
    # Get doctor ID
    doctor_id = client.get("/api/doctors", headers={"Authorization": f"Bearer {patient_token}"}).json()["doctors"][0]["id"]

    # Patient creates consultation
    consult_res = client.post(
        "/api/consultations",
        json={"doctor_id": doctor_id, "channel": "chat"},
        headers={"Authorization": f"Bearer {patient_token}"},
    )
    assert consult_res.status_code == 201
    consultation_id = consult_res.json()["consultation_id"]
    assert consultation_id

    # Doctor views queue (must be doctor role)
    # Patient attempting doctor queue gets 403
    forbidden_res = client.get("/api/doctor/queue", headers={"Authorization": f"Bearer {patient_token}"})
    assert forbidden_res.status_code == 403

    # Doctor queue has the consultation
    # Update doctor_id of consultation to our doctor for queue test
    db = TestingSessionLocal()
    doctor_user = db.query(Doctor).filter(Doctor.phone == "+91-2222222222").first()
    consult = db.query(Consultation).filter(Consultation.id == consultation_id).first()
    consult.doctor_id = doctor_user.id
    db.commit()
    db.close()

    queue_res = client.get("/api/doctor/queue", headers={"Authorization": f"Bearer {doctor_token}"})
    assert queue_res.status_code == 200
    queue = queue_res.json()
    assert len(queue) == 1
    assert queue[0]["consultation_id"] == consultation_id
    assert queue[0]["patient_name"] == "Patient A"


def test_websocket_chat_and_persistence(client):
    # Setup patient and doctor
    patient_res = client.post(
        "/api/auth/register",
        json={"name": "Chat Patient", "phone": "+91-3333333333", "password": "Pass@123", "role": "patient"},
    )
    patient_token = patient_res.json()["access_token"]

    doctor_res = client.post(
        "/api/auth/register",
        json={"name": "Dr. Chat", "phone": "+91-4444444444", "password": "Pass@123", "role": "doctor", "specialty": "ENT Specialist"},
    )
    doctor_token = doctor_res.json()["access_token"]

    db = TestingSessionLocal()
    doc = db.query(Doctor).filter(Doctor.phone == "+91-4444444444").first()
    pat = db.query(Patient).filter(Patient.phone == "+91-3333333333").first()
    # Create consultation
    consult = Consultation(patient_id=pat.id, doctor_id=doc.id, channel="chat", status="open")
    db.add(consult)
    db.commit()
    consult_id = consult.id
    db.close()

    # Test WebSocket connection and message exchange
    with client.websocket_connect(f"/ws/chat/{consult_id}?token={patient_token}") as ws:
        # Send text message
        msg_payload = {"type": "text", "content": "Hello Doctor, I have a sore throat."}
        ws.send_json(msg_payload)

        # Receive broadcast
        response = ws.receive_json()
        assert response["consultation_id"] == consult_id
        assert response["sender_role"] == "patient"
        assert response["text"] == "Hello Doctor, I have a sore throat."
        assert response["message_type"] == "text"

    # Verify message is persisted in DB and retrievable via GET /api/consultations/{id}/messages
    history_res = client.get(
        f"/api/consultations/{consult_id}/messages",
        headers={"Authorization": f"Bearer {doctor_token}"},
    )
    assert history_res.status_code == 200
    messages = history_res.json()["messages"]
    assert len(messages) == 1
    assert messages[0]["text"] == "Hello Doctor, I have a sore throat."
    assert messages[0]["sender_role"] == "patient"
