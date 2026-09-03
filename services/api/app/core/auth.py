from dataclasses import dataclass
from typing import Annotated
from uuid import UUID

from fastapi import Depends, Header
from sqlalchemy import text, select
from sqlalchemy.orm import Session

from services.api.app.core.config import get_settings
from services.api.app.core.db import get_session
from services.api.app.core.errors import AppError
from services.api.app.db.models import Profile, Role, UserRole


@dataclass(frozen=True)
class UserPrincipal:
    user_id: str


def _ensure_local_principal(session: Session, user_id: str) -> None:
    if session.bind is not None and session.bind.dialect.name == "postgresql":
        session.execute(
            text("insert into auth.users (id) values (:user_id) on conflict (id) do nothing"),
            {"user_id": user_id},
        )
    profile = session.get(Profile, user_id)
    if profile is None:
        profile = Profile(id=user_id, display_name="Local demo user")
        session.add(profile)
        session.flush()
    if session.get(Role, "user") is None:
        session.add(Role(id="user", label="User", description="Local demo role"))
        session.flush()
    has_user_role = session.scalar(
        select(UserRole).where(UserRole.user_id == user_id, UserRole.role_id == "user")
    )
    if has_user_role is None:
        session.add(UserRole(user_id=user_id, role_id="user"))
    session.commit()


def get_current_user(
    authorization: Annotated[str | None, Header()] = None,
    session: Session = Depends(get_session),
) -> UserPrincipal:
    if not authorization or not authorization.startswith("Bearer "):
        raise AppError(401, "UNAUTHENTICATED", "Thông tin xác thực không hợp lệ.")

    token = authorization.removeprefix("Bearer ").strip()
    settings = get_settings()
    if settings.app_env == "local" and settings.dev_auth_enabled and token.startswith("dev:"):
        user_id = token.removeprefix("dev:")
        try:
            UUID(user_id)
        except ValueError as exc:
            raise AppError(401, "UNAUTHENTICATED", "Thông tin xác thực không hợp lệ.") from exc
        _ensure_local_principal(session, user_id)
        return UserPrincipal(user_id=user_id)

    raise AppError(401, "UNAUTHENTICATED", "Thông tin xác thực không hợp lệ.")


def require_role(required_role: str):
    def dependency(
        user: UserPrincipal = Depends(get_current_user),
        session: Session = Depends(get_session),
    ) -> UserPrincipal:
        role = session.scalar(
            select(UserRole).where(UserRole.user_id == user.user_id, UserRole.role_id == required_role)
        )
        if role is None:
            raise AppError(403, "FORBIDDEN", "Bạn không có quyền thực hiện thao tác này.")
        return user

    return dependency
