"""
AarogyaMP — Auth utilities (Milestone 0 stub)
Person A owns this file.

TODO (M1):
- JWT issue (access + refresh tokens)
- JWT verify + decode
- Password hashing (passlib bcrypt)
- Role-based FastAPI dependency guards (patient_only, doctor_only)
"""

# Stub — implementation in M1


def create_access_token(data: dict) -> str:
    raise NotImplementedError("Auth not yet implemented — M1")


def verify_token(token: str) -> dict:
    raise NotImplementedError("Auth not yet implemented — M1")


def hash_password(password: str) -> str:
    raise NotImplementedError("Auth not yet implemented — M1")


def verify_password(plain: str, hashed: str) -> bool:
    raise NotImplementedError("Auth not yet implemented — M1")
