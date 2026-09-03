from sqlalchemy import select
from sqlalchemy.orm import Session

from services.api.app.core.errors import AppError
from services.api.app.db.models import JournalEntry, Subject
from services.api.app.modules.journal.schemas import CreateJournalEntryRequest


def create_journal_entry(session: Session, user_id: str, request: CreateJournalEntryRequest) -> JournalEntry:
    subject = session.scalar(select(Subject).where(Subject.id == request.subject_id, Subject.status == "published"))
    if subject is None:
        raise AppError(422, "VALIDATION_ERROR", "Đối tượng chưa được hỗ trợ.")

    if request.client_event_id:
        existing = session.scalar(
            select(JournalEntry).where(
                JournalEntry.user_id == user_id,
                JournalEntry.client_event_id == request.client_event_id,
            )
        )
        if existing:
            return existing

    entry = JournalEntry(user_id=user_id, **request.model_dump())
    session.add(entry)
    session.flush()
    return entry
