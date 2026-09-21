"""
AarogyaMP — Assessments router stub
Person B owns this file.

Endpoints:
  POST /api/assessments
  GET  /api/assessments/{assessment_id}

Pipeline (Reference §8):
  Stage 1: intake — save SymptomReport
  Stage 2: vitals_validator.run()
  Stage 3: emergency_rule_engine.run()  ← deterministic, runs FIRST
  Stage 4: ai_symptom_engine.analyze()  ← only if NOT emergency
  Stage 5: specialty_mapper.resolve()
  Stage 6: persist AIAssessment row

TODO (M1 — Person B): Wire all pipeline stages.
"""
from fastapi import APIRouter

router = APIRouter()


@router.post("")
async def submit_assessment():
    """POST /api/assessments — Reference §11"""
    raise NotImplementedError("M1 — Person B")


@router.get("/{assessment_id}")
async def get_assessment(assessment_id: str):
    """GET /api/assessments/{assessment_id}"""
    raise NotImplementedError("M1 — Person B")
