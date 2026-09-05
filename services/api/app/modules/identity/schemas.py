from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field


class ProfileResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    display_name: str | None
    locale: str
    region_code: str | None


class UpdateProfileRequest(BaseModel):
    display_name: str | None = Field(default=None, max_length=120)
    locale: str | None = Field(default=None, max_length=16)
    region_code: str | None = Field(default=None, max_length=32)


class CreateConsentRequest(BaseModel):
    consent_type: Literal["privacy", "ai_disclaimer", "notifications"]
    version: str = Field(min_length=1, max_length=32)


class ConsentResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    consent_type: str
    version: str
    accepted_at: datetime
