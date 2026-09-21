"""
AarogyaMP — Auth router stub
Person A owns this file.

Endpoints:
  POST /api/auth/register
  POST /api/auth/login

TODO (M1): Implement register/login, JWT issue, role guard.
"""
from fastapi import APIRouter

router = APIRouter()


@router.post("/register")
async def register():
    raise NotImplementedError("M1")


@router.post("/login")
async def login():
    raise NotImplementedError("M1")
