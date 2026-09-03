from typing import Annotated

from fastapi import APIRouter, Depends, Header, Response
from sqlalchemy.orm import Session

from services.api.app.core.auth import UserPrincipal, get_current_user
from services.api.app.core.db import get_session
from services.api.app.core.idempotency import execute_idempotent, require_idempotency_key
from services.api.app.modules.identity.schemas import (
    ConsentResponse,
    CreateConsentRequest,
    ProfileResponse,
    UpdateProfileRequest,
)
from services.api.app.modules.identity.service import create_consent, get_profile, update_profile

router = APIRouter(prefix="/v1/me", tags=["identity"])


@router.get("", response_model=ProfileResponse)
def read_profile(
    user: UserPrincipal = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> ProfileResponse:
    return ProfileResponse.model_validate(get_profile(session, user.user_id))


@router.patch("", response_model=ProfileResponse)
def patch_profile(
    request: UpdateProfileRequest,
    user: UserPrincipal = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> ProfileResponse:
    return ProfileResponse.model_validate(update_profile(session, user.user_id, request))


@router.post("/consents", response_model=ConsentResponse, status_code=201)
def record_consent(
    request: CreateConsentRequest,
    idempotency_key: Annotated[str | None, Header(alias="Idempotency-Key")] = None,
    user: UserPrincipal = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> Response:
    key = require_idempotency_key(idempotency_key)

    def action() -> tuple[int, dict]:
        consent = create_consent(session, user.user_id, request)
        return 201, ConsentResponse.model_validate(consent).model_dump(mode="json")

    status_code, body = execute_idempotent(
        session,
        user_id=user.user_id,
        key=key,
        operation="create_consent",
        payload=request.model_dump(mode="json"),
        action=action,
    )
    return Response(content=ConsentResponse.model_validate(body).model_dump_json(), status_code=status_code, media_type="application/json")
