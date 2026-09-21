from sqlalchemy.orm import Session

from services.api.app.db.models import JournalEntry
from services.api.app.db.repositories.sqlalchemy_journal import SqlAlchemyJournalRepository
from services.api.app.modules.journal.schemas import CreateJournalEntryRequest

_journal_repo = SqlAlchemyJournalRepository()


def create_journal_entry(session: Session, user_id: str, request: CreateJournalEntryRequest) -> JournalEntry:
    return _journal_repo.create_journal_entry(session, user_id, request)


def list_journal_entries(
    session: Session,
    user_id: str,
    subject_id: str | None = None,
    since: str | None = None,
    limit: int = 50,
) -> list[JournalEntry]:
    return _journal_repo.list_journal_entries(session, user_id, subject_id=subject_id, since=since, limit=limit)


