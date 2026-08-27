"""
Project PARAKH — Standardized API Response Wrappers

All API responses follow the format specified in §39:
    Success: {"success": true, "data": {...}, "error": null}
    Error:   {"success": false, "data": null, "error": {"code": "...", "message": "..."}}
"""

from __future__ import annotations

from typing import Any, Optional

from fastapi.encoders import jsonable_encoder
from fastapi.responses import JSONResponse


def success_response(
    data: Any = None,
    message: Optional[str] = None,
    status_code: int = 200,
    headers: Optional[dict[str, str]] = None,
) -> JSONResponse:
    """
    Build a standardized success response.

    Args:
        data: The response payload.
        message: Optional success message.
        status_code: HTTP status code (default 200).
        headers: Optional response headers.
    """
    body: dict[str, Any] = {
        "success": True,
        "data": data,
        "error": None,
    }
    if message:
        body["message"] = message
    return JSONResponse(
        status_code=status_code,
        content=jsonable_encoder(body),
        headers=headers,
    )


def error_response(
    code: str,
    message: str,
    status_code: int = 400,
    details: Optional[dict[str, Any]] = None,
) -> JSONResponse:
    """
    Build a standardized error response.

    Args:
        code: Machine-readable error code.
        message: Human-readable error message.
        status_code: HTTP status code.
        details: Optional additional error details.
    """
    error_body: dict[str, Any] = {
        "code": code,
        "message": message,
    }
    if details:
        error_body["details"] = details

    return JSONResponse(
        status_code=status_code,
        content=jsonable_encoder({
            "success": False,
            "data": None,
            "error": error_body,
        }),
    )


def paginated_response(
    data: list[Any],
    total: int,
    page: int,
    page_size: int,
    status_code: int = 200,
) -> JSONResponse:
    """
    Build a standardized paginated response.

    Args:
        data: List of items for the current page.
        total: Total number of items across all pages.
        page: Current page number (1-indexed).
        page_size: Number of items per page.
    """
    total_pages = (total + page_size - 1) // page_size if page_size > 0 else 0

    return JSONResponse(
        status_code=status_code,
        content=jsonable_encoder({
            "success": True,
            "data": data,
            "error": None,
            "pagination": {
                "total": total,
                "page": page,
                "page_size": page_size,
                "total_pages": total_pages,
                "has_next": page < total_pages,
                "has_prev": page > 1,
            },
        }),
    )
