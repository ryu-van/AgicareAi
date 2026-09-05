"""Shared contract schemas across API endpoints."""

from typing import Generic, TypeVar
from pydantic import BaseModel

T = TypeVar("T")


class APIResponseEnvelope(BaseModel, Generic[T]):
    success: bool = True
    data: T | None = None
    message: str | None = None


class PaginatedMeta(BaseModel):
    page: int = 1
    page_size: int = 20
    total_items: int = 0
