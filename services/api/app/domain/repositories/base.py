"""Base repository protocol interface."""

from typing import Generic, Protocol, TypeVar

T = TypeVar("T")


class BaseRepository(Protocol[T]):
    """Generic base repository interface defining essential CRUD contracts."""

    def get_by_id(self, entity_id: str) -> T | None:
        ...

    def list_all(self, limit: int = 100, offset: int = 0) -> list[T]:
        ...
