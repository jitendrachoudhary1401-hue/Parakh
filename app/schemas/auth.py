"""
Project PARAKH — Authentication Schemas
"""

from __future__ import annotations

try:
    from pydantic import EmailStr
except ImportError:
    EmailStr = str

from pydantic import BaseModel, Field


class LoginRequest(BaseModel):
    """OAuth2 login credentials."""
    email: str = Field(..., min_length=3, max_length=255)
    password: str = Field(..., min_length=8)


class TokenResponse(BaseModel):
    """JWT token pair response."""
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int  # seconds


class RefreshTokenRequest(BaseModel):
    """Refresh token exchange request."""
    refresh_token: str


class LogoutRequest(BaseModel):
    """Logout / session invalidation."""
    refresh_token: Optional[str] = None
