from uuid import uuid4

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.exceptions import RequestValidationError

from services.api.app.core.errors import AppError, app_error_handler, unexpected_error_handler, validation_error_handler
from services.api.app.modules.registry import api_routers


def create_app() -> FastAPI:
    app = FastAPI(title="AgriCare AI API", version="0.1.0")
    app.add_middleware(
        CORSMiddleware,
        allow_origin_regex=r"^https?://.*",
        allow_credentials=False,
        allow_methods=["*"],
        allow_headers=["*"],
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

    for router in api_routers():
        app.include_router(router)
    return app


app = create_app()
