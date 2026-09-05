from fastapi import APIRouter, Depends
from services.api.app.core.auth import UserPrincipal, get_current_user
from services.api.app.modules.farm.schemas import FarmCreateRequest, FarmSummaryResponse
from services.api.app.modules.farm.service import create_user_farm, get_user_farms

router = APIRouter(prefix="/v1/farm", tags=["farm"])


@router.get("/summary", response_model=list[FarmSummaryResponse])
def get_farms(user: UserPrincipal = Depends(get_current_user)) -> list[FarmSummaryResponse]:
    farms = get_user_farms(user.user_id)
    return [FarmSummaryResponse.model_validate(f) for f in farms]


@router.post("", response_model=FarmSummaryResponse, status_code=201)
def create_farm(
    request: FarmCreateRequest,
    user: UserPrincipal = Depends(get_current_user),
) -> FarmSummaryResponse:
    farm = create_user_farm(user.user_id, request)
    return FarmSummaryResponse.model_validate(farm)
