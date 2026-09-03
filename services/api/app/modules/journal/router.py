from typing import Annotated

from fastapi import APIRouter, Depends, Header, Response
from sqlalchemy.orm import Session

from services.api.app.core.auth import UserPrincipal, get_current_user
from services.api.app.core.db import get_session
from services.api.app.core.idempotency import execute_idempotent, require_idempotency_key
from services.api.app.modules.journal.schemas import CreateJournalEntryRequest, JournalEntryResponse
from services.api.app.modules.journal.service import create_journal_entry

router = APIRouter(prefix="/v1/journal", tags=["journal"])


@router.post("/entries", response_model=JournalEntryResponse, status_code=201)
def create_entry(
    request: CreateJournalEntryRequest,
    idempotency_key: Annotated[str | None, Header(alias="Idempotency-Key")] = None,
    user: UserPrincipal = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> Response:
    key = require_idempotency_key(idempotency_key)

    def action() -> tuple[int, dict]:
        entry = create_journal_entry(session, user.user_id, request)
        return 201, JournalEntryResponse.model_validate(entry).model_dump(mode="json")

    status_code, body = execute_idempotent(
        session,
        user_id=user.user_id,
        key=key,
        operation="create_journal_entry",
        payload=request.model_dump(mode="json"),
        action=action,
    )
    return Response(content=JournalEntryResponse.model_validate(body).model_dump_json(), status_code=status_code, media_type="application/json")
