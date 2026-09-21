"""
AarogyaMP — Pydantic Schemas (FROZEN at Milestone 0)
Person A owns this file.

⚠️  CONTRACT FREEZE: These schemas mirror Reference §6, §9, §11 exactly.
    Do NOT add, rename, or remove fields without:
    1. Updating AAROGYAMP-REFERENCE.md first
    2. Announcing to all tracks (A/B/C)
    3. Incrementing the relevant schema version comment below

Last frozen: Milestone 0 (2026-09-21)
"""
from datetime import datetime
from typing import List, Literal, Optional

from pydantic import BaseModel, Field


# ── Auth ──────────────────────────────────────────────────────

class RegisterRequest(BaseModel):
    name: str
    phone: str
    email: Optional[str] = None
    password: str
    role: Literal["patient", "doctor"]
    # Doctor-only fields (ignored for patient role)
    specialty: Optional[str] = None
    qualification: Optional[str] = None

class LoginRequest(BaseModel):
    phone: str
    password: str

class AuthResponse(BaseModel):
    access_token: str
    refresh_token: str
    role: Literal["patient", "doctor"]


# ── Vitals ────────────────────────────────────────────────────

class VitalsIn(BaseModel):
    temperature_f: Optional[float] = None
    heart_rate_bpm: Optional[int] = None
    systolic_bp: Optional[int] = None
    diastolic_bp: Optional[int] = None
    spo2_pct: Optional[int] = None
    age: Optional[int] = None          # passed to LLM for context, not stored in Vitals table


# ── Assessment ────────────────────────────────────────────────

class AssessmentRequest(BaseModel):
    """POST /api/assessments — Reference §11"""
    input_mode: Literal["text", "voice"]
    raw_text: str
    duration_text: Optional[str] = None
    vitals: Optional[VitalsIn] = None


class PossibleCondition(BaseModel):
    name: str
    likelihood: Literal["high", "medium", "low"]


class EmergencyTrigger(BaseModel):
    rule_id: str
    description: str


class AssessmentResponse(BaseModel):
    """200 response — Reference §11"""
    assessment_id: str
    is_emergency: bool
    risk_level: Literal["LOW", "MODERATE", "HIGH", "EMERGENCY"]
    # Emergency-only fields
    emergency_triggers: Optional[List[EmergencyTrigger]] = None
    # Non-emergency fields
    possible_conditions: Optional[List[PossibleCondition]] = None
    recommended_specialty: Optional[str] = None
    recommendation_text: Optional[str] = None
    ai_status: Literal["ok", "unavailable", "skipped"]


# ── LLM Output Schema (§9) — FROZEN ───────────────────────────
# Used internally by ai_symptom_engine.py to validate the LLM response.
# risk_level here intentionally excludes EMERGENCY (LLM cannot declare emergency).

class LLMAssessmentOutput(BaseModel):
    """Expected JSON output from LLM — Reference §9. FROZEN."""
    risk_level: Literal["LOW", "MODERATE", "HIGH"]
    confidence: Literal["high", "medium", "low"]
    possible_conditions: List[PossibleCondition]
    supporting_symptoms: List[str]
    recommended_specialty: str
    recommendation_text: str
    disclaimer: str


# ── Doctors ───────────────────────────────────────────────────

class DoctorOut(BaseModel):
    id: str
    name: str
    specialty: str
    qualification: Optional[str] = None
    distance_km: Optional[float] = None
    phone: str
    email: Optional[str] = None
    hospital: Optional[str] = None
    address: Optional[str] = None
    availability: Optional[dict] = None
    verification_status: str           # always "verified" in results — enforced server-side

class DoctorListResponse(BaseModel):
    doctors: List[DoctorOut]


# ── Consultations ─────────────────────────────────────────────

class ConsultationRequest(BaseModel):
    doctor_id: str
    channel: Literal["call", "email", "chat"]
    symptom_report_id: Optional[str] = None

class ConsultationResponse(BaseModel):
    consultation_id: str


# ── Chat ──────────────────────────────────────────────────────

class ChatMessageOut(BaseModel):
    id: str
    consultation_id: str
    sender_role: Literal["patient", "doctor"]
    message_type: Literal["text", "voice", "image", "document"]
    text: Optional[str] = None
    file_path: Optional[str] = None
    timestamp: datetime

class ChatMessageListResponse(BaseModel):
    messages: List[ChatMessageOut]

class WsIncomingMessage(BaseModel):
    """WebSocket message format — Reference §11 /ws/chat"""
    type: Literal["text", "voice", "image"]
    content: str


# ── Doctor Queue (doctor role) ────────────────────────────────

class PatientQueueItem(BaseModel):
    consultation_id: str
    patient_name: str
    symptom_summary: str
    risk_level: Optional[str] = None
    is_emergency: bool = False
    started_at: datetime


# ── Admin ─────────────────────────────────────────────────────

class VerifyDoctorResponse(BaseModel):
    doctor_id: str
    verification_status: str
