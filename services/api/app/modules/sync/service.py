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

    entity_id: str | None = None
    if event.entity == "journal_entry" and event.operation == "upsert":
        try:
            from services.api.app.db.models import JournalEntry
            from services.api.app.modules.journal.schemas import CreateJournalEntryRequest, UpdateJournalEntryRequest
            from services.api.app.modules.journal.service import create_journal_entry, update_journal_entry

            target_entry: JournalEntry | None = None
            candidate_id = event.payload.get("original_event_id") or event.payload.get("client_event_id") or event.event_id
            if candidate_id:
                target_entry = session.scalar(
                    select(JournalEntry).where(
                        JournalEntry.user_id == user_id,
                        JournalEntry.client_event_id == candidate_id,
                    )
                )
            if not target_entry and event.payload.get("entry_id"):
                target_entry = session.scalar(
                    select(JournalEntry).where(
                        JournalEntry.user_id == user_id,
                        JournalEntry.id == event.payload["entry_id"],
                    )
                )

            if target_entry:
                update_req = UpdateJournalEntryRequest.model_validate(event.payload)
                updated_entry = update_journal_entry(session, user_id, target_entry.id, update_req)
                updated_entry.client_event_id = event.event_id
                entity_id = updated_entry.id
            else:
                req = CreateJournalEntryRequest.model_validate(
                    {
                        "client_event_id": event.event_id,
                        **event.payload,
                    }
                )
                entry = create_journal_entry(session, user_id, req)
                entity_id = entry.id
        except Exception:
            pass
    elif event.entity == "journal_entry" and event.operation == "delete":
        try:
            from services.api.app.modules.journal.service import delete_journal_entry
            target_id = event.payload.get("entry_id")
            if not target_id and event.payload.get("client_event_id"):
                from services.api.app.db.models import JournalEntry
                found = session.scalar(
                    select(JournalEntry).where(
                        JournalEntry.user_id == user_id,
                        JournalEntry.client_event_id == event.payload["client_event_id"],
                    )
                )
                if found:
                    target_id = found.id
            if target_id:
                delete_journal_entry(session, user_id, target_id)
                entity_id = target_id
        except Exception:
            pass

    sync_event = SyncEvent(
        user_id=user_id,
        event_id=event.event_id,
        entity=event.entity,
        operation=event.operation,
        payload=event.payload,
        payload_hash=digest,
        status="applied",
        entity_id=entity_id,
    )
    session.add(sync_event)
    session.flush()
    return SyncResult(event_id=event.event_id, status="applied", entity_id=sync_event.entity_id)

