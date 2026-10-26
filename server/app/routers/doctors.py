"""
AarogyaMP — Doctors Router
Person A owns this file.

Endpoints:
  GET /api/doctors              — list verified doctors with optional specialty/location filter
  GET /api/doctors/{doctor_id} — fetch a single doctor by ID

Enforces server-side that only verified doctors are returned.
"""
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Doctor
from app.schemas import DoctorDetailResponse, DoctorListResponse, DoctorOut
from app.services.doctor_search import search_doctors

router = APIRouter()


@router.get("", response_model=DoctorListResponse)
async def list_doctors(
    specialty: Optional[str] = Query(None, description="Filter by doctor specialty"),
    lat: Optional[float] = Query(None, description="Patient latitude for distance calculation"),
    lng: Optional[float] = Query(None, description="Patient longitude for distance calculation"),
    radius_km: Optional[float] = Query(None, description="Maximum radius in kilometers"),
    db: Session = Depends(get_db),
):
    """
    List nearby verified doctors with optional specialty and radius filters.
    Strictly returns verified doctors only.
    """
    doctors_data = search_doctors(
        db=db,
        specialty=specialty,
        lat=lat,
        lng=lng,
        radius_km=radius_km,
    )
    doctors_out = [DoctorOut(**doc) for doc in doctors_data]
    return DoctorListResponse(doctors=doctors_out)


@router.get("/{doctor_id}", response_model=DoctorDetailResponse)
async def get_doctor(
    doctor_id: str,
    db: Session = Depends(get_db),
):
    """
    Fetch a single verified doctor by ID.
    Returns 404 if not found or not verified.
    NOTE: phone and address are returned here for the consultation chat screen.
          Do NOT fabricate or invent any doctor details — all data must come from the DB (Reference §3, §11).
    """
    doc = (
        db.query(Doctor)
        .filter(Doctor.id == doctor_id, Doctor.verification_status == "verified")
        .first()
    )
    if doc is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Doctor not found or not yet verified",
        )

    return DoctorOut(
        id=doc.id,
        name=doc.name,
        specialty=doc.specialty,
        qualification=doc.qualification,
        distance_km=None,  # not relevant for single-fetch context
        phone=doc.phone,
        email=doc.email,
        hospital=doc.hospital,
        address=doc.address,
        availability=None,  # TODO: parse JSON if needed
        verification_status=doc.verification_status,
    )
