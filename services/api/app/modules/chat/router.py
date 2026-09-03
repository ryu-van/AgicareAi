from typing import Annotated

from fastapi import APIRouter, Depends, Header, Response
from sqlalchemy.orm import Session

from services.api.app.core.auth import UserPrincipal, get_current_user
from services.api.app.core.db import get_session
from services.api.app.core.idempotency import execute_idempotent, require_idempotency_key
from services.api.app.core.rate_limit import chat_rate_limiter
from services.api.app.modules.chat.schemas import (
    ChatMessageResponse,
    ChatSessionResponse,
    CreateChatSessionRequest,
    SendChatMessageRequest,
)
from services.api.app.modules.chat.service import create_session, send_message

router = APIRouter(prefix="/v1/chat", tags=["chat"])


@router.post("/sessions", response_model=ChatSessionResponse, status_code=201)
def create_chat_session(
    request: CreateChatSessionRequest,
    idempotency_key: Annotated[str | None, Header(alias="Idempotency-Key")] = None,
    user: UserPrincipal = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> Response:
    key = require_idempotency_key(idempotency_key)

    def action() -> tuple[int, dict]:
        chat_session = create_session(session, user.user_id, request)
        body = ChatSessionResponse.model_validate(chat_session).model_dump(mode="json")
        return 201, body

    status_code, body = execute_idempotent(
        session,
        user_id=user.user_id,
        key=key,
        operation="create_chat_session",
        payload=request.model_dump(mode="json"),
        action=action,
    )
    return Response(content=ChatSessionResponse.model_validate(body).model_dump_json(), status_code=status_code, media_type="application/json")


@router.post("/sessions/{session_id}/messages", response_model=ChatMessageResponse, status_code=202)
def send_chat_message(
    session_id: str,
    request: SendChatMessageRequest,
    idempotency_key: Annotated[str | None, Header(alias="Idempotency-Key")] = None,
    user: UserPrincipal = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> Response:
    key = require_idempotency_key(idempotency_key)
    chat_rate_limiter.enforce(user.user_id)

    def action() -> tuple[int, dict]:
        message, citations = send_message(session, user.user_id, session_id, request)
        body = ChatMessageResponse(
            message_id=message.id,
            status=message.status,
            role="assistant",
            answer=message.content,
            safety_level=message.safety_level,
            needs_expert=message.needs_expert,
            citations=[
                {"article_id": citation.article_id, "section": citation.section, "relevance_score": citation.relevance_score}
                for citation in citations
            ],
            created_at=message.created_at,
        ).model_dump(mode="json")
        return 202, body

    status_code, body = execute_idempotent(
        session,
        user_id=user.user_id,
        key=key,
        operation=f"send_chat_message:{session_id}",
        payload=request.model_dump(mode="json"),
        action=action,
    )
    return Response(content=ChatMessageResponse.model_validate(body).model_dump_json(), status_code=status_code, media_type="application/json")
