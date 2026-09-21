"""
AarogyaMP — Doctors router stub
Person A owns this file.

Endpoints:
  GET /api/doctors?specialty=&lat=&lng=&radius_km=

IMPORTANT: Only verified doctors (verification_status=verified) are ever returned.
This filter is enforced SERVER-SIDE, never rely on the client to filter.

TODO (M1 — Person A): Implement with doctor_search.py distance+filter logic.
"""
from fastapi import APIRouter

router = APIRouter()


@router.get("")
async def list_doctors():
    """GET /api/doctors — Reference §11"""
    raise NotImplementedError("M1 — Person A")
