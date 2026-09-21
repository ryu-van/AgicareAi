from datetime import datetime, timedelta, timezone
from uuid import uuid4

import jwt
import pytest
from fastapi.testclient import TestClient

from services.api.app.core.config import get_settings
from services.api.app.core.db import configure_database, create_all_tables, dispose_database, session_scope
from services.api.app.db.models import Profile, Role, UserCredential
from services.api.app.main import create_app
from services.api.app.modules.auth.service import verify_password


@pytest.fixture()
def auth_client(tmp_path):
    database_url = f"sqlite+pysqlite:///{tmp_path / 'auth-test.db'}"
    configure_database(database_url)
    create_all_tables()

    with session_scope() as session:
        if session.get(Role, "user") is None:
            session.add(Role(id="user", label="User", description="Default role"))
            session.commit()

    app = create_app()
    with TestClient(app) as test_client:
        yield test_client, app
    dispose_database()


def test_register_success(auth_client):
    client, _ = auth_client

    payload = {
        "identifier": "0987654321",
        "password": "Password123!",
        "display_name": "Nông dân Ba Tri",
        "phone": "0987654321",
    }
    response = client.post("/v1/auth/register", json=payload)

    assert response.status_code == 201
    data = response.json()
    assert data["access_token"]
    assert data["refresh_token"]
    assert data["token_type"] == "bearer"
    assert data["expires_in"] == 3600
    assert data["user_id"]
    assert data["display_name"] == "Nông dân Ba Tri"

    # Verify credentials stored safely in DB with PBKDF2 hash
    with session_scope() as session:
        cred = session.get(UserCredential, data["user_id"])
        assert cred is not None
        assert cred.identifier == "0987654321"
        assert cred.password_hash.startswith("pbkdf2_sha256$100000$")
        assert verify_password("Password123!", cred.password_hash)


def test_register_duplicate_identifier(auth_client):
    client, _ = auth_client

    payload = {
        "identifier": "farmer@example.com",
        "password": "SecurePassword123!",
        "display_name": "Farmer Joe",
    }
    res1 = client.post("/v1/auth/register", json=payload)
    assert res1.status_code == 201

    res2 = client.post("/v1/auth/register", json=payload)
    assert res2.status_code == 409
    err = res2.json()["error"]
    assert err["code"] == "CONFLICT"
    assert "đã được đăng ký" in err["message"]


def test_register_validation(auth_client):
    client, _ = auth_client

    # Password too short (< 6)
    res_pw = client.post("/v1/auth/register", json={"identifier": "testuser", "password": "123"})
    assert res_pw.status_code == 422

    # Identifier too short (< 3)
    res_id = client.post("/v1/auth/register", json={"identifier": "ab", "password": "securepassword"})
    assert res_id.status_code == 422


