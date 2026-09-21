"""
AarogyaMP — Push Notifications via FCM (Milestone 0 stub)
Person A owns this file.

Used for: new chat message, new patient in doctor's queue.
Requires: FCM_SERVER_KEY in .env.

TODO (M2 — Person A): Implement FCM send.
"""


async def send_new_message_notification(doctor_id: str, patient_name: str, preview: str):
    """Notify doctor of a new incoming chat message."""
    raise NotImplementedError("M2 — Person A")


async def send_queue_notification(doctor_id: str, patient_name: str):
    """Notify doctor of a new patient in their queue."""
    raise NotImplementedError("M2 — Person A")
