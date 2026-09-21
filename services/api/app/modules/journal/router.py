from typing import Annotated

from fastapi import APIRouter, Depends, Header, Response
from sqlalchemy.orm import Session

from services.api.app.core.auth import UserPrincipal, get_current_user
from services.api.app.core.db import get_session
from services.api.app.core.errors import AppError
from services.api.app.core.idempotency import execute_idempotent, require_idempotency_key
from services.api.app.modules.journal.schemas import (
    CreateJournalEntryRequest,
    JournalEntryResponse,
    JournalListResponse,
    UpdateJournalEntryRequest,
)
from services.api.app.modules.journal.service import (
    create_journal_entry,
    delete_journal_entry,
    get_journal_entry,
    list_journal_entries,
    update_journal_entry,
)

router = APIRouter(prefix="/v1/journal", tags=["journal"])


@router.get("/entries", response_model=JournalListResponse)
def list_entries(
    subject_id: str | None = None,
    since: str | None = None,
    limit: int = 50,
    user: UserPrincipal = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> JournalListResponse:
    entries = list_journal_entries(session, user.user_id, subject_id=subject_id, since=since, limit=limit)
    items = [JournalEntryResponse.model_validate(e) for e in entries]
    return JournalListResponse(items=items, total=len(items))


@router.get("/entries/{entry_id}", response_model=JournalEntryResponse)
def get_entry(
    entry_id: str,
    user: UserPrincipal = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> JournalEntryResponse:
    entry = get_journal_entry(session, user.user_id, entry_id)
    if not entry:
        raise AppError(404, "NOT_FOUND", "Không tìm thấy nhật ký canh tác.")
    return JournalEntryResponse.model_validate(entry)


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


@router.patch("/entries/{entry_id}", response_model=JournalEntryResponse)
def update_entry(
    entry_id: str,
    request: UpdateJournalEntryRequest,
    idempotency_key: Annotated[str | None, Header(alias="Idempotency-Key")] = None,
    user: UserPrincipal = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> Response:
    key = require_idempotency_key(idempotency_key)

    def action() -> tuple[int, dict]:
        entry = update_journal_entry(session, user.user_id, entry_id, request)
        return 200, JournalEntryResponse.model_validate(entry).model_dump(mode="json")

    status_code, body = execute_idempotent(
        session,
        user_id=user.user_id,
        key=key,
        operation=f"update_journal_entry:{entry_id}",
        payload=request.model_dump(mode="json"),
        action=action,
    )
    return Response(
        content=JournalEntryResponse.model_validate(body).model_dump_json(),
        status_code=status_code,
        media_type="application/json",
    )


@router.delete("/entries/{entry_id}", status_code=204)
def delete_entry(
    entry_id: str,
    user: UserPrincipal = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> Response:
    delete_journal_entry(session, user.user_id, entry_id)
    return Response(status_code=204)

