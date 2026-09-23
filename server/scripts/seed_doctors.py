#!/usr/bin/env python3
"""
AarogyaMP — Seed synthetic doctors into the database.
Owned by: Person A

Seeds doctors from app/lib/mocks/mock_doctors.json.
Sets a default password ('Doctor@123') for doctor testing logins.
"""
import json
import sys
from pathlib import Path

# Add server directory to path
server_dir = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(server_dir))

import bcrypt
from app.database import SessionLocal, init_db
from app.models import Doctor


def seed_doctors(quiet: bool = False):
    init_db()
    db = SessionLocal()

    mock_path = server_dir.parent / "app" / "lib" / "mocks" / "mock_doctors.json"
    if not mock_path.exists():
        if not quiet:
            print(f"Mock file not found: {mock_path}")
        return

    with open(mock_path, "r", encoding="utf-8") as f:
        doctors_data = json.load(f)

    default_hash = bcrypt.hashpw(b"Doctor@123", bcrypt.gensalt()).decode("utf-8")
    seeded_count = 0

    for doc in doctors_data:
        existing = db.query(Doctor).filter(Doctor.id == doc["id"]).first()
        if not existing:
            new_doc = Doctor(
                id=doc["id"],
                name=doc["name"],
                specialty=doc["specialty"],
                qualification=doc.get("qualification"),
                phone=doc["phone"],
                email=doc.get("email"),
                hospital=doc.get("hospital"),
                address=doc.get("address"),
                latitude=doc.get("latitude"),
                longitude=doc.get("longitude"),
                languages=json.dumps(doc.get("languages", [])),
                availability=json.dumps(doc.get("availability", {})),
                verification_status=doc.get("verification_status", "verified"),
                password_hash=default_hash,
            )
            db.add(new_doc)
            seeded_count += 1
        else:
            # Update fields if needed
            existing.name = doc["name"]
            existing.specialty = doc["specialty"]
            existing.verification_status = doc.get("verification_status", "verified")

    db.commit()
    db.close()
    if not quiet:
        print(f"Successfully seeded/verified {seeded_count} synthetic doctors into database.")


if __name__ == "__main__":
    seed_doctors()
