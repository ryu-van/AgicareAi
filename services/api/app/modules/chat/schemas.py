from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field, field_validator


class CreateChatSessionRequest(BaseModel):
    domain: Literal["plant", "animal"]
    subject_id: str | None = Field(default=None, max_length=64)
    title: str | None = Field(default=None, max_length=120)


class ChatSessionResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    domain: Literal["plant", "animal"]
    subject_id: str | None
    title: str | None
    created_at: datetime


class SendChatMessageRequest(BaseModel):
    content: str = Field(min_length=1, max_length=5000)
    context: dict[str, object] | None = None

    @field_validator("content")
    @classmethod
    def content_must_not_be_blank(cls, value: str) -> str:
        if not value.strip():
            raise ValueError("must not be blank")
        return value.strip()


class ChatMessageResponse(BaseModel):
    message_id: str
    status: Literal["queued", "processing", "completed", "failed", "safety_blocked"]
    role: Literal["assistant"]
    answer: str | None
    safety_level: Literal["normal", "caution", "urgent"] | None
    needs_expert: bool
    citations: list[dict[str, object]]
    created_at: datetime
