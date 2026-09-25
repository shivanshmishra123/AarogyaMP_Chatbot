"""
AarogyaMP — Consultations Router & WebSocket Chat
Person A owns this file.

Endpoints:
  POST /api/consultations
  GET  /api/consultations/{consultation_id}/messages?before=&limit=
  GET  /api/doctor/queue  (doctor role only)
  WS   /ws/chat/{consultation_id}

Milestone 2 additions:
  - Proper cursor-based pagination on GET /messages (before= is now a message ID cursor,
    not just a query hint — returns messages strictly before that ID ordered by timestamp desc
    then reversed, matching the WebSocket reconnect pattern from Reference §14)
  - send_doctor_responded_notification when doctor sends a message (patient gets push)
  - send_queue_notification when a new chat consultation is created (doctor gets push)
  - /api/consultations/{id}/close  — doctor can mark a consultation closed
  - Improved error handling in WS loop (send error frame back instead of silent drop)
"""
import json
import logging
from collections import defaultdict
from typing import Dict, List, Optional

from fastapi import (
    APIRouter,
    Depends,
    HTTPException,
    Query,
    WebSocket,
    WebSocketDisconnect,
    status,
)
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.auth import get_current_user, get_user_by_token, require_doctor, require_patient
from app.database import SessionLocal, get_db
from app.models import AIAssessment, ChatMessage, Consultation, Doctor, Patient, SymptomReport
from app.schemas import (
    ChatMessageListResponse,
    ChatMessageOut,
    ConsultationRequest,
    ConsultationResponse,
    PatientQueueItem,
    WsIncomingMessage,
)
from app.services.notifications import (
    send_doctor_responded_notification,
    send_new_message_notification,
    send_queue_notification,
)

logger = logging.getLogger(__name__)

router = APIRouter()


# ── WebSocket Room Manager ─────────────────────────────────────────────────────

class ChatConnectionManager:
    def __init__(self):
        # consultation_id -> list of active WebSockets
        self.rooms: Dict[str, List[WebSocket]] = defaultdict(list)

    async def connect(self, consultation_id: str, websocket: WebSocket):
        await websocket.accept()
        self.rooms[consultation_id].append(websocket)

    def disconnect(self, consultation_id: str, websocket: WebSocket):
        if consultation_id in self.rooms:
            if websocket in self.rooms[consultation_id]:
                self.rooms[consultation_id].remove(websocket)
            if not self.rooms[consultation_id]:
                del self.rooms[consultation_id]

    async def broadcast(self, consultation_id: str, message: dict):
        if consultation_id in self.rooms:
            for connection in list(self.rooms[consultation_id]):
                try:
                    await connection.send_json(message)
                except Exception as e:
                    logger.warning(f"Failed to send to client: {e}")
                    self.disconnect(consultation_id, connection)


manager = ChatConnectionManager()


# ── Response extras (not in schemas.py to keep that file frozen) ──────────────

class CloseConsultationResponse(BaseModel):
    consultation_id: str
    status: str


# ── REST Endpoints ─────────────────────────────────────────────────────────────

@router.post("/consultations", response_model=ConsultationResponse, status_code=status.HTTP_201_CREATED)
async def create_consultation(
    req: ConsultationRequest,
    current_user: dict = Depends(require_patient),
    db: Session = Depends(get_db),
):
    """
    Start a call/email/chat consultation from a doctor profile.
    Requires an authenticated patient.
    For 'chat' channel, sends a push notification to the doctor.
    """
    # Verify doctor exists and is verified
    doctor = db.query(Doctor).filter(Doctor.id == req.doctor_id).first()
    if not doctor:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Doctor not found",
        )
    if doctor.verification_status != "verified":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Cannot start a consultation with an unverified doctor",
        )

    # Optional: verify symptom report belongs to this patient
    if req.symptom_report_id:
        symptom_report = db.query(SymptomReport).filter(
            SymptomReport.id == req.symptom_report_id,
            SymptomReport.patient_id == current_user["user_id"],
        ).first()
        if not symptom_report:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Symptom report not found or does not belong to this patient",
            )

    new_consultation = Consultation(
        patient_id=current_user["user_id"],
        doctor_id=req.doctor_id,
        symptom_report_id=req.symptom_report_id,
        channel=req.channel,
        status="open",
    )
    db.add(new_consultation)
    db.commit()
    db.refresh(new_consultation)

    # Notify the doctor that a new patient is in their queue (chat channel)
    if req.channel == "chat":
        patient = db.query(Patient).filter(Patient.id == current_user["user_id"]).first()
        patient_name = patient.name if patient else "A patient"
        await send_queue_notification(
            doctor_id=req.doctor_id,
            patient_name=patient_name,
        )

    return ConsultationResponse(consultation_id=new_consultation.id)


