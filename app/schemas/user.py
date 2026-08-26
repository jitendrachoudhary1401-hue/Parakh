"""
Project PARAKH — User Schemas
"""

from __future__ import annotations

from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, Field


class UserCreate(BaseModel):
    """Admin-only user creation."""
    full_name: str = Field(..., min_length=2, max_length=255)
    email: str = Field(..., min_length=3, max_length=255)
    password: str = Field(..., min_length=8)
    role: str = Field(..., pattern="^(inspector|admin|citizen)$")
    zone_id: Optional[str] = None
    phone: Optional[str] = None


class UserUpdate(BaseModel):
    """User update (admin)."""
    full_name: Optional[str] = Field(None, min_length=2, max_length=255)
    role: Optional[str] = Field(None, pattern="^(inspector|admin|citizen)$")
    zone_id: Optional[str] = None
    phone: Optional[str] = None
    is_active: Optional[bool] = None


class UserResponse(BaseModel):
    """User data returned via API."""
    user_id: UUID
    full_name: str
    email: str
    role: str
    zone_id: Optional[str] = None
    phone: Optional[str] = None
    is_active: bool
    created_at: datetime
    updated_at: datetime
    last_login_at: Optional[datetime] = None

    model_config = {"from_attributes": True}


class UserSummary(BaseModel):
    """Minimal user reference."""
    user_id: UUID
    full_name: str
    role: str

    model_config = {"from_attributes": True}
