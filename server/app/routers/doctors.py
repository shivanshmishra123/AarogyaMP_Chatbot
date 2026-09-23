"""
AarogyaMP — Doctors Router
Person A owns this file.

Endpoints:
  GET /api/doctors?specialty=&lat=&lng=&radius_km=

Enforces server-side that only verified doctors are returned.
"""
from typing import Optional

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.database import get_db
from app.schemas import DoctorListResponse, DoctorOut
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
