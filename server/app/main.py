"""
AarogyaMP — FastAPI Application Entry Point
Person A owns this file.

Wired routers for Milestone 1:
- /health
- /api/auth
- /api/doctors
- /api/consultations, /api/doctor/queue, /ws/chat
- /api/admin
"""
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.database import init_db
from app.routers import admin, auth, consultations, doctors


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Ensure database tables exist
    init_db()
    yield


# ── App factory ───────────────────────────────────────────────
app = FastAPI(
    title="AarogyaMP API",
    description="Symptom triage + doctor discovery + doctor-patient consultation platform",
    version="0.1.0",
    lifespan=lifespan,
)

# ── CORS ──────────────────────────────────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS.split(",") if settings.CORS_ORIGINS != "*" else ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Health check ──────────────────────────────────────────────
@app.get("/health", tags=["Health"])
async def health():
    return {"status": "ok", "version": "0.1.0"}


# ── Routers (Milestone 1 — Person A) ──────────────────────────
app.include_router(auth.router, prefix="/api/auth", tags=["Auth"])
app.include_router(doctors.router, prefix="/api/doctors", tags=["Doctors"])
app.include_router(consultations.router, prefix="/api", tags=["Consultations"])
app.include_router(consultations.ws_router, tags=["Chat"])
app.include_router(admin.router, prefix="/api/admin", tags=["Admin"])

# Note: Person B owns app.routers.assessments, to be wired in Checkpoint 1
# from app.routers import assessments
# app.include_router(assessments.router, prefix="/api/assessments", tags=["Assessments"])
