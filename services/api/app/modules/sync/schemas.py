from typing import Literal

from pydantic import BaseModel, Field


class SyncEventRequest(BaseModel):
    event_id: str = Field(min_length=1, max_length=128)
    entity: Literal["journal_entry", "reminder"]
    operation: Literal["upsert", "delete"]
    payload: dict[str, object]


class SyncBatchRequest(BaseModel):
    events: list[SyncEventRequest] = Field(min_length=1, max_length=50)


class SyncResult(BaseModel):
    event_id: str
    status: Literal["applied", "duplicate", "conflict", "rejected"]
    entity_id: str | None = None


class SyncBatchResponse(BaseModel):
    results: list[SyncResult]
    server_cursor: str | None = None
