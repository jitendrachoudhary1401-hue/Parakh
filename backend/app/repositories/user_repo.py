"""
Project PARAKH — User Repository
"""

from __future__ import annotations

from typing import List, Optional
from uuid import UUID

from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User


class UserRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_by_id(self, user_id: UUID) -> Optional[User]:
        result = await self.db.execute(
            select(User).where(User.user_id == user_id)
        )
        return result.scalar_one_or_none()

    async def get_by_email(self, email: str) -> Optional[User]:
        result = await self.db.execute(
            select(User).where(User.email == email.lower().strip())
        )
        return result.scalar_one_or_none()

    async def get_by_official_uid(self, uid: str) -> Optional[User]:
        result = await self.db.execute(
            select(User).where(User.official_uid == uid.upper().strip())
        )
        return result.scalar_one_or_none()

    async def get_by_identifier(self, identifier: str) -> Optional[User]:
        clean = identifier.strip()
        result = await self.db.execute(
            select(User).where(
                (User.email == clean.lower()) | (User.official_uid == clean.upper())
            )
        )
        return result.scalar_one_or_none()

    async def list_users(
        self,
        offset: int = 0,
        limit: int = 20,
        role: Optional[str] = None,
        is_active: Optional[bool] = None,
    ) -> tuple[List[User], int]:
        query = select(User)
        count_query = select(func.count()).select_from(User)

        if role:
            query = query.where(User.role == role)
            count_query = count_query.where(User.role == role)
        if is_active is not None:
            query = query.where(User.is_active == is_active)
            count_query = count_query.where(User.is_active == is_active)

        query = query.order_by(User.created_at.desc()).offset(offset).limit(limit)

        result = await self.db.execute(query)
        total_result = await self.db.execute(count_query)

        return list(result.scalars().all()), total_result.scalar_one()

    async def create(self, user: User) -> User:
        self.db.add(user)
        await self.db.flush()
        await self.db.refresh(user)
        return user

    async def update(self, user: User) -> User:
        await self.db.flush()
        await self.db.refresh(user)
        return user

    async def email_exists(self, email: str) -> bool:
        result = await self.db.execute(
            select(func.count()).select_from(User).where(User.email == email)
        )
        return result.scalar_one() > 0
