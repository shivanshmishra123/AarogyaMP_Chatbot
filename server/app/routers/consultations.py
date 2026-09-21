"""
AarogyaMP — Consultations router + WebSocket chat stub
Person A owns this file.

Endpoints:
  POST /api/consultations
  GET  /api/consultations/{id}/messages?before=&limit=
  WS   /ws/chat/{consultation_id}
  GET  /api/doctor/queue  (doctor role only)

TODO (M1 — Person A): POST + WS.
TODO (M2 — Person A): Message pagination, FCM push notifications.
"""
from fastapi import APIRouter, WebSocket

router = APIRouter()


@router.post("/consultations")
async def create_consultation():
    raise NotImplementedError("M1 — Person A")


@router.get("/consultations/{consultation_id}/messages")
async def get_messages(consultation_id: str, before: str = None, limit: int = 50):
    raise NotImplementedError("M2 — Person A")


@router.get("/doctor/queue")
async def get_doctor_queue():
    raise NotImplementedError("M1 — Person A")


@router.websocket("/ws/chat/{consultation_id}")
async def websocket_chat(websocket: WebSocket, consultation_id: str):
    """
    Bidirectional WebSocket chat.
    Client sends: { "type": "text"|"voice"|"image", "content": "..." }
    Server broadcasts to both participants + persists ChatMessage.
    Auth: token in query string or initial auth frame.
    """
    raise NotImplementedError("M1 — Person A")
