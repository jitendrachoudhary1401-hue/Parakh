"""
Project PARAKH — User Management Router

Implements §9 & §11:
User self profile and authorized administration.
"""

from __future__ import annotations

from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_admin, get_current_user
from app.core.responses import paginated_response, success_response
from app.db.postgres import get_db
from app.models.user import User
from app.schemas.user import UserCreate, UserResponse, UserUpdate
from app.services.user_service import UserService

router = APIRouter(prefix="/users", tags=["Users"])


@router.get("/me")
async def get_my_profile(current_user: User = Depends(get_current_user)):
    """Retrieve profile of currently authenticated user."""
    return success_response(
        data=UserResponse.model_validate(current_user).model_dump()
    )


@router.get("/", dependencies=[Depends(get_current_admin)])
async def list_users(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    role: Optional[str] = None,
    is_active: Optional[bool] = None,
    db: AsyncSession = Depends(get_db),
):
    """Admin-only: list registered users with pagination."""
    service = UserService(db)
    offset = (page - 1) * page_size
    users, total = await service.list_users(
        offset=offset, limit=page_size, role=role, is_active=is_active
    )
    user_dicts = [UserResponse.model_validate(u).model_dump() for u in users]
    return paginated_response(data=user_dicts, total=total, page=page, page_size=page_size)


@router.post("/", dependencies=[Depends(get_current_admin)])
async def create_user(
    payload: UserCreate,
    db: AsyncSession = Depends(get_db),
):
    """Admin-only: register a new system user with assigned role."""
    service = UserService(db)
    created = await service.create_user(payload)
    return success_response(
        data=UserResponse.model_validate(created).model_dump(),
        message="User created successfully",
        status_code=201,
    )


@router.get("/{user_id}", dependencies=[Depends(get_current_admin)])
async def get_user_detail(
    user_id: UUID,
    db: AsyncSession = Depends(get_db),
):
    """Admin-only: get details of a specific user."""
    service = UserService(db)
    user = await service.get_user_by_id(user_id)
    return success_response(data=UserResponse.model_validate(user).model_dump())


@router.patch("/{user_id}", dependencies=[Depends(get_current_admin)])
async def update_user(
    user_id: UUID,
    payload: UserUpdate,
    db: AsyncSession = Depends(get_db),
):
    """Admin-only: update user role, status, or details."""
    service = UserService(db)
    updated = await service.update_user(user_id, payload)
    return success_response(
        data=UserResponse.model_validate(updated).model_dump(),
        message="User updated successfully",
    )
