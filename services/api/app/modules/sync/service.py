import hashlib
import json

from sqlalchemy import select
from sqlalchemy.orm import Session

from services.api.app.db.models import SyncEvent
from services.api.app.modules.sync.schemas import SyncEventRequest, SyncResult


def payload_hash(event: SyncEventRequest) -> str:
    canonical = json.dumps(event.model_dump(mode="json"), ensure_ascii=False, sort_keys=True, separators=(",", ":"))
    return hashlib.sha256(canonical.encode("utf-8")).hexdigest()


def apply_event(session: Session, user_id: str, event: SyncEventRequest) -> SyncResult:
    digest = payload_hash(event)
    existing = session.scalar(select(SyncEvent).where(SyncEvent.user_id == user_id, SyncEvent.event_id == event.event_id))
    if existing:
        if existing.payload_hash == digest:
            return SyncResult(event_id=event.event_id, status="duplicate", entity_id=existing.entity_id)
        return SyncResult(event_id=event.event_id, status="conflict", entity_id=existing.entity_id)

    sync_event = SyncEvent(
        user_id=user_id,
        event_id=event.event_id,
        entity=event.entity,
        operation=event.operation,
        payload=event.payload,
        payload_hash=digest,
        status="applied",
    )
    session.add(sync_event)
    session.flush()
    return SyncResult(event_id=event.event_id, status="applied", entity_id=sync_event.entity_id)
