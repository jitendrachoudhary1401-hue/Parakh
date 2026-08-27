"""
Project PARAKH — Custom Exceptions & Error Handlers

Standardized error handling per §39. Does not expose internal stack traces.
"""

from __future__ import annotations

from typing import Any, Optional

from fastapi import FastAPI, Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse


# --- Custom Exception Classes ---

class ParakhException(Exception):
    """Base exception for all PARAKH application errors."""

    def __init__(
        self,
        code: str,
        message: str,
        status_code: int = status.HTTP_500_INTERNAL_SERVER_ERROR,
        details: Optional[dict[str, Any]] = None,
    ):
        self.code = code
        self.message = message
        self.status_code = status_code
        self.details = details
        super().__init__(message)


class NotFoundError(ParakhException):
    """Resource not found."""

    def __init__(self, resource: str, identifier: str = ""):
        msg = f"{resource} not found"
        if identifier:
            msg = f"{resource} '{identifier}' not found"
        super().__init__(
            code="NOT_FOUND",
            message=msg,
            status_code=status.HTTP_404_NOT_FOUND,
        )


class UnauthorizedError(ParakhException):
    """Authentication failed."""

    def __init__(self, message: str = "Authentication required"):
        super().__init__(
            code="UNAUTHORIZED",
            message=message,
            status_code=status.HTTP_401_UNAUTHORIZED,
        )


class ForbiddenError(ParakhException):
    """Insufficient permissions."""

    def __init__(self, message: str = "Insufficient permissions"):
        super().__init__(
            code="FORBIDDEN",
            message=message,
            status_code=status.HTTP_403_FORBIDDEN,
        )


class ValidationError(ParakhException):
    """Input validation failed."""

    def __init__(self, message: str, details: Optional[dict] = None):
        super().__init__(
            code="VALIDATION_ERROR",
            message=message,
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            details=details,
        )


class ConflictError(ParakhException):
    """Resource conflict (e.g., duplicate)."""

    def __init__(self, message: str):
        super().__init__(
            code="CONFLICT",
            message=message,
            status_code=status.HTTP_409_CONFLICT,
        )


class ServiceUnavailableError(ParakhException):
    """External service unavailable."""

    def __init__(self, service: str):
        super().__init__(
            code="SERVICE_UNAVAILABLE",
            message=f"{service} is currently unavailable",
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
        )


class InsufficientDataError(ParakhException):
    """Insufficient data to perform operation."""

    def __init__(self, message: str = "Insufficient data"):
        super().__init__(
            code="INSUFFICIENT_DATA",
            message=message,
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        )


class RateLimitExceededError(ParakhException):
    """Rate limit exceeded."""

    def __init__(self):
        super().__init__(
            code="RATE_LIMIT_EXCEEDED",
            message="Too many requests. Please try again later.",
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
        )


class FileValidationError(ParakhException):
    """Uploaded file failed validation."""

    def __init__(self, message: str):
        super().__init__(
            code="FILE_VALIDATION_ERROR",
            message=message,
            status_code=status.HTTP_400_BAD_REQUEST,
        )


class BlockchainUnavailableError(ParakhException):
    """Blockchain service unavailable."""

    def __init__(self):
        super().__init__(
            code="BLOCKCHAIN_SERVICE_UNAVAILABLE",
            message="Blockchain service is currently unavailable",
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
        )


class ImageQualityError(ParakhException):
    """Image quality insufficient for processing."""

    def __init__(self, message: str = "Image quality insufficient for reliable processing"):
        super().__init__(
            code="INSUFFICIENT_IMAGE_QUALITY",
            message=message,
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        )


# --- Exception Handlers ---

def _error_response(
    status_code: int,
    code: str,
    message: str,
    details: Optional[dict] = None,
) -> JSONResponse:
    """Build a standardized error response per §39."""
    body: dict[str, Any] = {
        "success": False,
        "data": None,
        "error": {
            "code": code,
            "message": message,
        },
    }
    if details:
        body["error"]["details"] = details
    return JSONResponse(status_code=status_code, content=body)


def register_exception_handlers(app: FastAPI) -> None:
    """Register all custom exception handlers on the FastAPI app."""

    @app.exception_handler(ParakhException)
    async def parakh_exception_handler(
        request: Request, exc: ParakhException
    ) -> JSONResponse:
        return _error_response(
            status_code=exc.status_code,
            code=exc.code,
            message=exc.message,
            details=exc.details,
        )

    @app.exception_handler(RequestValidationError)
    async def validation_exception_handler(
        request: Request, exc: RequestValidationError
    ) -> JSONResponse:
        # Sanitize validation errors — don't expose internal model details
        errors = []
        for error in exc.errors():
            errors.append({
                "field": ".".join(str(loc) for loc in error.get("loc", [])),
                "message": error.get("msg", "Validation error"),
                "type": error.get("type", ""),
            })
        return _error_response(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            code="VALIDATION_ERROR",
            message="Request validation failed",
            details={"errors": errors},
        )

    @app.exception_handler(Exception)
    async def general_exception_handler(
        request: Request, exc: Exception
    ) -> JSONResponse:
        # Never expose internal stack traces to clients
        import logging
        logger = logging.getLogger("parakh.error")
        logger.exception("Unhandled exception: %s", exc)

        return _error_response(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            code="INTERNAL_ERROR",
            message="An internal error occurred. Please try again later.",
        )
