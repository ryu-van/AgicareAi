from datetime import datetime, timezone
from uuid import uuid4

import pytest
from fastapi.testclient import TestClient

from services.api.app.core.auth import UserPrincipal, get_current_user
from services.api.app.core.config import get_settings
from services.api.app.core.db import configure_database, create_all_tables, dispose_database, session_scope
from services.api.app.db.models import Domain, KnowledgeArticle, Subject
from services.api.app.main import create_app


@pytest.fixture()
def client(tmp_path):
    database_url = f"sqlite+pysqlite:///{tmp_path / 'api-test.db'}"
    configure_database(database_url)
    create_all_tables()

    with session_scope() as session:
        session.add_all(
            [
                Domain(id="plant", label="Trồng trọt", sort_order=1),
                Domain(id="animal", label="Chăn nuôi", sort_order=2),
                Subject(id="chicken", domain="animal", name="Gà", status="published"),
                KnowledgeArticle(
                    id="10000000-0000-4000-8000-000000000001",
                    domain="animal",
                    subject_id="chicken",
                    title="Theo dõi đàn gà bỏ ăn",
                    summary="Fixture tổng hợp cho kiểm thử.",
                    content="Ghi nhận số con bỏ ăn và lượng nước uống.",
                    topic="observation",
                    source_name="AgriGuard synthetic fixture",
                    status="published",
                ),
            ]
        )
        session.commit()

    app = create_app()
    test_user = UserPrincipal(user_id=str(uuid4()))
    app.dependency_overrides[get_current_user] = lambda: test_user
    with TestClient(app) as test_client:
        yield test_client, app, test_user
    dispose_database()


def test_health_includes_request_id(client):
    test_client, _, _ = client

    response = test_client.get("/health")

    assert response.status_code == 200
    assert response.json()["status"] == "ok"
    assert response.headers["X-Request-Id"]


def test_cors_allows_configured_lan_origin(client):
    test_client, _, _ = client

    response = test_client.options(
        "/health",
        headers={
            "Origin": "http://192.168.8.140:8081",
            "Access-Control-Request-Method": "GET",
        },
    )

    assert response.status_code == 200
    assert response.headers["access-control-allow-origin"] == "http://192.168.8.140:8081"


def test_dev_identity_auto_provisions_profile_and_consent(client, monkeypatch):
    test_client, app, test_user = client
    monkeypatch.setenv("DEV_AUTH_ENABLED", "true")
    get_settings.cache_clear()
    app.dependency_overrides.pop(get_current_user, None)

    headers = {"Authorization": f"Bearer dev:{test_user.user_id}"}
    profile = test_client.get("/v1/me", headers=headers)
    updated = test_client.patch("/v1/me", headers=headers, json={"display_name": "Nông hộ demo", "active_domain": "animal"})
    consent = test_client.post(
        "/v1/me/consents",
        headers={**headers, "Idempotency-Key": "consent-key-000001"},
        json={"consent_type": "ai_disclaimer", "version": "v1"},
    )

    assert profile.status_code == 200
    assert profile.json()["id"] == test_user.user_id
    assert "active_domain" not in profile.json()
    assert updated.status_code == 200
    assert updated.json()["display_name"] == "Nông hộ demo"
    assert consent.status_code == 201
    assert consent.json()["version"] == "v1"
    get_settings.cache_clear()


def test_protected_route_rejects_missing_token_without_override():
    app = create_app()
    with TestClient(app) as test_client:
        response = test_client.post(
            "/v1/chat/sessions",
            headers={"Idempotency-Key": "a" * 16},
            json={"domain": "animal"},
        )

    assert response.status_code == 401
    assert response.json()["error"]["code"] == "UNAUTHENTICATED"


