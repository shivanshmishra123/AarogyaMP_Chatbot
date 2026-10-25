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

from fastapi import Depends, FastAPI, Header, HTTPException, Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
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
        "**Milestone 3**: WebSocket concurrency hardening, ntfy push notifications, "
        "structured error responses across all failure modes."
    ),
    version="0.3.0",
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


# ── Structured Error Handlers (Milestone 3) ────────────────────────────────────

@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    """
    Standardized HTTP error response shape across all endpoints.
    Preserves top-level 'detail' field for backward-compatibility with Pydantic & API tests.
    """
    error_codes = {
        400: "BAD_REQUEST",
        401: "UNAUTHORIZED",
        403: "FORBIDDEN",
        404: "NOT_FOUND",
        409: "CONFLICT",
        422: "UNPROCESSABLE_ENTITY",
        500: "INTERNAL_SERVER_ERROR",
        503: "SERVICE_UNAVAILABLE",
    }
    code = error_codes.get(exc.status_code, "HTTP_ERROR")
    return JSONResponse(
        status_code=exc.status_code,
        headers=exc.headers,
        content={
            "detail": exc.detail,
            "error": {
                "code": code,
                "message": str(exc.detail),
                "status_code": exc.status_code,
            },
        },
    )


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    """
    Structured validation error handler with field breakdown for client apps.
    """
    errors = exc.errors()
    field_errors = [
        {
            "field": ".".join(str(loc) for loc in err.get("loc", [])),
            "message": err.get("msg", ""),
            "type": err.get("type", ""),
        }
        for err in errors
    ]
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={
            "detail": errors,
            "error": {
                "code": "VALIDATION_ERROR",
                "message": "Input validation failed",
                "status_code": 422,
                "fields": field_errors,
            },
        },
    )


@app.exception_handler(Exception)
async def unhandled_exception_handler(request: Request, exc: Exception):
    """
    Global catch-all exception handler guaranteeing a JSON response.
    """
    logger.exception(f"Unhandled error on {request.method} {request.url.path}: {exc}")
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "detail": "Internal server error",
            "error": {
                "code": "INTERNAL_SERVER_ERROR",
                "message": "An unexpected server error occurred. Please try again later.",
                "status_code": 500,
            },
        },
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
