"""
Project PARAKH — Citizen Report Repository
"""

from __future__ import annotations

from typing import List, Optional
from uuid import UUID

from sqlalchemy import select, func, and_
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.citizen_report import CitizenReport


class CitizenReportRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_by_id(self, report_id: UUID) -> Optional[CitizenReport]:
        result = await self.db.execute(
            select(CitizenReport).where(CitizenReport.report_id == report_id)
        )
        return result.scalar_one_or_none()

    async def list_reports(
        self,
        offset: int = 0,
        limit: int = 20,
        citizen_id: Optional[UUID] = None,
        admin_decision: Optional[str] = None,
        ai_triage_status: Optional[str] = None,
    ) -> tuple[List[CitizenReport], int]:
        query = select(CitizenReport)
        count_query = select(func.count()).select_from(CitizenReport)

        conditions = []
        if citizen_id:
            conditions.append(CitizenReport.citizen_id == citizen_id)
        if admin_decision:
            conditions.append(CitizenReport.admin_decision == admin_decision)
        if ai_triage_status:
            conditions.append(CitizenReport.ai_triage_status == ai_triage_status)

        if conditions:
            combined = and_(*conditions)
            query = query.where(combined)
            count_query = count_query.where(combined)

        query = query.order_by(CitizenReport.created_at.desc()).offset(offset).limit(limit)

        result = await self.db.execute(query)
        total_result = await self.db.execute(count_query)

        return list(result.scalars().all()), total_result.scalar_one()

    async def create(self, report: CitizenReport) -> CitizenReport:
        self.db.add(report)
        await self.db.flush()
        await self.db.refresh(report)
        return report

    async def update(self, report: CitizenReport) -> CitizenReport:
        await self.db.flush()
        await self.db.refresh(report)
        return report

    async def count_total(self) -> int:
        result = await self.db.execute(
            select(func.count()).select_from(CitizenReport)
        )
        return result.scalar_one()

    async def count_pending(self) -> int:
        result = await self.db.execute(
            select(func.count())
            .select_from(CitizenReport)
            .where(CitizenReport.admin_decision == "pending")
        )
        return result.scalar_one()