def test_domains_and_chat_are_validated_and_idempotent(client):
    test_client, _, _ = client
    key = "chat-session-key-0001"

    domains = test_client.get("/v1/domains")
    assert domains.status_code == 200
    assert [item["id"] for item in domains.json()] == ["plant", "animal"]

    invalid = test_client.post(
        "/v1/chat/sessions",
        headers={"Idempotency-Key": key},
        json={"domain": "plant", "subject_id": "chicken"},
    )
    assert invalid.status_code == 422
    assert invalid.json()["error"]["code"] == "VALIDATION_ERROR"

    created = test_client.post(
        "/v1/chat/sessions",
        headers={"Idempotency-Key": key},
        json={"domain": "animal", "subject_id": "chicken", "title": "Gà bỏ ăn"},
    )
    repeated = test_client.post(
        "/v1/chat/sessions",
        headers={"Idempotency-Key": key},
        json={"domain": "animal", "subject_id": "chicken", "title": "Gà bỏ ăn"},
    )

    assert created.status_code == 201
    assert repeated.status_code == 201
    assert repeated.json() == created.json()


def test_knowledge_filters_published_articles(client):
    test_client, _, _ = client

    subjects = test_client.get("/v1/subjects", params={"domain": "animal"})
    all_articles = test_client.get("/v1/knowledge/articles")
    articles = test_client.get("/v1/knowledge/articles", params={"q": "gà bỏ ăn", "domain": "animal"})
    detail = test_client.get("/v1/knowledge/articles/10000000-0000-4000-8000-000000000001")

    assert subjects.status_code == 200
    assert subjects.json()[0]["id"] == "chicken"
    assert all_articles.status_code == 200
    assert all_articles.json()["items"][0]["domain"] == "animal"
    assert articles.status_code == 200
    assert articles.json()["items"][0]["source_name"] == "AgriGuard synthetic fixture"
    assert detail.status_code == 200
    assert detail.json()["status"] == "published"


def test_chat_message_returns_safe_no_source_response(client):
    test_client, _, _ = client
    session_response = test_client.post(
        "/v1/chat/sessions",
        headers={"Idempotency-Key": "session-key-000001"},
        json={"domain": "animal", "subject_id": "chicken"},
    )

    response = test_client.post(
        f"/v1/chat/sessions/{session_response.json()['id']}/messages",
        headers={"Idempotency-Key": "message-key-000001"},
        json={"content": "Gà bỏ ăn hai ngày, tôi nên kiểm tra gì?"},
    )

    assert response.status_code == 202
    body = response.json()
    assert body["status"] == "completed"
    assert body["citations"] == []
    assert body["needs_expert"] is True
    assert "chưa có nguồn" in body["answer"].lower()


def test_user_cannot_send_message_to_another_users_session(client):
    test_client, app, _ = client
    session_response = test_client.post(
        "/v1/chat/sessions",
        headers={"Idempotency-Key": "owner-session-key1"},
        json={"domain": "animal", "subject_id": "chicken"},
    )
    app.dependency_overrides[get_current_user] = lambda: UserPrincipal(user_id=str(uuid4()))

    response = test_client.post(
        f"/v1/chat/sessions/{session_response.json()['id']}/messages",
        headers={"Idempotency-Key": "other-user-msg-key"},
        json={"content": "Tôi muốn xem cuộc trò chuyện này"},
    )

    assert response.status_code == 404
    assert response.json()["error"]["code"] == "NOT_FOUND"


def test_reused_idempotency_key_with_changed_payload_conflicts(client):
    test_client, _, _ = client
    key = "reused-key-payload"
    first = test_client.post(
        "/v1/chat/sessions",
        headers={"Idempotency-Key": key},
        json={"domain": "animal", "subject_id": "chicken"},
    )
    changed = test_client.post(
        "/v1/chat/sessions",
        headers={"Idempotency-Key": key},
        json={"domain": "animal", "title": "Khác"},
    )

    assert first.status_code == 201
    assert changed.status_code == 409
    assert changed.json()["error"]["code"] == "CONFLICT"


