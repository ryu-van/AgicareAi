from uuid import uuid4

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.exceptions import RequestValidationError

from services.api.app.core.errors import AppError, app_error_handler, unexpected_error_handler, validation_error_handler
from services.api.app.modules.chat.router import router as chat_router
from services.api.app.modules.domains.router import router as domains_router
from services.api.app.modules.identity.router import router as identity_router
from services.api.app.modules.knowledge.router import router as knowledge_router
from services.api.app.modules.journal.router import router as journal_router
from services.api.app.modules.sync.router import router as sync_router


def create_app() -> FastAPI:
    app = FastAPI(title="AgriCare AI API", version="0.1.0")
    app.add_middleware(
        CORSMiddleware,
        allow_origins=[
            "http://localhost:8081",
            "http://127.0.0.1:8081",
            "http://192.168.8.140:8081",
        ],
        allow_credentials=False,
        allow_methods=["GET", "PATCH", "POST", "OPTIONS"],
        allow_headers=["Authorization", "Content-Type", "Accept", "Idempotency-Key", "X-Request-Id"],
    )
    app.add_exception_handler(AppError, app_error_handler)
    app.add_exception_handler(RequestValidationError, validation_error_handler)
    app.add_exception_handler(Exception, unexpected_error_handler)

    @app.middleware("http")
    async def attach_request_id(request: Request, call_next):
        request.state.request_id = request.headers.get("X-Request-Id") or f"req_{uuid4().hex}"
        response = await call_next(request)
        response.headers["X-Request-Id"] = request.state.request_id
        return response

    @app.get("/health", tags=["system"])
    def health() -> dict[str, str]:
        return {"status": "ok", "environment": "local"}

    @app.get("/ready", tags=["system"])
    def readiness() -> dict[str, str]:
        return {"status": "ok", "environment": "local"}

    app.include_router(domains_router)
    app.include_router(identity_router)
    app.include_router(knowledge_router)
    app.include_router(chat_router)
    app.include_router(journal_router)
    app.include_router(sync_router)
    return app


app = create_app()
