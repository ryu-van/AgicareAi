"""Knowledge repository interface."""

from typing import Any, Protocol
from sqlalchemy.orm import Session


class KnowledgeRepositoryProtocol(Protocol):
    def get_article_by_id(self, session: Session, article_id: str) -> Any | None:
        ...

    def list_articles(self, session: Session, domain: str | None, query: str | None) -> list[Any]:
        ...
