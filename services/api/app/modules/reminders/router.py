from fastapi import APIRouter, Depends
from services.api.app.core.auth import UserPrincipal, get_current_user
from services.api.app.modules.reminders.schemas import ReminderCreateRequest, ReminderResponse
from services.api.app.modules.reminders.service import create_user_reminder, get_user_reminders

router = APIRouter(prefix="/v1/reminders", tags=["reminders"])


@router.get("", response_model=list[ReminderResponse])
def list_reminders(user: UserPrincipal = Depends(get_current_user)) -> list[ReminderResponse]:
    items = get_user_reminders(user.user_id)
    return [ReminderResponse.model_validate(item) for item in items]


@router.post("", response_model=ReminderResponse, status_code=201)
def create_reminder(
    request: ReminderCreateRequest,
    user: UserPrincipal = Depends(get_current_user),
) -> ReminderResponse:
    item = create_user_reminder(user.user_id, request)
    return ReminderResponse.model_validate(item)
