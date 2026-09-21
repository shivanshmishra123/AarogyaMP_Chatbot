"""
AarogyaMP — ORM Models (Milestone 0 stub)
Person A owns this file.

All tables defined per Reference doc §6. Schema is FROZEN — do not add/rename fields
without updating AAROGYAMP-REFERENCE.md first and announcing to all tracks.
"""
import uuid
from datetime import datetime
from typing import Optional

from sqlalchemy import Boolean, DateTime, Float, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


def _uuid() -> str:
    return str(uuid.uuid4())


class Patient(Base):
    __tablename__ = "patients"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=_uuid)
    name: Mapped[str] = mapped_column(String, nullable=False)
    age: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    gender: Mapped[Optional[str]] = mapped_column(String, nullable=True)
    phone: Mapped[str] = mapped_column(String, nullable=False, unique=True)
    email: Mapped[Optional[str]] = mapped_column(String, nullable=True)
    password_hash: Mapped[str] = mapped_column(String, nullable=False)
    home_location: Mapped[Optional[str]] = mapped_column(String, nullable=True)  # JSON lat/lng
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)


class Doctor(Base):
    __tablename__ = "doctors"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=_uuid)
    name: Mapped[str] = mapped_column(String, nullable=False)
    specialty: Mapped[str] = mapped_column(String, nullable=False)
    qualification: Mapped[Optional[str]] = mapped_column(String, nullable=True)
    phone: Mapped[str] = mapped_column(String, nullable=False)
    email: Mapped[Optional[str]] = mapped_column(String, nullable=True)
    hospital: Mapped[Optional[str]] = mapped_column(String, nullable=True)
    address: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    latitude: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    longitude: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    languages: Mapped[Optional[str]] = mapped_column(String, nullable=True)       # JSON list
    availability: Mapped[Optional[str]] = mapped_column(String, nullable=True)    # JSON hours/days
    verification_status: Mapped[str] = mapped_column(String, default="pending")   # pending | verified | rejected
    password_hash: Mapped[str] = mapped_column(String, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)


class SymptomReport(Base):
    __tablename__ = "symptom_reports"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=_uuid)
    patient_id: Mapped[str] = mapped_column(String, nullable=False)
    input_mode: Mapped[str] = mapped_column(String, nullable=False)                # text | voice
    raw_text: Mapped[str] = mapped_column(Text, nullable=False)
    duration_text: Mapped[Optional[str]] = mapped_column(String, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)


class Vitals(Base):
    __tablename__ = "vitals"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=_uuid)
    symptom_report_id: Mapped[str] = mapped_column(String, nullable=False)
    temperature_f: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    heart_rate_bpm: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    systolic_bp: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    diastolic_bp: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    spo2_pct: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    flagged_invalid: Mapped[Optional[str]] = mapped_column(String, nullable=True)  # JSON list of field names
    source: Mapped[str] = mapped_column(String, default="manual")                  # manual | device
    timestamp: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)


class AIAssessment(Base):
    __tablename__ = "ai_assessments"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=_uuid)
    symptom_report_id: Mapped[str] = mapped_column(String, nullable=False)
    risk_level: Mapped[str] = mapped_column(String, nullable=False)               # LOW | MODERATE | HIGH | EMERGENCY
    is_emergency: Mapped[bool] = mapped_column(Boolean, default=False)
    emergency_triggers: Mapped[Optional[str]] = mapped_column(Text, nullable=True) # JSON [{rule_id, description}]
    possible_conditions: Mapped[Optional[str]] = mapped_column(Text, nullable=True) # JSON [{name, likelihood}]
    recommended_specialty: Mapped[Optional[str]] = mapped_column(String, nullable=True)
    recommendation_text: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    ai_status: Mapped[str] = mapped_column(String, default="ok")                  # ok | unavailable | skipped
    raw_ai_response: Mapped[Optional[str]] = mapped_column(Text, nullable=True)   # full LLM JSON for audit
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)


class Consultation(Base):
    __tablename__ = "consultations"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=_uuid)
    patient_id: Mapped[str] = mapped_column(String, nullable=False)
    doctor_id: Mapped[str] = mapped_column(String, nullable=False)
    symptom_report_id: Mapped[Optional[str]] = mapped_column(String, nullable=True)
    channel: Mapped[str] = mapped_column(String, nullable=False)                  # call | email | chat
    status: Mapped[str] = mapped_column(String, default="open")                   # open | closed
    started_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    ended_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)


class ChatMessage(Base):
    __tablename__ = "chat_messages"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=_uuid)
    consultation_id: Mapped[str] = mapped_column(String, nullable=False)
    sender_role: Mapped[str] = mapped_column(String, nullable=False)              # patient | doctor
    message_type: Mapped[str] = mapped_column(String, nullable=False)             # text | voice | image | document
    text: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    file_path: Mapped[Optional[str]] = mapped_column(String, nullable=True)
    timestamp: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
