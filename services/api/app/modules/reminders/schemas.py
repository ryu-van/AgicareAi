from pydantic import BaseModel, ConfigDict


class ReminderResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    title: str
    scheduled_at: str
    is_completed: bool = False
    priority: str = "normal"


class ReminderCreateRequest(BaseModel):
    title: str
    scheduled_at: str
    priority: str = "normal"
