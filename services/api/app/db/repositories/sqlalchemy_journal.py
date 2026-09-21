"""Concrete SQLAlchemy repository for journal entries."""

from sqlalchemy import select
from sqlalchemy.orm import Session

from services.api.app.core.errors import AppError
from services.api.app.db.models import JournalEntry, Subject
from services.api.app.modules.journal.schemas import CreateJournalEntryRequest


class SqlAlchemyJournalRepository:
    def create_journal_entry(self, session: Session, user_id: str, request: CreateJournalEntryRequest) -> JournalEntry:
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

    def list_journal_entries(
        self,
        session: Session,
        user_id: str,
        subject_id: str | None = None,
        since: str | None = None,
        limit: int = 50,
    ) -> list[JournalEntry]:
        stmt = select(JournalEntry).where(
            JournalEntry.user_id == user_id,
            JournalEntry.deleted_at.is_(None),
        )
        if subject_id:
            stmt = stmt.where(JournalEntry.subject_id == subject_id)
        if since:
            try:
                from datetime import datetime
                since_dt = datetime.fromisoformat(since)
                stmt = stmt.where(JournalEntry.updated_at > since_dt)
            except Exception:
                pass
        stmt = stmt.order_by(JournalEntry.observed_at.desc()).limit(limit)
        return list(session.scalars(stmt).all())

