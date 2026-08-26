"""
Project PARAKH — User Management Service
"""

from __future__ import annotations

from typing import List, Optional
from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import ConflictError, NotFoundError
from app.core.security import hash_password
from app.models.user import User
from app.repositories.user_repo import UserRepository
from app.schemas.user import UserCreate, UserUpdate


class UserService:
    def __init__(self, db: AsyncSession):
        self.db = db
        self.user_repo = UserRepository(db)

    async def get_user_by_id(self, user_id: UUID) -> User:
        user = await self.user_repo.get_by_id(user_id)
        if not user:
            raise NotFoundError("User", str(user_id))
        return user

    async def list_users(
        self,
        offset: int = 0,
        limit: int = 20,
        role: Optional[str] = None,
        is_active: Optional[bool] = None,
    ) -> tuple[List[User], int]:
        return await self.user_repo.list_users(
            offset=offset, limit=limit, role=role, is_active=is_active
        )

    async def create_user(self, data: UserCreate) -> User:
        clean_email = data.email.lower().strip()
        if await self.user_repo.email_exists(clean_email):
            raise ConflictError(f"User with email '{clean_email}' already exists")

        user = User(
            full_name=data.full_name.strip(),
            email=clean_email,
            hashed_password=hash_password(data.password),
            role=data.role,
            zone_id=data.zone_id,
            phone=data.phone,
            is_active=True,
        )
        return await self.user_repo.create(user)

    async def update_user(self, user_id: UUID, data: UserUpdate) -> User:
        user = await self.get_user_by_id(user_id)
        if data.full_name is not None:
            user.full_name = data.full_name.strip()
        if data.role is not None:
            user.role = data.role
        if data.zone_id is not None:
            user.zone_id = data.zone_id
        if data.phone is not None:
            user.phone = data.phone
        if data.is_active is not None:
            user.is_active = data.is_active

        return await self.user_repo.update(user)
