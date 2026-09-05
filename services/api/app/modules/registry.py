"""Single composition point for feature routers.

Feature modules expose their own router. The application shell depends on this
registry instead of individual modules, keeping module registration explicit
and making future extraction or feature flags localized to this file.
"""

from fastapi import APIRouter

from services.api.app.modules.chat.router import router as chat_router
from services.api.app.modules.diagnosis.router import router as diagnosis_router
from services.api.app.modules.domains.router import router as domains_router
from services.api.app.modules.farm.router import router as farm_router
from services.api.app.modules.identity.router import router as identity_router
from services.api.app.modules.journal.router import router as journal_router
from services.api.app.modules.knowledge.router import router as knowledge_router
from services.api.app.modules.reminders.router import router as reminders_router
from services.api.app.modules.sync.router import router as sync_router


def api_routers() -> tuple[APIRouter, ...]:
    """Return the stable set of HTTP feature routers in API order."""
    return (
        domains_router,
        identity_router,
        farm_router,
        knowledge_router,
        chat_router,
        diagnosis_router,
        journal_router,
        reminders_router,
        sync_router,
    )

