from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field, field_validator


class CreateJournalEntryRequest(BaseModel):
    subject_id: str = Field(max_length=64)
    entry_type: Literal["observation", "treatment", "harvest", "vaccination", "feeding"]
    observed_at: datetime
    timezone: str = Field(default="Asia/Ho_Chi_Minh", max_length=64)
    title: str = Field(min_length=1, max_length=160)
    notes: str | None = Field(default=None, max_length=5000)
    photo_url: str | None = Field(default=None, max_length=512)
    client_event_id: str | None = Field(default=None, max_length=128)

    @field_validator("title")
    @classmethod
    def title_must_not_be_blank(cls, value: str) -> str:
        if not value.strip():
            raise ValueError("must not be blank")
        return value.strip()


class UpdateJournalEntryRequest(BaseModel):
    title: str | None = Field(default=None, min_length=1, max_length=160)
    entry_type: Literal["observation", "treatment", "harvest", "vaccination", "feeding"] | None = None
    subject_id: str | None = Field(default=None, max_length=64)
    observed_at: datetime | None = None
    timezone: str | None = Field(default=None, max_length=64)
    notes: str | None = Field(default=None, max_length=5000)
    photo_url: str | None = Field(default=None, max_length=512)

    @field_validator("title")
    @classmethod
    def title_must_not_be_blank(cls, value: str | None) -> str | None:
        if value is not None and not value.strip():
            raise ValueError("must not be blank")
        return value.strip() if value is not None else None


class JournalEntryResponse(CreateJournalEntryRequest):
    model_config = ConfigDict(from_attributes=True)

    id: str
    created_at: datetime
    updated_at: datetime | None = None
    deleted_at: datetime | None = None


class JournalListResponse(BaseModel):
    items: list[JournalEntryResponse]
    total: int

