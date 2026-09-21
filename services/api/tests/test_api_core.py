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

    # Test GET /v1/journal/entries
    list_response = test_client.get("/v1/journal/entries")
    assert list_response.status_code == 200
    assert list_response.json()["total"] >= 1
    assert any(item["title"] == "Gà bỏ ăn" for item in list_response.json()["items"])



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


def test_emergency_disease_pre_guardrail_blocks_treatment(client):
    test_client, _, _ = client
    session_response = test_client.post(
        "/v1/chat/sessions",
        headers={"Idempotency-Key": "asf-session-key-000001"},
        json={"domain": "animal", "subject_id": "chicken"},
    )
    assert session_response.status_code == 201
    session_id = session_response.json()["id"]

    response = test_client.post(
        f"/v1/chat/sessions/{session_id}/messages",
        headers={"Idempotency-Key": "asf-message-key-000001"},
        json={"content": "Đàn heo sốt cao xuất huyết, nghi nhiễm dịch tả lợn châu phi ASF thì dùng thuốc gì?"},
    )

    assert response.status_code == 202
    body = response.json()
    assert body["safety_level"] == "urgent"
    assert body["needs_expert"] is True
    assert "CẢNH BÁO NGUY CẤP" in body["answer"]
    assert "Dịch tả lợn Châu Phi" in body["answer"]
    assert "TUYỆT ĐỐI KHÔNG tự ý mua thuốc" in body["answer"]
    assert body["citations"] == []


def test_banned_substances_post_guardrail(client):
    test_client, _, _ = client
    from services.api.app.adapters.ai.provider import AIProviderAdapter

    class MockBannedAIProvider(AIProviderAdapter):
        def generate_completion(self, prompt, **kwargs):
            return "Bạn có thể phun thuốc diệt cỏ chứa paraquat để làm sạch bờ ruộng."

    from services.api.app.modules.chat import service as chat_svc

    original_provider = chat_svc._ai_provider
    chat_svc._ai_provider = MockBannedAIProvider()
    try:
        session_response = test_client.post(
            "/v1/chat/sessions",
            headers={"Idempotency-Key": "banned-session-key-001"},
            json={"domain": "animal", "subject_id": "chicken"},
        )
        session_id = session_response.json()["id"]

        response = test_client.post(
            f"/v1/chat/sessions/{session_id}/messages",
            headers={"Idempotency-Key": "banned-message-key-001"},
            json={"content": "Fixture"},
        )

        assert response.status_code == 202
        body = response.json()
        assert "HOẠT CHẤT ĐÃ BỊ CẤM LƯU HÀNH" in body["answer"]
        assert "paraquat" not in body["answer"].lower()

    finally:
        chat_svc._ai_provider = original_provider


def test_gemini_api_client_payload_headers_and_rag_grounding():
    import json
    import httpx
    from services.api.app.adapters.ai.provider import AIProviderAdapter

    captured_requests = []

    def mock_transport(request: httpx.Request) -> httpx.Response:
        captured_requests.append(request)
        body = json.loads(request.content.decode("utf-8"))
        assert "x-goog-api-key" in request.headers
        assert request.headers["x-goog-api-key"] == "test-api-key-12345"
        # Verify RAG context articles were injected into prompt
        user_content = body["contents"][0]["parts"][0]["text"]
        assert "TÀI LIỆU CẨM NANG NÔNG NGHIỆP THAM KHẢO" in user_content
        assert "Cách chăm sóc lúa" in user_content
        assert "Lúa bị đạo ôn thì làm gì?" in user_content

        response_data = {
            "candidates": [
                {
                    "content": {
                        "parts": [
                            {
                                "text": "Đánh giá sơ bộ: Lúa có dấu hiệu đạo ôn.\nBiện pháp: Giữ nước, bón phân cân đối.\nNguồn: Cẩm nang BVTV.\nĐây là thông tin tham khảo, không phải chẩn đoán xác định hay chỉ định thuốc."
                            }
                        ]
                    }
                }
            ]
        }
        return httpx.Response(200, json=response_data)

    mock_client = httpx.Client(transport=httpx.MockTransport(mock_transport))
    adapter = AIProviderAdapter(
        api_key="test-api-key-12345",
        client=mock_client,
    )

    result = adapter.generate_completion(
        prompt="Lúa bị đạo ôn thì làm gì?",
        system_instruction="Chỉ dựa vào cẩm nang.",
        context_articles=[
            {"title": "Cách chăm sóc lúa", "topic": "Kỹ thuật canh tác", "summary": "Ngưng bón đạm khi bị đạo ôn"}
        ],
    )

    assert len(captured_requests) == 1
    assert "Đánh giá sơ bộ: Lúa có dấu hiệu đạo ôn" in result
    adapter.close()


def test_gemini_api_client_error_fallback_to_grounded():
    import httpx
    from services.api.app.adapters.ai.provider import AIProviderAdapter

    def error_transport(request: httpx.Request) -> httpx.Response:
        return httpx.Response(500, json={"error": "Internal Server Error"})

    mock_client = httpx.Client(transport=httpx.MockTransport(error_transport))
    adapter = AIProviderAdapter(
        api_key="test-key-500",
        client=mock_client,
    )

    # Should fallback gracefully to grounded fallback
    result = adapter.generate_completion(
        prompt="Lúa vàng lá",
        context_articles=[
            {"title": "Cẩm nang lúa", "summary": "Bón phân đúng thời điểm"}
        ],
    )
    assert "Theo nguồn kiến thức nội bộ 'Cẩm nang lúa'" in result
    assert "không phải chẩn đoán xác định" in result
    adapter.close()


def test_pre_guardrail_does_not_false_alarm_on_substrings(client):
    test_client, _, _ = client
    session_response = test_client.post(
        "/v1/chat/sessions",
        headers={"Idempotency-Key": "asphalt-session-001"},
        json={"domain": "animal", "subject_id": "chicken"},
    )
    session_id = session_response.json()["id"]

    # "asphalt" contains "asf" as substring, but is NOT the disease acronym
    response = test_client.post(
        f"/v1/chat/sessions/{session_id}/messages",
        headers={"Idempotency-Key": "asphalt-msg-0000001"},
        json={"content": "Đường vào trang trại đổ nhựa asphalt thì có ảnh hưởng đàn gà không?"},
    )

    assert response.status_code == 202
    body = response.json()
    assert "CẢNH BÁO NGUY CẤP" not in body["answer"]
    assert "Dịch tả lợn Châu Phi" not in body["answer"]


def test_pre_guardrail_plant_emergency_disease(client):
    test_client, _, _ = client
    session_response = test_client.post(
        "/v1/chat/sessions",
        headers={"Idempotency-Key": "plant-emer-session-1"},
        json={"domain": "plant"},
    )
    assert session_response.status_code == 201
    session_id = session_response.json()["id"]


    response = test_client.post(
        f"/v1/chat/sessions/{session_id}/messages",
        headers={"Idempotency-Key": "plant-emer-msg-00001"},
        json={"content": "Ruộng sắn bị khảm lá sắn xoăn ngọn hàng loạt thì xử lý sao?"},
    )

    assert response.status_code == 202
    body = response.json()
    assert body["safety_level"] == "urgent"
    assert "CẢNH BÁO NGUY CẤP" in body["answer"]
    assert "Chi cục Trồng trọt & Bảo vệ Thực vật" in body["answer"]
    assert body["citations"] == []






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

