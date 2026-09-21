"""
AarogyaMP — FastAPI Application Entry Point (Milestone 0 stub)

Person A owns this file.
At M0: serves GET /health only.
Full routes are wired in as each router is implemented.
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings

# ── App factory ───────────────────────────────────────────────
app = FastAPI(
    title="AarogyaMP API",
    description="Symptom triage + doctor discovery + doctor-patient consultation platform",
    version="0.1.0",
)

# ── CORS ──────────────────────────────────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS.split(","),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Health check (M0 exit criterion for Person A) ─────────────
@app.get("/health", tags=["Health"])
async def health():
    return {"status": "ok", "version": "0.1.0"}


# ── Routers (uncomment as each milestone is completed) ────────
# from app.routers import auth, assessments, doctors, consultations, admin
# app.include_router(auth.router, prefix="/api/auth", tags=["Auth"])
# app.include_router(assessments.router, prefix="/api/assessments", tags=["Assessments"])
# app.include_router(doctors.router, prefix="/api/doctors", tags=["Doctors"])
# app.include_router(consultations.router, prefix="/api", tags=["Consultations"])
# app.include_router(admin.router, prefix="/api/admin", tags=["Admin"])
