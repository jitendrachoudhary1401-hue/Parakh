"""
Project PARAKH — Authentication Router

Implements §9 & §10:
Login, token refresh, and logout.
"""

from fastapi import APIRouter, Depends, Request
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.audit.logger import AuditService
from app.core.rate_limiter import limiter
from app.core.responses import success_response
from app.db.postgres import get_db
from app.models.user import User
from app.schemas.auth import LoginRequest, RefreshTokenRequest, LogoutRequest
from app.services.auth_service import AuthService

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/login")
@limiter.limit("5/minute")
async def login(
    request: Request,
    payload: LoginRequest,
    db: AsyncSession = Depends(get_db),
):
    """Authenticate with credentials and obtain JWT access & refresh tokens."""
    auth_service = AuthService(db)
    token_data = await auth_service.authenticate_user(payload.email, payload.password)

    # Audit log
    try:
        audit = AuditService(db)
        await audit.log_event(
            action="AUTH_LOGIN_SUCCESS",
            user_email=payload.email,
            user_role=token_data["user"]["role"],
            resource_type="auth",
            ip_address=request.client.host if request.client else None,
            user_agent=request.headers.get("user-agent"),
        )
    except Exception:
        pass

    return success_response(data=token_data, message="Authentication successful")


@router.post("/refresh")
@limiter.limit("10/minute")
async def refresh_token(
    request: Request,
    payload: RefreshTokenRequest,
    db: AsyncSession = Depends(get_db),
):
    """Exchange a valid refresh token for a new access token."""
    auth_service = AuthService(db)
    result = await auth_service.refresh_access_token(payload.refresh_token)
    return success_response(data=result, message="Token refreshed successfully")


@router.post("/logout")
async def logout(
    request: Request,
    payload: LogoutRequest = None,
    db: AsyncSession = Depends(get_db),
):
    """Invalidate session / logout."""
    return success_response(data={"logged_out": True}, message="Successfully logged out")


@router.get("/me")
async def get_me(
    current_user: User = Depends(get_current_user),
):
    """Return currently authenticated user information."""
    return success_response(
        data={
            "user_id": str(current_user.user_id),
            "official_uid": current_user.official_uid,
            "full_name": current_user.full_name,
            "email": current_user.email,
            "role": current_user.role,
            "zone_id": current_user.zone_id,
        },
        message="User profile retrieved successfully",
    )
