from typing import Any
from services.api.app.db.repositories.sqlalchemy_farm import SqlAlchemyFarmRepository
from services.api.app.modules.farm.schemas import FarmCreateRequest

_farm_repo = SqlAlchemyFarmRepository()


def get_user_farms(user_id: str) -> list[dict[str, Any]]:
    return _farm_repo.get_user_farms(user_id)


def create_user_farm(user_id: str, request: FarmCreateRequest) -> dict[str, Any]:
    return _farm_repo.create_farm(user_id, request.name, request.domain, request.total_area_ha)

