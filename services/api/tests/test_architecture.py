from services.api.app.main import create_app
from services.api.app.modules.registry import api_routers


def test_application_composes_all_feature_routers_from_the_registry():
    registered_paths = {
        route.path
        for route in create_app().routes
        if getattr(route, "path", "").startswith("/v1")
    }

    assert len(api_routers()) == 9
    assert {
        "/v1/domains",
        "/v1/me",
        "/v1/farm/summary",
        "/v1/knowledge/articles",
        "/v1/chat/sessions",
        "/v1/diagnosis/analyze",
        "/v1/journal/entries",
        "/v1/reminders",
        "/v1/sync/batch",
    }.issubset(registered_paths)

