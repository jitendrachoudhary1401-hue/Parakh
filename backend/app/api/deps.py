"""
Project PARAKH — API Dependencies

Shared FastAPI dependencies: database sessions, authenticated user extraction, and RBAC guards.
"""

from __future__ import annotations

from typing import Any, Dict
from uuid import UUID

from fastapi import Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.rbac import Role, require_roles
from app.core.security import get_current_user_payload
from app.db.postgres import get_db
from app.models.user import User
from app.repositories.user_repo import UserRepository


async def get_current_user(
    payload: Dict[str, Any] = Depends(get_current_user_payload),
    db: AsyncSession = Depends(get_db),
) -> User:
    """Dependency that resolves the authenticated User ORM model from token."""
    user_id_str = payload.get("sub")
    if not user_id_str:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token missing subject identifier",
        )

    user_repo = UserRepository(db)
    user = await user_repo.get_by_id(UUID(user_id_str))
    if not user or not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found or inactive",
        )
    return user


def get_current_inspector(
    payload: Dict[str, Any] = Depends(require_roles(Role.INSPECTOR, Role.ADMIN)),
) -> Dict[str, Any]:
    """Dependency allowing Inspectors or Admins."""
    return payload


def get_current_admin(
    payload: Dict[str, Any] = Depends(require_roles(Role.ADMIN)),
) -> Dict[str, Any]:
    """Dependency allowing Admins only."""
    return payload


def get_current_citizen(
    payload: Dict[str, Any] = Depends(require_roles(Role.CITIZEN, Role.ADMIN)),
) -> Dict[str, Any]:
    """Dependency allowing Citizens or Admins."""
    return payload
