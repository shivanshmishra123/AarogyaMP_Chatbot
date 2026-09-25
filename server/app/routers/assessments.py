"""
AarogyaMP — Assessments router (Milestone 1)
Person B owns this file.

Endpoints:
  POST /api/assessments
  GET  /api/assessments/{assessment_id}

Pipeline (Reference §8):
  Stage 1: intake — accept SymptomReport data
  Stage 2: vitals_validator.run() — owned by Person A, skipped at M1
  Stage 3: emergency_rule_engine.run()  ← deterministic, runs FIRST
  Stage 4: ai_symptom_engine.analyze()  ← only if NOT emergency
  Stage 5: specialty_mapper.resolve()   ← cross-check LLM specialty pick
  Stage 6: persist AIAssessment row     ← needs Person A's DB, deferred to integration

At M1 this router runs standalone without Person A's DB/auth.
Persistence and auth guards will be wired at Checkpoint 1 integration.
"""
import uuid

from fastapi import APIRouter

from app.schemas import AssessmentRequest, AssessmentResponse
from app.services import emergency_rule_engine
from app.services import ai_symptom_engine
from app.services.specialty_mapper import resolve as resolve_specialty

router = APIRouter()


@router.post("", response_model=AssessmentResponse)
async def submit_assessment(req: AssessmentRequest):
    """
    POST /api/assessments — Reference §11

    Runs the full 6-stage assessment pipeline synchronously.
    """
    assessment_id = str(uuid.uuid4())

    # ── Stage 1: Intake ───────────────────────────────────────
    # Accept raw_text, input_mode, duration_text, vitals from request.
    # DB persistence deferred to integration with Person A's models.

    # ── Stage 2: Vitals validation ────────────────────────────
    # Owned by Person A (vitals_validator.py). Skipped at M1.
    # When wired: would return 400 if vitals are obviously invalid.

    # ── Stage 3: Emergency rule engine (deterministic) ────────
    vitals_kwargs = {}
    if req.vitals:
        vitals_kwargs = {
            "temperature_f": req.vitals.temperature_f,
            "heart_rate_bpm": req.vitals.heart_rate_bpm,
            "systolic_bp": req.vitals.systolic_bp,
            "diastolic_bp": req.vitals.diastolic_bp,
            "spo2_pct": req.vitals.spo2_pct,
        }

    emergency_result = emergency_rule_engine.run(
        raw_text=req.raw_text,
        **vitals_kwargs,
    )

    # If EMERGENCY: short-circuit — return immediately, SKIP the LLM
    if emergency_result.is_emergency:
        return AssessmentResponse(
            assessment_id=assessment_id,
            is_emergency=True,
            risk_level="EMERGENCY",
            emergency_triggers=emergency_result.triggers,
            possible_conditions=None,
            recommended_specialty=None,
            recommendation_text=(
                "Seek immediate emergency medical care. "
                "Call emergency services or go to the nearest emergency room NOW. "
                "Do not wait for a chat response."
            ),
            ai_status="skipped",
        )

    # ── Stage 4: AI symptom engine (LLM call) ─────────────────
    ai_result, ai_status = await ai_symptom_engine.analyze(
        raw_text=req.raw_text,
        duration_text=req.duration_text,
        age=req.vitals.age if req.vitals else None,
        **vitals_kwargs,
    )

    # ── Stage 5: Specialty mapper ─────────────────────────────
    # Cross-check LLM's specialty pick against the fixed list.
    recommended_specialty = None
    if ai_result:
        recommended_specialty = resolve_specialty(ai_result.recommended_specialty)

    # ── Build response ────────────────────────────────────────
    # If AI was unavailable: default to MODERATE minimum (Reference §8)
    if ai_result:
        return AssessmentResponse(
            assessment_id=assessment_id,
            is_emergency=False,
            risk_level=ai_result.risk_level,
            emergency_triggers=None,
            possible_conditions=[
                {"name": c.name, "likelihood": c.likelihood}
                for c in ai_result.possible_conditions
            ],
            recommended_specialty=recommended_specialty,
            recommendation_text=ai_result.recommendation_text,
            ai_status=ai_status,
        )
    else:
        # AI unavailable — fallback to MODERATE, recommend seeing a doctor
        return AssessmentResponse(
            assessment_id=assessment_id,
            is_emergency=False,
            risk_level="MODERATE",
            emergency_triggers=None,
            possible_conditions=None,
            recommended_specialty="General Physician",
            recommendation_text=(
                "AI assessment is temporarily unavailable. "
                "Based on the information provided, please consult a doctor. "
                "If symptoms worsen or you experience any emergency signs, "
                "seek immediate medical care."
            ),
            ai_status=ai_status,
        )

    # ── Stage 6: Persist AIAssessment row ─────────────────────
    # Deferred to Checkpoint 1 integration with Person A's database.
    # At that point: save SymptomReport, Vitals, and AIAssessment rows.


@router.get("/{assessment_id}", response_model=AssessmentResponse)
async def get_assessment(assessment_id: str):
    """
    GET /api/assessments/{assessment_id}
    Requires Person A's database — deferred to integration.
    """
    # Will be implemented when Person A's DB layer is wired in.
    # For now, return 501 to indicate it's not yet available.
    from fastapi import HTTPException
    raise HTTPException(
        status_code=501,
        detail="Assessment retrieval requires database integration (Person A). Not yet wired.",
    )
