from collections import defaultdict, deque
from time import monotonic

from services.api.app.core.errors import AppError


class InMemoryRateLimiter:
    """Local single-process limiter; replace with a shared store before multi-instance deployment."""

    def __init__(self, limit: int, window_seconds: int):
        self.limit = limit
        self.window_seconds = window_seconds
        self._requests: dict[str, deque[float]] = defaultdict(deque)

    def enforce(self, key: str) -> None:
        now = monotonic()
        timestamps = self._requests[key]
        while timestamps and timestamps[0] <= now - self.window_seconds:
            timestamps.popleft()
        if len(timestamps) >= self.limit:
            retry_after = max(1, int(self.window_seconds - (now - timestamps[0])) + 1)
            raise AppError(
                429,
                "RATE_LIMITED",
                "Bạn đã gửi quá nhiều yêu cầu. Vui lòng thử lại sau.",
                headers={"Retry-After": str(retry_after)},
            )
        timestamps.append(now)


chat_rate_limiter = InMemoryRateLimiter(limit=20, window_seconds=60)
