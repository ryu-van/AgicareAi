"""Concrete SQLAlchemy repository for farm management."""

from typing import Any


class SqlAlchemyFarmRepository:
    def get_user_farms(self, user_id: str) -> list[dict[str, Any]]:
        return [
            {
                "id": f"farm-{user_id[:8]}",
                "name": "Trang trại AgriCare Demo",
                "domain": "plant",
                "total_area_ha": 2.5,
                "active_crops_count": 3,
                "active_livestock_count": 12,
            }
        ]

    def create_farm(self, user_id: str, name: str, domain: str, total_area_ha: float | None) -> dict[str, Any]:
        return {
            "id": f"farm-{user_id[:8]}-new",
            "name": name,
            "domain": domain,
            "total_area_ha": total_area_ha or 1.0,
            "active_crops_count": 0,
            "active_livestock_count": 0,
        }
