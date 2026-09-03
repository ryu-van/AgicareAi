from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field


class SubjectResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    domain: Literal["plant", "animal"]
    name: str


class KnowledgeArticleResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    domain: Literal["plant", "animal"]
    subject_id: str
    title: str
    summary: str | None
    content: str
    topic: str | None
    source_name: str | None
    status: Literal["published"]
    published_at: datetime | None


class KnowledgeArticleListResponse(BaseModel):
    items: list[KnowledgeArticleResponse]
    next_cursor: str | None = None


class KnowledgeCitation(BaseModel):
    article_id: str
    title: str
    section: str | None = None
    revision: str | None = None