@router.get("/consultations/{consultation_id}/messages", response_model=ChatMessageListResponse)
async def get_messages(
    consultation_id: str,
    before: Optional[str] = Query(
        None,
        description=(
            "Cursor for pagination. Pass the ID of the oldest message you already have "
            "to fetch messages before it (for infinite scroll / reconnect re-sync). "
            "Omit to get the most recent `limit` messages."
        ),
    ),
    limit: int = Query(50, ge=1, le=100),
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Cursor-based paginated chat history for a consultation thread.

    Pagination pattern (per Reference §14 WebSocket reconnect):
      1. On reconnect, call GET /messages without `before` → get latest N messages.
      2. To load older history, call GET /messages?before=<oldest_message_id_you_have>.
         Returns up to `limit` messages strictly older than that message, chronologically.

    Only the participating patient or doctor may access this endpoint.
    """
    consultation = db.query(Consultation).filter(Consultation.id == consultation_id).first()
    if not consultation:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Consultation not found")

    user_id = current_user["user_id"]
    if user_id != consultation.patient_id and user_id != consultation.doctor_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied to this consultation")

    query = db.query(ChatMessage).filter(ChatMessage.consultation_id == consultation_id)

    if before:
        # Cursor-based: find the reference message's timestamp, then return messages before it
        ref_msg = db.query(ChatMessage).filter(ChatMessage.id == before).first()
        if not ref_msg:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Cursor message ID '{before}' not found",
            )
        # Fetch messages strictly before the cursor message (by timestamp)
        query = query.filter(ChatMessage.timestamp < ref_msg.timestamp)
        # Order descending to get the most recent ones before the cursor, then reverse
        messages = query.order_by(ChatMessage.timestamp.desc()).limit(limit).all()
        messages = list(reversed(messages))
    else:
        # No cursor: return the most recent `limit` messages in chronological order
        all_msgs = query.order_by(ChatMessage.timestamp.desc()).limit(limit).all()
        messages = list(reversed(all_msgs))

    messages_out = [
        ChatMessageOut(
            id=m.id,
            consultation_id=m.consultation_id,
            sender_role=m.sender_role,
            message_type=m.message_type,
            text=m.text,
            file_path=m.file_path,
            timestamp=m.timestamp,
        )
        for m in messages
    ]
    return ChatMessageListResponse(messages=messages_out)


@router.get("/doctor/queue", response_model=List[PatientQueueItem])
async def get_doctor_queue(
    current_user: dict = Depends(require_doctor),
    db: Session = Depends(get_db),
):
    """
    Doctor's incoming patients queue.
    Returns open consultations with patient name, symptom summary, and AI risk level.
    """
    doctor_id = current_user["user_id"]
    consultations = (
        db.query(Consultation)
        .filter(Consultation.doctor_id == doctor_id, Consultation.status == "open")
        .order_by(Consultation.started_at.desc())
        .all()
    )

    queue_items: List[PatientQueueItem] = []

    for consult in consultations:
        patient = db.query(Patient).filter(Patient.id == consult.patient_id).first()
        patient_name = patient.name if patient else "Unknown Patient"

        symptom_summary = "General consultation"
        risk_level = None
        is_emergency = False

        if consult.symptom_report_id:
            sreport = db.query(SymptomReport).filter(SymptomReport.id == consult.symptom_report_id).first()
            if sreport:
                symptom_summary = sreport.raw_text[:100] + ("..." if len(sreport.raw_text) > 100 else "")

                assessment = (
                    db.query(AIAssessment)
                    .filter(AIAssessment.symptom_report_id == sreport.id)
                    .order_by(AIAssessment.created_at.desc())
                    .first()
                )
                if assessment:
                    risk_level = assessment.risk_level
                    is_emergency = assessment.is_emergency

        queue_items.append(
            PatientQueueItem(
                consultation_id=consult.id,
                patient_name=patient_name,
                symptom_summary=symptom_summary,
                risk_level=risk_level,
                is_emergency=is_emergency,
                started_at=consult.started_at,
            )
        )

    return queue_items


@router.post(
    "/consultations/{consultation_id}/close",
    response_model=CloseConsultationResponse,
)
async def close_consultation(
    consultation_id: str,
    current_user: dict = Depends(require_doctor),
    db: Session = Depends(get_db),
):
    """
    Doctor marks a consultation as closed (resolved).
    Closed consultations move to the history view for both roles.
    Only the attending doctor can close a consultation.
    """
    consultation = db.query(Consultation).filter(Consultation.id == consultation_id).first()
    if not consultation:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Consultation not found")

    if consultation.doctor_id != current_user["user_id"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only the attending doctor can close this consultation",
        )

    if consultation.status == "closed":
        return CloseConsultationResponse(consultation_id=consultation_id, status="closed")

    from datetime import datetime
    consultation.status = "closed"
    consultation.ended_at = datetime.utcnow()
    db.commit()
    db.refresh(consultation)
    logger.info(f"[Consultation] {consultation_id} closed by doctor {current_user['user_id']}")

    return CloseConsultationResponse(consultation_id=consultation_id, status="closed")


# ── WebSocket Chat ─────────────────────────────────────────────────────────────

ws_router = APIRouter()


@ws_router.websocket("/ws/chat/{consultation_id}")
@router.websocket("/ws/chat/{consultation_id}")
async def websocket_chat(websocket: WebSocket, consultation_id: str, db: Session = Depends(get_db)):
    """
    Bidirectional WebSocket chat endpoint.

    Client sends:
      { "type": "text"|"voice"|"image", "content": "..." }

    Server:
      1. Authenticates user (token in ?token= query param or initial auth frame)
      2. Verifies participation in the consultation
      3. Persists each message as ChatMessage
      4. Broadcasts to all room members
      5. Sends push notification to the other party

    Auth: token in query string (?token=...) or an initial JSON auth frame: { "token": "..." }
    """
    await websocket.accept()
    token = websocket.query_params.get("token")

    try:
        # If not provided in query param, read first frame
        if not token:
            first_msg = await websocket.receive_text()
            try:
                data = json.loads(first_msg)
                token = data.get("token")
            except Exception:
                await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
                return

        # Authenticate user
        try:
            user_info = get_user_by_token(token, db)
        except Exception as e:
            logger.warning(f"WebSocket auth failed: {e}")
            await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
            return

        # Verify consultation and participation
        consultation = db.query(Consultation).filter(Consultation.id == consultation_id).first()
        if not consultation:
            await websocket.send_json({"error": "consultation_not_found"})
            await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
            return

        user_id = user_info["user_id"]
        role = user_info["role"]
        if user_id != consultation.patient_id and user_id != consultation.doctor_id:
            await websocket.send_json({"error": "access_denied"})
            await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
            return

        if consultation.status == "closed":
            await websocket.send_json({"error": "consultation_closed"})
            await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
            return

        # Register connection in room manager
        manager.rooms[consultation_id].append(websocket)
        logger.info(f"[WS] {role} {user_id} connected to consultation {consultation_id}")

        # Look up names for push notifications
        patient = db.query(Patient).filter(Patient.id == consultation.patient_id).first()
        doctor = db.query(Doctor).filter(Doctor.id == consultation.doctor_id).first()
        patient_name = patient.name if patient else "Patient"
        doctor_name = doctor.name if doctor else "Doctor"

        # Main message loop
        while True:
            raw_text = await websocket.receive_text()
            try:
                payload = json.loads(raw_text)
                msg_in = WsIncomingMessage(**payload)
            except Exception as parse_err:
                logger.warning(f"Invalid message format received: {parse_err}")
                await websocket.send_json({"error": "invalid_message_format"})
                continue

            # Persist message
            chat_msg = ChatMessage(
                consultation_id=consultation_id,
                sender_role=role,
                message_type=msg_in.type,
                text=msg_in.content if msg_in.type == "text" else None,
                file_path=msg_in.content if msg_in.type in ["voice", "image", "document"] else None,
            )
            db.add(chat_msg)
            db.commit()
            db.refresh(chat_msg)

            # Prepare broadcast payload
            broadcast_payload = {
                "id": chat_msg.id,
                "consultation_id": consultation_id,
                "sender_role": role,
                "message_type": msg_in.type,
                "text": chat_msg.text,
                "file_path": chat_msg.file_path,
                "timestamp": chat_msg.timestamp.isoformat(),
            }

            # Broadcast to all clients in the room
            await manager.broadcast(consultation_id, broadcast_payload)

            # Send push notification to the OTHER party
            preview = (msg_in.content[:80] if msg_in.type == "text" else f"[{msg_in.type} message]")
            if role == "patient":
                # Patient sent a message → notify doctor
                await send_new_message_notification(
                    doctor_id=consultation.doctor_id,
                    patient_name=patient_name,
                    preview=preview,
                )
            elif role == "doctor":
                # Doctor replied → notify patient
                await send_doctor_responded_notification(
                    patient_id=consultation.patient_id,
                    doctor_name=doctor_name,
                    preview=preview,
                )

    except WebSocketDisconnect:
        manager.disconnect(consultation_id, websocket)
        logger.info(f"[WS] Client disconnected from {consultation_id}")
    except Exception as e:
        logger.error(f"WebSocket error in {consultation_id}: {e}")
        manager.disconnect(consultation_id, websocket)
