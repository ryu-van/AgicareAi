from datetime import datetime, timezone
from sqlalchemy import select
from sqlalchemy.orm import Session

from services.api.app.core.errors import AppError
from services.api.app.db.models import JournalEntry, Subject
from services.api.app.modules.journal.schemas import CreateJournalEntryRequest, UpdateJournalEntryRequest


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
                from sqlalchemy import func
                since_dt = datetime.fromisoformat(since)
                stmt = stmt.where(func.coalesce(JournalEntry.updated_at, JournalEntry.created_at) > since_dt)
            except Exception:
                pass
        stmt = stmt.order_by(JournalEntry.observed_at.desc()).limit(limit)
        return list(session.scalars(stmt).all())

    def get_journal_entry(self, session: Session, user_id: str, entry_id: str) -> JournalEntry | None:
        return session.scalar(
            select(JournalEntry).where(
                JournalEntry.id == entry_id,
                JournalEntry.user_id == user_id,
                JournalEntry.deleted_at.is_(None),
            )
        )

    def update_journal_entry(
        self, session: Session, user_id: str, entry_id: str, request: UpdateJournalEntryRequest
    ) -> JournalEntry:
        entry = self.get_journal_entry(session, user_id, entry_id)
        if not entry:
            raise AppError(404, "NOT_FOUND", "Không tìm thấy nhật ký canh tác.")

        fields = request.model_fields_set
        if "subject_id" in fields and request.subject_id is not None:
            subject = session.scalar(select(Subject).where(Subject.id == request.subject_id, Subject.status == "published"))
            if subject is None:
                raise AppError(422, "VALIDATION_ERROR", "Đối tượng chưa được hỗ trợ.")
            entry.subject_id = request.subject_id

        if "title" in fields and request.title is not None:
            entry.title = request.title
        if "entry_type" in fields and request.entry_type is not None:
            entry.entry_type = request.entry_type
        if "observed_at" in fields and request.observed_at is not None:
            entry.observed_at = request.observed_at
        if "timezone" in fields and request.timezone is not None:
            entry.timezone = request.timezone
        if "notes" in fields:
            entry.notes = request.notes
        if "photo_url" in fields:
            entry.photo_url = request.photo_url

        entry.updated_at = datetime.now(timezone.utc)
        session.flush()
        return entry

    def delete_journal_entry(self, session: Session, user_id: str, entry_id: str) -> bool:
        entry = session.scalar(
            select(JournalEntry).where(
                JournalEntry.id == entry_id,
                JournalEntry.user_id == user_id,
            )
        )
        if not entry:
            raise AppError(404, "NOT_FOUND", "Không tìm thấy nhật ký canh tác.")

        if entry.deleted_at is None:
            entry.deleted_at = datetime.now(timezone.utc)
            session.flush()
        return True