def test_login_success(auth_client):
    client, _ = auth_client

    # Register first
    client.post(
        "/v1/auth/register",
        json={
            "identifier": "0912345678",
            "password": "MySecretPassword123",
            "display_name": "Tran Van B",
        },
    )

    # Login
    response = client.post(
        "/v1/auth/login",
        json={"identifier": "0912345678", "password": "MySecretPassword123"},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["access_token"]
    assert data["refresh_token"]
    assert data["token_type"] == "bearer"
    assert data["display_name"] == "Tran Van B"


def test_login_wrong_password(auth_client):
    client, _ = auth_client

    client.post(
        "/v1/auth/register",
        json={"identifier": "0912345678", "password": "CorrectPassword123"},
    )

    response = client.post(
        "/v1/auth/login",
        json={"identifier": "0912345678", "password": "WrongPassword456"},
    )
    assert response.status_code == 401
    err = response.json()["error"]
    assert err["code"] == "UNAUTHENTICATED"


def test_login_user_not_found(auth_client):
    client, _ = auth_client

    response = client.post(
        "/v1/auth/login",
        json={"identifier": "nonexistent@example.com", "password": "anyPassword123"},
    )
    assert response.status_code == 401
    err = response.json()["error"]
    assert err["code"] == "UNAUTHENTICATED"


def test_refresh_token_success(auth_client):
    client, _ = auth_client

    reg_res = client.post(
        "/v1/auth/register",
        json={"identifier": "refresher@example.com", "password": "SecretPassword123"},
    )
    assert reg_res.status_code == 201
    refresh_token = reg_res.json()["refresh_token"]

    refresh_res = client.post("/v1/auth/refresh", json={"refresh_token": refresh_token})
    assert refresh_res.status_code == 200
    data = refresh_res.json()
    assert data["access_token"]
    assert data["refresh_token"]
    assert data["token_type"] == "bearer"
    assert data["user_id"] == reg_res.json()["user_id"]


def test_refresh_token_invalid_or_wrong_type(auth_client):
    client, _ = auth_client

    reg_res = client.post(
        "/v1/auth/register",
        json={"identifier": "refresher2@example.com", "password": "SecretPassword123"},
    )
    access_token = reg_res.json()["access_token"]

    # Passing access token to refresh endpoint should fail (wrong type)
    res1 = client.post("/v1/auth/refresh", json={"refresh_token": access_token})
    assert res1.status_code == 401

    # Passing malformed token
    res2 = client.post("/v1/auth/refresh", json={"refresh_token": "not.a.valid.jwt"})
    assert res2.status_code == 401


def test_refresh_token_expired(auth_client):
    client, _ = auth_client
    settings = get_settings()

    user_id = str(uuid4())
    # Create profile so user exists
    with session_scope() as session:
        session.add(Profile(id=user_id, display_name="Expired User"))
        session.commit()

    # Create expired refresh token
    past = datetime.now(timezone.utc) - timedelta(days=1)
    payload = {
        "sub": user_id,
        "iat": int((past - timedelta(days=30)).timestamp()),
        "exp": int(past.timestamp()),
        "type": "refresh",
    }
    expired_token = jwt.encode(payload, settings.jwt_secret_key.get_secret_value(), algorithm=settings.jwt_algorithm)

    response = client.post("/v1/auth/refresh", json={"refresh_token": expired_token})
    assert response.status_code == 401
    assert response.json()["error"]["message"] == "Phiên đăng nhập đã hết hạn."


def test_access_me_and_auth_me_with_real_jwt(auth_client):
    client, _ = auth_client

    reg_res = client.post(
        "/v1/auth/register",
        json={
            "identifier": "realjwt@example.com",
            "password": "Password123456",
            "display_name": "Real JWT User",
            "phone": "0911223344",
        },
    )
    access_token = reg_res.json()["access_token"]
    user_id = reg_res.json()["user_id"]

    headers = {"Authorization": f"Bearer {access_token}"}

    # Access /v1/auth/me
    auth_me_res = client.get("/v1/auth/me", headers=headers)
    assert auth_me_res.status_code == 200
    me_data = auth_me_res.json()
    assert me_data["id"] == user_id
    assert me_data["display_name"] == "Real JWT User"
    assert me_data["phone"] == "0911223344"
    assert "user" in me_data["roles"]
    assert me_data["created_at"]

    # Access /v1/me (Profile API)
    me_res = client.get("/v1/me", headers=headers)
    assert me_res.status_code == 200
    assert me_res.json()["id"] == user_id
    assert me_res.json()["display_name"] == "Real JWT User"


def test_expired_access_token_raises_401(auth_client):
    client, _ = auth_client
    settings = get_settings()

    user_id = str(uuid4())
    with session_scope() as session:
        session.add(Profile(id=user_id, display_name="Test Expired"))
        session.commit()

    past = datetime.now(timezone.utc) - timedelta(minutes=5)
    payload = {
        "sub": user_id,
        "iat": int((past - timedelta(hours=1)).timestamp()),
        "exp": int(past.timestamp()),
        "type": "access",
    }
    expired_token = jwt.encode(payload, settings.jwt_secret_key.get_secret_value(), algorithm=settings.jwt_algorithm)

    response = client.get("/v1/auth/me", headers={"Authorization": f"Bearer {expired_token}"})
    assert response.status_code == 401
    assert response.json()["error"]["message"] == "Phiên đăng nhập đã hết hạn."


def test_dev_token_compatibility(auth_client, monkeypatch):
    client, _ = auth_client
    dev_user_id = str(uuid4())

    # When dev auth is disabled
    monkeypatch.setenv("DEV_AUTH_ENABLED", "false")
    get_settings.cache_clear()

    res_disabled = client.get("/v1/me", headers={"Authorization": f"Bearer dev:{dev_user_id}"})
    assert res_disabled.status_code == 401
    assert res_disabled.json()["error"]["code"] == "UNAUTHENTICATED"

    # When dev auth is enabled
    monkeypatch.setenv("DEV_AUTH_ENABLED", "true")
    get_settings.cache_clear()

    res_enabled = client.get("/v1/me", headers={"Authorization": f"Bearer dev:{dev_user_id}"})
    assert res_enabled.status_code == 200
    assert res_enabled.json()["id"] == dev_user_id

    get_settings.cache_clear()

