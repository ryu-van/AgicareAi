from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from services.api.app.core.auth import UserPrincipal, get_current_user
from services.api.app.core.db import get_session
from services.api.app.modules.auth.schemas import (
    AuthUserResponse,
    LoginRequest,
    RefreshTokenRequest,
    RegisterRequest,
    TokenResponse,
)
from services.api.app.modules.auth.service import (
    authenticate_user,
    get_auth_user_me,
    refresh_access_token,
    register_user,
)

router = APIRouter(prefix="/v1/auth", tags=["auth"])


@router.post("/register", response_model=TokenResponse, status_code=201)
def register(
    request: RegisterRequest,
    session: Session = Depends(get_session),
) -> TokenResponse:
    return register_user(session, request)


@router.post("/login", response_model=TokenResponse, status_code=200)
def login(
    request: LoginRequest,
    session: Session = Depends(get_session),
) -> TokenResponse:
    return authenticate_user(session, request.identifier, request.password)


@router.post("/refresh", response_model=TokenResponse, status_code=200)
def refresh(
    request: RefreshTokenRequest,
    session: Session = Depends(get_session),
) -> TokenResponse:
    return refresh_access_token(session, request.refresh_token)


@router.get("/me", response_model=AuthUserResponse, status_code=200)
def read_current_auth_user(
    user: UserPrincipal = Depends(get_current_user),
    session: Session = Depends(get_session),
) -> AuthUserResponse:
    return get_auth_user_me(session, user.user_id)
