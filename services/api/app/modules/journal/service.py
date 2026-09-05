from sqlalchemy.orm import Session

from services.api.app.db.models import JournalEntry
from services.api.app.db.repositories.sqlalchemy_journal import SqlAlchemyJournalRepository
from services.api.app.modules.journal.schemas import CreateJournalEntryRequest

_journal_repo = SqlAlchemyJournalRepository()


def create_journal_entry(session: Session, user_id: str, request: CreateJournalEntryRequest) -> JournalEntry:
    return _journal_repo.create_journal_entry(session, user_id, request)

