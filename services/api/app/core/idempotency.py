import hashlib
import json
from collections.abc import Callable
from typing import Any

from sqlalchemy import select
from sqlalchemy.orm import Session

from services.api.app.core.errors import AppError
from services.api.app.db.models import IdempotencyKey


def require_idempotency_key(value: str | None) -> str:
    if value is None or not 16 <= len(value) <= 128:
        raise AppError(422, "VALIDATION_ERROR", "Idempotency-Key phải dài từ 16 đến 128 ký tự.")
    return value


def request_hash(operation: str, payload: dict[str, Any]) -> str:
    canonical = json.dumps({"operation": operation, "payload": payload}, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
    return hashlib.sha256(canonical.encode("utf-8")).hexdigest()


def execute_idempotent(
    session: Session,
    *,
    user_id: str,
    key: str,
    operation: str,
    payload: dict[str, Any],
    action: Callable[[], tuple[int, dict[str, Any]]],
) -> tuple[int, dict[str, Any]]:
    digest = request_hash(operation, payload)
    existing = session.scalar(select(IdempotencyKey).where(IdempotencyKey.user_id == user_id, IdempotencyKey.key == key))
    if existing:
        if existing.request_hash != digest:
            raise AppError(409, "CONFLICT", "Idempotency-Key đã được dùng cho một yêu cầu khác.")
        return existing.response_status, existing.response_body

    status_code, body = action()
    session.flush()
    session.add(
        IdempotencyKey(
            user_id=user_id,
            key=key,
            request_hash=digest,
            response_status=status_code,
            response_body=body,
        )
    )
    session.commit()
    return status_code, body
