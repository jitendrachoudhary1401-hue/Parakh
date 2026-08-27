"""
Project PARAKH — Middleware

Request/response logging, secure headers, and CORS configuration.
CORS allows only explicitly configured frontend origins per §41.
"""

from __future__ import annotations

import logging
import time
import uuid

from fastapi import FastAPI, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from starlette.middleware.base import BaseHTTPMiddleware

from app.config import get_settings

logger = logging.getLogger("parakh.middleware")


# --- Secure Headers Middleware ---

class SecureHeadersMiddleware(BaseHTTPMiddleware):
    """
    Adds security-related HTTP headers to all responses.

    Headers per §34 security requirements.
    """

    async def dispatch(self, request: Request, call_next) -> Response:
        response = await call_next(request)
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-Frame-Options"] = "DENY"
        response.headers["X-XSS-Protection"] = "1; mode=block"
        response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
        response.headers["Cache-Control"] = "no-store, no-cache, must-revalidate"
        response.headers["Pragma"] = "no-cache"

        settings = get_settings()
        if settings.is_production:
            response.headers["Strict-Transport-Security"] = (
                "max-age=63072000; includeSubDomains; preload"
            )
            response.headers["Content-Security-Policy"] = (
                "default-src 'self'; frame-ancestors 'none'"
            )

        return response


# --- Request Logging Middleware ---

class RequestLoggingMiddleware(BaseHTTPMiddleware):
    """
    Logs incoming requests and response times.

    Assigns a unique request ID for traceability.
    """

    async def dispatch(self, request: Request, call_next) -> Response:
        request_id = str(uuid.uuid4())[:8]
        start_time = time.time()

        # Attach request ID for downstream use
        request.state.request_id = request_id

        logger.info(
            "REQ %s | %s %s | IP=%s",
            request_id,
            request.method,
            request.url.path,
            request.client.host if request.client else "unknown",
        )

        response = await call_next(request)

        duration_ms = (time.time() - start_time) * 1000
        logger.info(
            "RES %s | %s | %.1fms",
            request_id,
            response.status_code,
            duration_ms,
        )

        response.headers["X-Request-ID"] = request_id
        return response


# --- Setup Function ---

def setup_middleware(app: FastAPI) -> None:
    """
    Register all middleware on the FastAPI application.

    Order matters: CORS must be added first so preflight requests are handled
    before other middleware runs.
    """
    settings = get_settings()

    # CORS — only allow explicitly configured origins (§41)
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=True,
        allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
        allow_headers=["*"],
        expose_headers=["X-Request-ID"],
    )

    # Secure headers
    app.add_middleware(SecureHeadersMiddleware)

    # Request logging
    app.add_middleware(RequestLoggingMiddleware)

    logger.info(
        "Middleware configured. CORS origins: %s",
        settings.cors_origins,
    )
