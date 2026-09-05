"""Push notification client adapter."""


class PushNotificationAdapter:
    def send_push_notification(self, user_id: str, title: str, body: str) -> bool:
        return True