def test_chat_rate_limit_returns_retry_after(client):
    test_client, _, _ = client
    session_response = test_client.post(
        "/v1/chat/sessions",
        headers={"Idempotency-Key": "rate-session-key01"},
        json={"domain": "animal", "subject_id": "chicken"},
    )
    session_id = session_response.json()["id"]

    for index in range(20):
        response = test_client.post(
            f"/v1/chat/sessions/{session_id}/messages",
            headers={"Idempotency-Key": f"rate-message-{index:05d}"},
            json={"content": "Câu hỏi kiểm thử"},
        )
        assert response.status_code == 202

    limited = test_client.post(
        f"/v1/chat/sessions/{session_id}/messages",
        headers={"Idempotency-Key": "rate-message-00020"},
        json={"content": "Câu hỏi kiểm thử"},
    )
    assert limited.status_code == 429
    assert limited.headers["Retry-After"]
    assert limited.json()["error"]["code"] == "RATE_LIMITED"


def test_journal_idempotency_and_sync_conflict(client):
    test_client, _, _ = client
    journal_body = {
        "subject_id": "chicken",
        "entry_type": "observation",
        "observed_at": datetime.now(timezone.utc).isoformat(),
        "timezone": "Asia/Ho_Chi_Minh",
        "title": "Gà bỏ ăn",
        "client_event_id": "journal-client-event-1",
    }
    first = test_client.post(
        "/v1/journal/entries",
        headers={"Idempotency-Key": "journal-key-000001"},
        json=journal_body,
    )
    repeated = test_client.post(
        "/v1/journal/entries",
        headers={"Idempotency-Key": "journal-key-000001"},
        json=journal_body,
    )
    assert first.status_code == repeated.status_code == 201
    assert first.json() == repeated.json()

    event = {"event_id": "sync-event-1", "entity": "journal_entry", "operation": "upsert", "payload": {"title": "A"}}
    applied = test_client.post(
        "/v1/sync/batch",
        headers={"Idempotency-Key": "sync-key-00000001"},
        json={"events": [event]},
    )
    conflicting = test_client.post(
        "/v1/sync/batch",
        headers={"Idempotency-Key": "sync-key-00000002"},
        json={"events": [{**event, "payload": {"title": "B"}}]},
    )

    assert applied.status_code == 200
    assert applied.json()["results"][0]["status"] == "applied"
    assert conflicting.status_code == 200
    assert conflicting.json()["results"][0]["status"] == "conflict"


def test_chat_message_returns_grounded_citation_for_matching_knowledge(client):
    test_client, _, _ = client
    session_response = test_client.post(
        "/v1/chat/sessions",
        headers={"Idempotency-Key": "grounded-session-key"},
        json={"domain": "animal", "subject_id": "chicken"},
    )
    response = test_client.post(
        f"/v1/chat/sessions/{session_response.json()['id']}/messages",
        headers={"Idempotency-Key": "grounded-message-key"},
        json={"content": "Fixture"},
    )

    assert response.status_code == 202
    body = response.json()
    assert len(body["citations"]) == 1
    assert body["citations"][0]["article_id"] == "10000000-0000-4000-8000-000000000001"
    assert "không phải chẩn đoán xác định" in body["answer"]


def test_farm_diagnosis_and_reminders_endpoints(client):
    test_client, _, _ = client

    farms = test_client.get("/v1/farm/summary")
    assert farms.status_code == 200
    assert len(farms.json()) >= 1
    assert farms.json()[0]["name"] == "Trang trại AgriCare Demo"

    diagnosis = test_client.post(
        "/v1/diagnosis/analyze",
        json={"symptoms": "Lá lúa có đốm nâu và héo vàng", "domain": "plant"},
    )
    assert diagnosis.status_code == 200
    assert "disease_name" in diagnosis.json()

    reminders = test_client.get("/v1/reminders")
    assert reminders.status_code == 200
    assert len(reminders.json()) >= 1

