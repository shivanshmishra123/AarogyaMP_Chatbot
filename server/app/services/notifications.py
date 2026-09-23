"""
AarogyaMP — Push Notifications via FCM
Person A owns this file.

Used for: new chat message, new patient in doctor's queue.
Requires: FCM_SERVER_KEY in .env (Milestone 2).
"""
import logging
from app.config import settings

logger = logging.getLogger(__name__)


async def send_new_message_notification(doctor_id: str, patient_name: str, preview: str):
    """Notify doctor of a new incoming chat message."""
    if not settings.FCM_SERVER_KEY:
        logger.debug(f"[FCM Stub] New message for doctor {doctor_id} from {patient_name}: {preview}")
        return
    # Full FCM implementation wired in M2


async def send_queue_notification(doctor_id: str, patient_name: str):
    """Notify doctor of a new patient in their queue."""
    if not settings.FCM_SERVER_KEY:
        logger.debug(f"[FCM Stub] New patient {patient_name} in queue for doctor {doctor_id}")
        return
    # Full FCM implementation wired in M2
