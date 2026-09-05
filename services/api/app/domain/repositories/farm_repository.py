"""Farm repository interface."""

from typing import Any, Protocol


class FarmRepositoryProtocol(Protocol):
    def get_user_farms(self, user_id: str) -> list[dict[str, Any]]:
        ...

    def create_farm(self, user_id: str, name: str, domain: str, total_area_ha: float | None) -> dict[str, Any]:
        ...
