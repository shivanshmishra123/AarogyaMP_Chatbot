"""
AarogyaMP — Doctor Search Service
Person A owns this file.

Handles:
- Specialty filter
- Verified-only filter (enforced server-side)
- Haversine distance calculation (lat/lng to km)
- Radius filtering and sorting
"""
import json
import math
from typing import List, Optional

from sqlalchemy.orm import Session

from app.models import Doctor


def haversine_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Calculate the great-circle distance between two points on the Earth (in km)."""
    R = 6371.0  # Earth's radius in km
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = (
        math.sin(dlat / 2.0) ** 2
        + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon / 2.0) ** 2
    )
    c = 2.0 * math.atan2(math.sqrt(a), math.sqrt(1.0 - a))
    return round(R * c, 1)


def search_doctors(
    db: Session,
    specialty: Optional[str] = None,
    lat: Optional[float] = None,
    lng: Optional[float] = None,
    radius_km: Optional[float] = None,
) -> List[dict]:
    """
    Query verified doctors with optional specialty and distance filters.
    verification_status='verified' is ALWAYS enforced server-side.
    """
    query = db.query(Doctor).filter(Doctor.verification_status == "verified")

    if specialty:
        # Case-insensitive match or contains
        query = query.filter(Doctor.specialty.ilike(f"%{specialty.strip()}%"))

    doctors = query.all()
    results = []

    for doc in doctors:
        distance: Optional[float] = None
        if lat is not None and lng is not None and doc.latitude is not None and doc.longitude is not None:
            distance = haversine_km(lat, lng, doc.latitude, doc.longitude)
            if radius_km is not None and distance > radius_km:
                continue  # outside the requested radius

        # Parse availability JSON if string
        avail = None
        if doc.availability:
            try:
                avail = json.loads(doc.availability) if isinstance(doc.availability, str) else doc.availability
            except Exception:
                avail = None

        doc_dict = {
            "id": doc.id,
            "name": doc.name,
            "specialty": doc.specialty,
            "qualification": doc.qualification,
            "distance_km": distance,
            "phone": doc.phone,
            "email": doc.email,
            "hospital": doc.hospital,
            "address": doc.address,
            "availability": avail,
            "verification_status": "verified",
        }
        results.append(doc_dict)

    # Sort: by distance if lat/lng available, otherwise by name
    if lat is not None and lng is not None:
        results.sort(key=lambda d: (d["distance_km"] is None, d["distance_km"] or 0))
    else:
        results.sort(key=lambda d: d["name"])

    return results
