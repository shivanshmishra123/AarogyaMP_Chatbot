"""
AarogyaMP — Admin router stub
Person A owns this file.

Endpoints:
  POST /api/admin/doctors/{id}/verify  (ops-token gated)

This is a placeholder until real admin tooling is needed.
The ops token is checked against ADMIN_OPS_TOKEN in config.

TODO (M2 — Person A): Implement verify endpoint.
"""
from fastapi import APIRouter

router = APIRouter()


@router.post("/doctors/{doctor_id}/verify")
async def verify_doctor(doctor_id: str):
    """POST /api/admin/doctors/{id}/verify — Reference §11"""
    raise NotImplementedError("M2 — Person A")
