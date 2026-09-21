"""
AarogyaMP — Doctor Search Service (Milestone 0 stub)
Person A owns this file.

Handles: specialty filter, verified-only filter, distance calculation.
Uses Haversine formula for lat/lng distance.

TODO (M1 — Person A): Implement distance calc + DB query with filters.
"""
from typing import List, Optional


def search_doctors(
    specialty: Optional[str] = None,
    lat: Optional[float] = None,
    lng: Optional[float] = None,
    radius_km: Optional[float] = None,
) -> List[dict]:
    """
    Query verified doctors with optional specialty + distance filters.
    verification_status=verified is ALWAYS enforced here — never return unverified doctors.
    """
    raise NotImplementedError("M1 — Person A")
