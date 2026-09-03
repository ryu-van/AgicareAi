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
    client_event_id: str | None = Field(default=None, max_length=128)

    @field_validator("title")
    @classmethod
    def title_must_not_be_blank(cls, value: str) -> str:
        if not value.strip():
            raise ValueError("must not be blank")
        return value.strip()


class JournalEntryResponse(CreateJournalEntryRequest):
    model_config = ConfigDict(from_attributes=True)

    id: str
    created_at: datetime
