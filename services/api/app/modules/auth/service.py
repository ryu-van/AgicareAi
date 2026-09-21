from datetime import datetime, timedelta, timezone
import hashlib
import secrets
from uuid import UUID, uuid4

import jwt
from sqlalchemy import select
from sqlalchemy.orm import Session

from services.api.app.core.config import get_settings
from services.api.app.core.errors import AppError
from services.api.app.db.models import Profile, Role, UserCredential, UserRole
from services.api.app.modules.auth.schemas import (
    AuthUserResponse,
    RegisterRequest,
    TokenResponse,
)

PBKDF2_ITERATIONS = 100_000


def hash_password(plain_password: str) -> str:
    salt = secrets.token_hex(16)
    hash_bytes = hashlib.pbkdf2_hmac(
        "sha256",
        plain_password.encode("utf-8"),
        salt.encode("utf-8"),
        PBKDF2_ITERATIONS,
    )
    return f"pbkdf2_sha256${PBKDF2_ITERATIONS}${salt}${hash_bytes.hex()}"


def verify_password(plain_password: str, hashed_password: str) -> bool:
    try:
        parts = hashed_password.split("$")
        if len(parts) != 4:
            return False
        algo, iters_str, salt, stored_hash = parts
        if algo != "pbkdf2_sha256":
            return False
        iters = int(iters_str)
        hash_bytes = hashlib.pbkdf2_hmac(
            "sha256",
            plain_password.encode("utf-8"),
            salt.encode("utf-8"),
            iters,
        )
        return secrets.compare_digest(hash_bytes.hex(), stored_hash)
    except Exception:
        return False


def create_access_token(user_id: str) -> tuple[str, int]:
    settings = get_settings()
    now = datetime.now(timezone.utc)
    expires_in_seconds = settings.access_token_expire_minutes * 60
    exp = now + timedelta(seconds=expires_in_seconds)
    payload = {
        "sub": user_id,
        "iat": int(now.timestamp()),
        "exp": int(exp.timestamp()),
        "type": "access",
    }
    token = jwt.encode(payload, settings.jwt_secret_key.get_secret_value(), algorithm=settings.jwt_algorithm)
    return token, expires_in_seconds


def create_refresh_token(user_id: str) -> str:
    settings = get_settings()
    now = datetime.now(timezone.utc)
    exp = now + timedelta(days=settings.refresh_token_expire_days)
    payload = {
        "sub": user_id,
        "iat": int(now.timestamp()),
        "exp": int(exp.timestamp()),
        "type": "refresh",
    }
    return jwt.encode(payload, settings.jwt_secret_key.get_secret_value(), algorithm=settings.jwt_algorithm)


def register_user(session: Session, data: RegisterRequest) -> TokenResponse:
    identifier = data.identifier.strip()
    existing = session.scalar(
        select(UserCredential).where(UserCredential.identifier == identifier)
    )
    if existing is not None:
        raise AppError(409, "CONFLICT", "Số điện thoại hoặc tài khoản này đã được đăng ký.")

    user_id = str(uuid4())
    display_name = data.display_name.strip() if data.display_name else None
    phone = data.phone.strip() if data.phone else (identifier if identifier.replace("+", "").isdigit() else None)

    profile = Profile(id=user_id, display_name=display_name, phone=phone)
    session.add(profile)

    if session.get(Role, "user") is None:
        session.add(Role(id="user", label="User", description="Default user role"))
        session.flush()

    session.add(UserRole(user_id=user_id, role_id="user"))

    credential = UserCredential(
        user_id=user_id,
        identifier=identifier,
        password_hash=hash_password(data.password),
    )
    session.add(credential)
    session.commit()

    access_token, expires_in = create_access_token(user_id)
    refresh_token = create_refresh_token(user_id)

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="bearer",
        expires_in=expires_in,
        user_id=user_id,
        display_name=display_name,
    )


def authenticate_user(session: Session, identifier: str, password: str) -> TokenResponse:
    ident = identifier.strip()
    credential = session.scalar(
        select(UserCredential).where(UserCredential.identifier == ident)
    )
    if credential is None or not verify_password(password, credential.password_hash):
        raise AppError(401, "UNAUTHENTICATED", "Số điện thoại/tài khoản hoặc mật khẩu không chính xác.")

    profile = session.get(Profile, credential.user_id)
    display_name = profile.display_name if profile else None

    access_token, expires_in = create_access_token(credential.user_id)
    refresh_token = create_refresh_token(credential.user_id)

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="bearer",
        expires_in=expires_in,
        user_id=credential.user_id,
        display_name=display_name,
    )


def refresh_access_token(session: Session, refresh_token: str) -> TokenResponse:
    settings = get_settings()
    try:
        payload = jwt.decode(
            refresh_token,
            settings.jwt_secret_key.get_secret_value(),
            algorithms=[settings.jwt_algorithm],
        )
    except jwt.ExpiredSignatureError as exc:
        raise AppError(401, "UNAUTHENTICATED", "Phiên đăng nhập đã hết hạn.") from exc
    except jwt.PyJWTError as exc:
        raise AppError(401, "UNAUTHENTICATED", "Thông tin xác thực không hợp lệ.") from exc

    if payload.get("type") != "refresh":
        raise AppError(401, "UNAUTHENTICATED", "Thông tin xác thực không hợp lệ.")

    user_id = payload.get("sub")
    if not user_id:
        raise AppError(401, "UNAUTHENTICATED", "Thông tin xác thực không hợp lệ.")

    try:
        UUID(user_id)
    except ValueError as exc:
        raise AppError(401, "UNAUTHENTICATED", "Thông tin xác thực không hợp lệ.") from exc

    profile = session.get(Profile, user_id)
    if profile is None:
        raise AppError(401, "UNAUTHENTICATED", "Thông tin xác thực không hợp lệ.")

    access_token, expires_in = create_access_token(user_id)
    new_refresh_token = create_refresh_token(user_id)

    return TokenResponse(
        access_token=access_token,
        refresh_token=new_refresh_token,
        token_type="bearer",
        expires_in=expires_in,
        user_id=user_id,
        display_name=profile.display_name,
    )


def get_auth_user_me(session: Session, user_id: str) -> AuthUserResponse:
    profile = session.get(Profile, user_id)
    if profile is None:
        raise AppError(404, "NOT_FOUND", "Không tìm thấy thông tin người dùng.")

    user_roles = session.scalars(
        select(UserRole.role_id).where(UserRole.user_id == user_id)
    ).all()

    return AuthUserResponse(
        id=profile.id,
        display_name=profile.display_name,
        phone=profile.phone,
        roles=list(user_roles),
        created_at=profile.created_at.isoformat(),
    )
