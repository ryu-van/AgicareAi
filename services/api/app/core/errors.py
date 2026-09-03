import logging
from typing import Any

from fastapi import Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse

logger = logging.getLogger(__name__)


class AppError(Exception):
    def __init__(
        self,
        status_code: int,
        code: str,
        message: str,
        fields: list[dict[str, Any]] | None = None,
        headers: dict[str, str] | None = None,
    ):
        self.status_code = status_code
        self.code = code
        self.message = message
        self.fields = fields
        self.headers = headers


def error_body(request: Request, code: str, message: str, fields: list[dict[str, Any]] | None = None) -> dict[str, Any]:
    error: dict[str, Any] = {
        "code": code,
        "message": message,
        "request_id": getattr(request.state, "request_id", "unknown"),
    }
    if fields:
        error["fields"] = fields
    return {"error": error}


async def app_error_handler(request: Request, exc: AppError) -> JSONResponse:
    return JSONResponse(
        status_code=exc.status_code,
        content=error_body(request, exc.code, exc.message, exc.fields),
        headers=exc.headers,
    )


async def validation_error_handler(request: Request, exc: RequestValidationError) -> JSONResponse:
    fields = [
        {"field": ".".join(str(item) for item in error["loc"] if item != "body"), "reason": error["msg"]}
        for error in exc.errors()
    ]
    return JSONResponse(
        status_code=422,
        content=error_body(request, "VALIDATION_ERROR", "Dữ liệu không hợp lệ.", fields),
    )


async def unexpected_error_handler(request: Request, exc: Exception) -> JSONResponse:
    logger.exception("Unhandled API error; request_id=%s", getattr(request.state, "request_id", "unknown"))
    return JSONResponse(
        status_code=500,
        content=error_body(request, "INTERNAL_ERROR", "Đã xảy ra lỗi hệ thống."),
    )
