"""
Project PARAKH — Legal Notice Repository
"""

from __future__ import annotations

from typing import List, Optional
from uuid import UUID

from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.legal_notice import LegalNotice


class LegalNoticeRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_by_id(self, notice_id: UUID) -> Optional[LegalNotice]:
        result = await self.db.execute(
            select(LegalNotice).where(LegalNotice.notice_id == notice_id)
        )
        return result.scalar_one_or_none()

    async def get_by_inspection(self, inspection_id: UUID) -> List[LegalNotice]:
        result = await self.db.execute(
            select(LegalNotice)
            .where(LegalNotice.inspection_id == inspection_id)
            .order_by(LegalNotice.generated_at.desc())
        )
        return list(result.scalars().all())

    async def create(self, notice: LegalNotice) -> LegalNotice:
        self.db.add(notice)
        await self.db.flush()
        await self.db.refresh(notice)
        return notice

    async def update(self, notice: LegalNotice) -> LegalNotice:
        await self.db.flush()
        await self.db.refresh(notice)
        return notice
