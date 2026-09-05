from pydantic import BaseModel, ConfigDict


class FarmSummaryResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    name: str
    domain: str
    total_area_ha: float | None = None
    active_crops_count: int = 0
    active_livestock_count: int = 0


class FarmCreateRequest(BaseModel):
    name: str
    domain: str
    total_area_ha: float | None = None
