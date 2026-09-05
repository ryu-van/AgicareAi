from typing import Any
from services.api.app.modules.reminders.schemas import ReminderCreateRequest


def get_user_reminders(user_id: str) -> list[dict[str, Any]]:
    return [
        {
            "id": "rem-001",
            "title": "Tưới nước lúa vụ Đông Xuân",
            "scheduled_at": "2026-09-04T07:00:00Z",
            "is_completed": False,
            "priority": "high",
        },
        {
            "id": "rem-002",
            "title": "Tiêm vắc xin phòng bệnh cho đàn gà",
            "scheduled_at": "2026-09-05T08:00:00Z",
            "is_completed": False,
            "priority": "normal",
        },
    ]


def create_user_reminder(user_id: str, request: ReminderCreateRequest) -> dict[str, Any]:
    return {
        "id": "rem-new",
        "title": request.title,
        "scheduled_at": request.scheduled_at,
        "is_completed": False,
        "priority": request.priority,
    }
