from typing import Annotated

from fastapi import APIRouter, Depends, Header, Response
from sqlalchemy.orm import Session

from services.api.app.core.auth import UserPrincipal, get_current_user
from services.api.app.core.db import get_session
from services.api.app.core.idempotency import execute_idempotent, require_idempotency_key
from services.api.app.modules.sync.schemas import SyncBatchRequest, SyncBatchResponse
from services.api.app.modules.sync.service import apply_event

router = APIRouter(prefix="/v1/sync", tags=["sync"])


@router.post("/batch", response_model=SyncBatchResponse)
def sync_batch(
    request: SyncBatchRequest,
    idempotency_key: Annotated[str | None, Header(alias="Idempotency-Key")] = None,
    user: UserPrincipal = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> Response:
    key = require_idempotency_key(idempotency_key)

    def action() -> tuple[int, dict]:
        results = [apply_event(session, user.user_id, event) for event in request.events]
        body = SyncBatchResponse(results=results).model_dump(mode="json")
        return 200, body

    status_code, body = execute_idempotent(
        session,
        user_id=user.user_id,
        key=key,
        operation="sync_batch",
        payload=request.model_dump(mode="json"),
        action=action,
    )
    return Response(content=SyncBatchResponse.model_validate(body).model_dump_json(), status_code=status_code, media_type="application/json")
