"""
AarogyaMP — FastAPI Application Entry Point
Person A owns this file.

Wired routers:
- /health
- /api/auth
- /api/doctors
- /api/consultations, /api/doctor/queue, /api/consultations/{id}/close, /ws/chat
- /api/admin  (ops-token gated doctor onboarding/verification)
- /api/assessments
- /api/devices  (FCM token registration — Milestone 2)

Milestone 2 additions:
  - /api/devices/register endpoint for FCM device token registration
  - updated app version to 0.2.0
"""
import logging
from contextlib import asynccontextmanager
from typing import Literal, Optional

from fastapi import Depends, FastAPI, Header, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from app.auth import get_current_user
from app.config import settings
from app.database import get_db, init_db
from app.routers import admin, auth, consultations, doctors
from app.services.notifications import register_doctor_token, register_patient_token

logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Ensure database tables exist on startup
    init_db()
    logger.info("AarogyaMP backend started — tables initialized")
    yield
    logger.info("AarogyaMP backend shutting down")


# ── App factory ────────────────────────────────────────────────────────────────
app = FastAPI(
    title="AarogyaMP API",
    description=(
        "Symptom triage + doctor discovery + doctor-patient consultation platform.\n\n"
        "**Milestone 2**: Doctor onboarding flow, FCM push notifications, "
        "cursor-based chat pagination."
    ),
    version="0.2.0",
    lifespan=lifespan,
)

# ── CORS ───────────────────────────────────────────────────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS.split(",") if settings.CORS_ORIGINS != "*" else ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ── Health check ───────────────────────────────────────────────────────────────
@app.get("/health", tags=["Health"])
async def health():
    return {"status": "ok", "version": "0.2.0"}


# ── Device token registration (M2 — FCM push) ──────────────────────────────────
class DeviceRegisterRequest(BaseModel):
    fcm_token: str
    platform: Optional[Literal["android", "ios"]] = None


class DeviceRegisterResponse(BaseModel):
    registered: bool


@app.post("/api/devices/register", response_model=DeviceRegisterResponse, tags=["Devices"])
async def register_device(
    body: DeviceRegisterRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Register the caller's FCM device token so they can receive push notifications.
    Called by the app on login and whenever the OS rotates the token.
    Both patient and doctor roles call this endpoint after authenticating.
    """
    role = current_user.get("role")
    user_id = current_user["user_id"]

    if role == "doctor":
        register_doctor_token(user_id, body.fcm_token)
    elif role == "patient":
        register_patient_token(user_id, body.fcm_token)
    else:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Unknown role: {role}",
        )

    logger.info(f"[Devices] Registered FCM token for {role} {user_id}")
    return DeviceRegisterResponse(registered=True)


# ── Routers ────────────────────────────────────────────────────────────────────
app.include_router(auth.router, prefix="/api/auth", tags=["Auth"])
app.include_router(doctors.router, prefix="/api/doctors", tags=["Doctors"])
app.include_router(consultations.router, prefix="/api", tags=["Consultations"])
app.include_router(consultations.ws_router, tags=["Chat"])
app.include_router(admin.router, prefix="/api/admin", tags=["Admin"])

from app.routers import assessments
app.include_router(assessments.router, prefix="/api/assessments", tags=["Assessments"])
