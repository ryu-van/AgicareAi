"""Journal repository interface."""

from typing import Any, Protocol
from sqlalchemy.orm import Session
from services.api.app.modules.journal.schemas import CreateJournalEntryRequest


class JournalRepositoryProtocol(Protocol):
    def create_journal_entry(self, session: Session, user_id: str, request: CreateJournalEntryRequest) -> Any:
        ...
