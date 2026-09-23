"""
AarogyaMP — Auth Router
Person A owns this file.

Endpoints:
  POST /api/auth/register
  POST /api/auth/login
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.auth import (
    create_access_token,
    create_refresh_token,
    hash_password,
    verify_password,
)
from app.database import get_db
from app.models import Doctor, Patient
from app.schemas import AuthResponse, LoginRequest, RegisterRequest

router = APIRouter()


@router.post("/register", response_model=AuthResponse, status_code=status.HTTP_201_CREATED)
async def register(req: RegisterRequest, db: Session = Depends(get_db)):
    """
    Register a new user (patient or doctor).
    Returns JWT access and refresh tokens along with user role.
    """
    # Check if phone already registered
    existing_patient = db.query(Patient).filter(Patient.phone == req.phone).first()
    existing_doctor = db.query(Doctor).filter(Doctor.phone == req.phone).first()
    if existing_patient or existing_doctor:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="A user with this phone number already exists",
        )

    pw_hash = hash_password(req.password)

    if req.role == "patient":
        new_patient = Patient(
            name=req.name,
            phone=req.phone,
            email=req.email,
            password_hash=pw_hash,
        )
        db.add(new_patient)
        db.commit()
        db.refresh(new_patient)
        user_id = new_patient.id

    elif req.role == "doctor":
        if not req.specialty:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Doctor registration requires specialty",
            )
        new_doctor = Doctor(
            name=req.name,
            phone=req.phone,
            email=req.email,
            specialty=req.specialty,
            qualification=req.qualification,
            password_hash=pw_hash,
            verification_status="pending",
        )
        db.add(new_doctor)
        db.commit()
        db.refresh(new_doctor)
        user_id = new_doctor.id

    else:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid role specified",
        )

    token_data = {"sub": user_id, "role": req.role}
    access_token = create_access_token(token_data)
    refresh_token = create_refresh_token(token_data)

    return AuthResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        role=req.role,
    )


@router.post("/login", response_model=AuthResponse)
async def login(req: LoginRequest, db: Session = Depends(get_db)):
    """
    Authenticate user by phone and password.
    Returns JWT access and refresh tokens with role.
    """
    # Check patient table first
    patient = db.query(Patient).filter(Patient.phone == req.phone).first()
    if patient and verify_password(req.password, patient.password_hash):
        token_data = {"sub": patient.id, "role": "patient"}
        return AuthResponse(
            access_token=create_access_token(token_data),
            refresh_token=create_refresh_token(token_data),
            role="patient",
        )

    # Check doctor table
    doctor = db.query(Doctor).filter(Doctor.phone == req.phone).first()
    if doctor and verify_password(req.password, doctor.password_hash):
        token_data = {"sub": doctor.id, "role": "doctor"}
        return AuthResponse(
            access_token=create_access_token(token_data),
            refresh_token=create_refresh_token(token_data),
            role="doctor",
        )

    raise HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Invalid phone number or password",
        headers={"WWW-Authenticate": "Bearer"},
    )
