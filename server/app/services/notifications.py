"""
AarogyaMP — Push Notifications via FCM (Firebase Cloud Messaging)
Person A owns this file.

Milestone 2: Real FCM HTTP v1 API integration.
Sends notifications for:
  - New chat message → doctor
  - New patient in doctor's queue → doctor
  - Doctor accepted consultation → patient (future)

Configuration:
  FCM_SERVER_KEY in server/.env (Legacy HTTP API key or Service Account JSON path)

If FCM_SERVER_KEY is not set, all calls are no-ops (logs at DEBUG level).
No notification failure should ever propagate up and break the main request path.
"""
import json
import logging
import httpx
from app.config import settings

logger = logging.getLogger(__name__)

# FCM Legacy HTTP API endpoint (works with server key)
_FCM_SEND_URL = "https://fcm.googleapis.com/fcm/send"


def _build_fcm_headers() -> dict:
    return {
        "Authorization": f"key={settings.FCM_SERVER_KEY}",
        "Content-Type": "application/json",
    }


def _build_notification_payload(
    *,
    to_token: str,
    title: str,
    body: str,
    data: dict | None = None,
) -> dict:
    """Build FCM legacy HTTP payload for a targeted device token."""
    payload: dict = {
        "to": to_token,
        "notification": {
            "title": title,
            "body": body,
            "sound": "default",
        },
        "priority": "high",
    }
    if data:
        payload["data"] = data
    return payload


async def _send_fcm(title: str, body: str, to_token: str, data: dict | None = None) -> None:
    """
    Core FCM dispatch. Always fire-and-forget — never raises.
    Timeout: 5 seconds (push failures must not block a chat message persisting).
    """
    if not settings.FCM_SERVER_KEY:
        logger.debug(f"[FCM Stub] '{title}': {body} → token not configured")
        return

    payload = _build_notification_payload(to=to_token, title=title, body=body, data=data)
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            resp = await client.post(
                _FCM_SEND_URL,
                headers=_build_fcm_headers(),
                content=json.dumps(payload),
            )
            if resp.status_code != 200:
                logger.warning(
                    f"[FCM] Non-200 response: {resp.status_code} — {resp.text[:200]}"
                )
            else:
                result = resp.json()
                if result.get("failure", 0):
                    logger.warning(f"[FCM] Delivery failure in response: {result}")
                else:
                    logger.debug(f"[FCM] Sent OK: '{title}' → ...{to_token[-8:]}")
    except Exception as exc:
        # Push notification failure is never fatal — log and continue
        logger.warning(f"[FCM] Exception sending notification: {exc!r}")


# ── Doctor FCM Token Store ─────────────────────────────────────────────────────
# In a real deployment, doctor FCM tokens would be stored in the DB (e.g., Doctor.fcm_token
# or a separate DeviceToken table per-user-session). At M2 we use a lightweight in-process
# dict as a stub that gets populated via the /api/devices/register endpoint below.
# The structure is intentionally identical to what a DB-backed version would use,
# so swapping is a one-liner later.

_doctor_fcm_tokens: dict[str, str] = {}   # doctor_id -> fcm_device_token
_patient_fcm_tokens: dict[str, str] = {}  # patient_id -> fcm_device_token


def register_doctor_token(doctor_id: str, token: str) -> None:
    """Called by /api/devices/register when a doctor logs in and sends their FCM token."""
    _doctor_fcm_tokens[doctor_id] = token
    logger.info(f"[FCM] Registered doctor token for {doctor_id}")


def register_patient_token(patient_id: str, token: str) -> None:
    """Called by /api/devices/register when a patient logs in and sends their FCM token."""
    _patient_fcm_tokens[patient_id] = token
    logger.info(f"[FCM] Registered patient token for {patient_id}")


# ── Public notification helpers ────────────────────────────────────────────────

async def send_new_message_notification(doctor_id: str, patient_name: str, preview: str) -> None:
    """
    Notify a doctor that a patient sent a new chat message.
    Called from the WebSocket handler after each persisted message.
    """
    token = _doctor_fcm_tokens.get(doctor_id)
    if not token:
        logger.debug(f"[FCM] No device token for doctor {doctor_id} — skipping new-message push")
        return

    await _send_fcm(
        title=f"New message from {patient_name}",
        body=preview[:100],
        to_token=token,
        data={"event": "new_message", "doctor_id": doctor_id},
    )


async def send_queue_notification(doctor_id: str, patient_name: str) -> None:
    """
    Notify a doctor that a new patient has appeared in their consultation queue.
    Called from assessments.py / consultations.py when a consultation is created
    and linked to a doctor.
    """
    token = _doctor_fcm_tokens.get(doctor_id)
    if not token:
        logger.debug(f"[FCM] No device token for doctor {doctor_id} — skipping queue push")
        return

    await _send_fcm(
        title="New Patient in Queue",
        body=f"{patient_name} is waiting for a consultation",
        to_token=token,
        data={"event": "new_queue_patient", "doctor_id": doctor_id},
    )


async def send_doctor_responded_notification(patient_id: str, doctor_name: str, preview: str) -> None:
    """
    Notify a patient that the doctor replied in their chat thread.
    Called from the WebSocket handler when sender_role == 'doctor'.
    """
    token = _patient_fcm_tokens.get(patient_id)
    if not token:
        logger.debug(f"[FCM] No device token for patient {patient_id} — skipping reply push")
        return

    await _send_fcm(
        title=f"Dr. {doctor_name} replied",
        body=preview[:100],
        to_token=token,
        data={"event": "doctor_reply", "patient_id": patient_id},
    )
