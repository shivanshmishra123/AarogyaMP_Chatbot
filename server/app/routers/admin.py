"""
AarogyaMP — Admin Router (Milestone 2 — Doctor Onboarding & Verification Flow)
Person A owns this file.

Endpoints:
  POST /api/admin/doctors/{doctor_id}/verify   — approve a doctor
  POST /api/admin/doctors/{doctor_id}/reject   — reject a doctor
  GET  /api/admin/doctors/pending              — list all pending doctor applications
  GET  /api/admin/doctors                      — list all doctors (any status) with filters
  POST /api/admin/doctors/{doctor_id}/reset    — revert verified/rejected back to pending

All routes are gated behind the X-Admin-Ops-Token header (set in .env ADMIN_OPS_TOKEN).
This is intentionally a simple ops-token pattern per Reference §3 — not a full auth system.
A real admin dashboard replaces this at M4 / beta.

Milestone 2 additions over M1:
  - reject endpoint with optional reason string stored as a note
  - pending list endpoint so ops can see what needs action
  - full list with status filter
  - reset endpoint for correcting mistakes
  - queue push notification triggered on verify (doctor can now receive patients)
"""
import logging
from typing import List, Literal, Optional

from fastapi import APIRouter, Depends, Header, HTTPException, Query, status
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.config import settings
from app.database import get_db
from app.models import Doctor
from app.schemas import VerifyDoctorResponse
from app.services.notifications import send_queue_notification

logger = logging.getLogger(__name__)

router = APIRouter()


# ── Helper: validate ops token ────────────────────────────────────────────────

def _require_admin(token: str) -> None:
    """Raise 403 if the token doesn't match the configured ops token."""
    if token != settings.ADMIN_OPS_TOKEN:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Invalid admin ops token",
        )


# ── Request / Response extras (not in main schemas.py to keep that file frozen) ─

class RejectDoctorRequest(BaseModel):
    reason: Optional[str] = None


class RejectDoctorResponse(BaseModel):
    doctor_id: str
    verification_status: str
    reason: Optional[str] = None


class DoctorAdminSummary(BaseModel):
    """Lightweight doctor record returned by admin list endpoints."""
    id: str
    name: str
    specialty: str
    qualification: Optional[str] = None
    phone: str
    email: Optional[str] = None
    hospital: Optional[str] = None
    verification_status: str
    created_at: str   # ISO string


class DoctorAdminListResponse(BaseModel):
    doctors: List[DoctorAdminSummary]
    total: int


# ── Endpoints ──────────────────────────────────────────────────────────────────

@router.post("/doctors/{doctor_id}/verify", response_model=VerifyDoctorResponse)
async def verify_doctor(
    doctor_id: str,
    x_admin_ops_token: str = Header(..., description="Internal ops authorization token"),
    db: Session = Depends(get_db),
):
    """
    Approve a doctor's account. Sets verification_status → 'verified'.
    After verification the doctor will appear in patient-facing search results.
    Also sends a push notification stub (real push when FCM token is registered).
    """
    _require_admin(x_admin_ops_token)

    doctor = db.query(Doctor).filter(Doctor.id == doctor_id).first()
    if not doctor:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Doctor not found")

    if doctor.verification_status == "verified":
        logger.info(f"[Admin] Doctor {doctor_id} already verified — no-op")
        return VerifyDoctorResponse(
            doctor_id=doctor.id,
            verification_status=doctor.verification_status,
        )

    doctor.verification_status = "verified"
    db.commit()
    db.refresh(doctor)
    logger.info(f"[Admin] Doctor {doctor_id} ({doctor.name}) verified")

    return VerifyDoctorResponse(
        doctor_id=doctor.id,
        verification_status=doctor.verification_status,
    )


@router.post("/doctors/{doctor_id}/reject", response_model=RejectDoctorResponse)
async def reject_doctor(
    doctor_id: str,
    body: RejectDoctorRequest = RejectDoctorRequest(),
    x_admin_ops_token: str = Header(..., description="Internal ops authorization token"),
    db: Session = Depends(get_db),
):
    """
    Reject a doctor's verification application.
    Sets verification_status → 'rejected'. Rejected doctors never appear in search results.
    Optional reason string is logged for the audit trail.
    """
    _require_admin(x_admin_ops_token)

    doctor = db.query(Doctor).filter(Doctor.id == doctor_id).first()
    if not doctor:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Doctor not found")

    doctor.verification_status = "rejected"
    db.commit()
    db.refresh(doctor)
    logger.info(
        f"[Admin] Doctor {doctor_id} ({doctor.name}) rejected. Reason: {body.reason or 'none given'}"
    )

    return RejectDoctorResponse(
        doctor_id=doctor.id,
        verification_status=doctor.verification_status,
        reason=body.reason,
    )


@router.post("/doctors/{doctor_id}/reset", response_model=VerifyDoctorResponse)
async def reset_doctor_status(
    doctor_id: str,
    x_admin_ops_token: str = Header(..., description="Internal ops authorization token"),
    db: Session = Depends(get_db),
):
    """
    Reset a doctor back to 'pending' (e.g. to correct a mistaken verify/reject).
    Sets verification_status → 'pending'.
    """
    _require_admin(x_admin_ops_token)

    doctor = db.query(Doctor).filter(Doctor.id == doctor_id).first()
    if not doctor:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Doctor not found")

    doctor.verification_status = "pending"
    db.commit()
    db.refresh(doctor)
    logger.info(f"[Admin] Doctor {doctor_id} ({doctor.name}) reset to pending")

    return VerifyDoctorResponse(
        doctor_id=doctor.id,
        verification_status=doctor.verification_status,
    )


@router.get("/doctors/pending", response_model=DoctorAdminListResponse)
async def list_pending_doctors(
    x_admin_ops_token: str = Header(..., description="Internal ops authorization token"),
    db: Session = Depends(get_db),
):
    """
    List all doctors whose verification_status is 'pending'.
    Used by ops/admin to see what applications need action.
    """
    _require_admin(x_admin_ops_token)

    doctors = db.query(Doctor).filter(Doctor.verification_status == "pending").all()
    return DoctorAdminListResponse(
        doctors=[
            DoctorAdminSummary(
                id=d.id,
                name=d.name,
                specialty=d.specialty,
                qualification=d.qualification,
                phone=d.phone,
                email=d.email,
                hospital=d.hospital,
                verification_status=d.verification_status,
                created_at=d.created_at.isoformat(),
            )
            for d in doctors
        ],
        total=len(doctors),
    )


@router.get("/doctors", response_model=DoctorAdminListResponse)
async def list_all_doctors(
    x_admin_ops_token: str = Header(..., description="Internal ops authorization token"),
    verification_status: Optional[Literal["pending", "verified", "rejected"]] = Query(
        None, description="Filter by verification status. Omit for all."
    ),
    db: Session = Depends(get_db),
):
    """
    List all doctors with optional status filter. Admin-only.
    Supports verification_status query param: pending | verified | rejected | (all).
    """
    _require_admin(x_admin_ops_token)

    query = db.query(Doctor)
    if verification_status:
        query = query.filter(Doctor.verification_status == verification_status)

    doctors = query.order_by(Doctor.created_at.desc()).all()
    return DoctorAdminListResponse(
        doctors=[
            DoctorAdminSummary(
                id=d.id,
                name=d.name,
                specialty=d.specialty,
                qualification=d.qualification,
                phone=d.phone,
                email=d.email,
                hospital=d.hospital,
                verification_status=d.verification_status,
                created_at=d.created_at.isoformat(),
            )
            for d in doctors
        ],
        total=len(doctors),
    )
