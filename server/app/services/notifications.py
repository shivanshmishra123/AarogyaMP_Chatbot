"""
AarogyaMP — Push Notifications via ntfy.sh (Self-Hosted) & FCM Migration Hook
Person A owns this file.

Milestone 2/4 Architecture:
- Primary transport: Self-hosted ntfy server (Docker sidecar).
  Topics:
    - Doctor notifications -> topic: "aarogyamp-doctor-{doctor_id}"
    - Patient notifications -> topic: "aarogyamp-patient-{patient_id}"
  No accounts or external credentials needed. Clients subscribe over HTTP SSE or WebSocket.

- Legacy/Fallback transport: Firebase Cloud Messaging (FCM).
  Kept as a migration hook when FCM_SERVER_KEY is configured.

No notification failure should ever propagate up and break the main request path.
"""
import json
import logging
import httpx
from app.config import settings

logger = logging.getLogger(__name__)

# FCM Legacy HTTP API endpoint (works with server key)
_FCM_SEND_URL = "https://fcm.googleapis.com/fcm/send"


# ── ntfy (Self-Hosted) Dispatch ────────────────────────────────────────────────

async def _send_ntfy(
    topic: str,
    title: str,
    body: str,
    priority: str = "default",
    tags: str = "hospital",
) -> None:
    """
    Fire-and-forget ntfy notification. Never raises.
    Timeout: 3 seconds (push failures must not block chat or consultations).
    """
    if not settings.NTFY_BASE_URL:
        return

    base_url = settings.NTFY_BASE_URL.rstrip("/")
    url = f"{base_url}/{topic}"
    headers = {
        "Title": title,
        "Priority": priority,
        "Tags": tags,
    }
    try:
        async with httpx.AsyncClient(timeout=3.0) as client:
            resp = await client.post(url, headers=headers, content=body.encode("utf-8"))
            if resp.status_code >= 400:
                logger.warning(f"[ntfy] Non-2xx response from {url}: {resp.status_code}")
            else:
                logger.debug(f"[ntfy] Sent OK: '{title}' → {topic}")
    except Exception as exc:
        # Push notification failure is never fatal — log and continue
        logger.warning(f"[ntfy] Exception sending notification to {topic}: {exc!r}")


# ── FCM Legacy Dispatch ────────────────────────────────────────────────────────

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


# ── Doctor & Patient Token Store (Migration Hook) ──────────────────────────────
# Stored in-process for device token registration endpoint (/api/devices/register).

_doctor_fcm_tokens: dict[str, str] = {}   # doctor_id -> fcm_device_token
_patient_fcm_tokens: dict[str, str] = {}  # patient_id -> fcm_device_token


def register_doctor_token(doctor_id: str, token: str) -> None:
    """Called by /api/devices/register when a doctor logs in."""
    _doctor_fcm_tokens[doctor_id] = token
    logger.info(f"[Devices] Registered doctor token for {doctor_id}")


def register_patient_token(patient_id: str, token: str) -> None:
    """Called by /api/devices/register when a patient logs in."""
    _patient_fcm_tokens[patient_id] = token
    logger.info(f"[Devices] Registered patient token for {patient_id}")


# ── Public notification helpers ────────────────────────────────────────────────

async def send_new_message_notification(doctor_id: str, patient_name: str, preview: str) -> None:
    """
    Notify a doctor that a patient sent a new chat message.
    Called from the WebSocket handler after each persisted message.
    """
    body_text = preview[:100]
    title_text = f"New message from {patient_name}"

    # 1. Primary: ntfy self-hosted push
    await _send_ntfy(
        topic=f"aarogyamp-doctor-{doctor_id}",
        title=title_text,
        body=body_text,
        priority="default",
        tags="speech_balloon",
    )

    # 2. Migration hook: FCM if configured
    token = _doctor_fcm_tokens.get(doctor_id)
    if token and settings.FCM_SERVER_KEY:
        await _send_fcm(
            title=title_text,
            body=body_text,
            to_token=token,
            data={"event": "new_message", "doctor_id": doctor_id},
        )


async def send_queue_notification(doctor_id: str, patient_name: str) -> None:
    """
    Notify a doctor that a new patient has appeared in their consultation queue.
    Called from consultations.py when a consultation is created.
    """
    title_text = "New Patient in Queue"
    body_text = f"{patient_name} is waiting for a consultation"

    # 1. Primary: ntfy self-hosted push
    await _send_ntfy(
        topic=f"aarogyamp-doctor-{doctor_id}",
        title=title_text,
        body=body_text,
        priority="high",
        tags="hospital,inbox_tray",
    )

    # 2. Migration hook: FCM if configured
    token = _doctor_fcm_tokens.get(doctor_id)
    if token and settings.FCM_SERVER_KEY:
        await _send_fcm(
            title=title_text,
            body=body_text,
            to_token=token,
            data={"event": "new_queue_patient", "doctor_id": doctor_id},
        )


async def send_doctor_responded_notification(patient_id: str, doctor_name: str, preview: str) -> None:
    """
    Notify a patient that the doctor replied in their chat thread.
    Called from the WebSocket handler when sender_role == 'doctor'.
    """
    body_text = preview[:100]
    title_text = f"Dr. {doctor_name} replied"

    # 1. Primary: ntfy self-hosted push
    await _send_ntfy(
        topic=f"aarogyamp-patient-{patient_id}",
        title=title_text,
        body=body_text,
        priority="default",
        tags="stethoscope",
    )

    # 2. Migration hook: FCM if configured
    token = _patient_fcm_tokens.get(patient_id)
    if token and settings.FCM_SERVER_KEY:
        await _send_fcm(
            title=title_text,
            body=body_text,
            to_token=token,
            data={"event": "doctor_reply", "patient_id": patient_id},
        )
