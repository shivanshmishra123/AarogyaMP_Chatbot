"""
AarogyaMP — Admin Router
Person A owns this file.

Endpoints:
  POST /api/admin/doctors/{doctor_id}/verify  (ops-token gated)

Allows internal operations to verify a doctor's credentials.
"""
from fastapi import APIRouter, Depends, Header, HTTPException, status
from sqlalchemy.orm import Session

from app.config import settings
from app.database import get_db
from app.models import Doctor
from app.schemas import VerifyDoctorResponse

router = APIRouter()


@router.post("/doctors/{doctor_id}/verify", response_model=VerifyDoctorResponse)
async def verify_doctor(
    doctor_id: str,
    x_admin_ops_token: str = Header(..., description="Internal ops authorization token"),
    db: Session = Depends(get_db),
):
    """
    Mark a doctor as verified using internal ops token.
    Enforces that unverified doctors cannot be discovered until verified.
    """
    if x_admin_ops_token != settings.ADMIN_OPS_TOKEN:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Invalid admin ops token",
        )

    doctor = db.query(Doctor).filter(Doctor.id == doctor_id).first()
    if not doctor:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Doctor not found",
        )

    doctor.verification_status = "verified"
    db.commit()
    db.refresh(doctor)

    return VerifyDoctorResponse(
        doctor_id=doctor.id,
        verification_status=doctor.verification_status,
    )
