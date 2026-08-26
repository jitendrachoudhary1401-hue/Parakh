"""
Project PARAKH — Evidence Repository
"""

from __future__ import annotations

from typing import List, Optional
from uuid import UUID

from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.evidence import Evidence


class EvidenceRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_by_id(self, evidence_id: UUID) -> Optional[Evidence]:
        result = await self.db.execute(
            select(Evidence).where(Evidence.evidence_id == evidence_id)
        )
        return result.scalar_one_or_none()

    async def get_by_inspection(self, inspection_id: UUID) -> List[Evidence]:
        result = await self.db.execute(
            select(Evidence)
            .where(Evidence.inspection_id == inspection_id)
            .order_by(Evidence.created_at.desc())
        )
        return list(result.scalars().all())

    async def create(self, evidence: Evidence) -> Evidence:
        self.db.add(evidence)
        await self.db.flush()
        await self.db.refresh(evidence)
        return evidence

    async def update(self, evidence: Evidence) -> Evidence:
        await self.db.flush()
        await self.db.refresh(evidence)
        return evidence

    async def count_committed(self) -> int:
        result = await self.db.execute(
            select(func.count())
            .select_from(Evidence)
            .where(Evidence.blockchain_status == "committed")
        )
        return result.scalar_one()
