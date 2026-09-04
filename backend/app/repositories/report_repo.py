"""
Project PARAKH — Report Repository
"""

from __future__ import annotations

from typing import List, Optional
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.report import Report


class ReportRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_by_id(self, report_id: UUID) -> Optional[Report]:
        result = await self.db.execute(
            select(Report).where(Report.report_id == report_id)
        )
        return result.scalar_one_or_none()

    async def get_by_inspection(self, inspection_id: UUID) -> List[Report]:
        result = await self.db.execute(
            select(Report)
            .where(Report.inspection_id == inspection_id)
            .order_by(Report.created_at.desc())
        )
        return list(result.scalars().all())

    async def list_reports(self, limit: int = 50, offset: int = 0) -> List[Report]:
        result = await self.db.execute(
            select(Report)
            .order_by(Report.created_at.desc())
            .limit(limit)
            .offset(offset)
        )
        return list(result.scalars().all())

    async def get_by_status(self, status: str, limit: int = 50) -> List[Report]:
        result = await self.db.execute(
            select(Report)
            .where(Report.status == status)
            .order_by(Report.created_at.desc())
            .limit(limit)
        )
        return list(result.scalars().all())

    async def create(self, report: Report) -> Report:
        self.db.add(report)
        await self.db.flush()
        await self.db.refresh(report)
        return report

    async def update(self, report: Report) -> Report:
        await self.db.flush()
        await self.db.refresh(report)
        return report

