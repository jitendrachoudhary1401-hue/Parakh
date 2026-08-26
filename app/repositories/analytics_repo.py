"""
Project PARAKH — Analytics Repository

Computes dashboard metrics from actual database records per §27.
Never stores hardcoded dashboard values.
"""

from __future__ import annotations

from datetime import datetime, timedelta, timezone
from typing import List

from sqlalchemy import select, func, extract, and_, cast, Date
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.inspection import Inspection
from app.models.citizen_report import CitizenReport
from app.models.evidence import Evidence
from app.models.legal_notice import LegalNotice


class AnalyticsRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_inspection_counts(self) -> dict[str, int]:
        """Get inspection counts by status from actual records."""
        result = await self.db.execute(
            select(Inspection.overall_result, func.count())
            .group_by(Inspection.overall_result)
        )
        counts = {(row[0] or "pending"): row[1] for row in result.all()}
        total = await self.db.execute(
            select(func.count()).select_from(Inspection)
        )
        counts["total"] = total.scalar_one()
        return counts

    async def get_citizen_report_counts(self) -> dict[str, int]:
        total = await self.db.execute(
            select(func.count()).select_from(CitizenReport)
        )
        pending = await self.db.execute(
            select(func.count())
            .select_from(CitizenReport)
            .where(CitizenReport.admin_decision == "pending")
        )
        return {
            "total": total.scalar_one(),
            "pending": pending.scalar_one(),
        }

    async def get_evidence_committed_count(self) -> int:
        result = await self.db.execute(
            select(func.count())
            .select_from(Evidence)
            .where(Evidence.blockchain_status == "committed")
        )
        return result.scalar_one()

    async def get_legal_notices_count(self) -> int:
        result = await self.db.execute(
            select(func.count()).select_from(LegalNotice)
        )
        return result.scalar_one()

    async def get_trend_data(
        self,
        period_type: str = "daily",
        days_back: int = 30,
    ) -> list[dict]:
        """Get inspection trend data grouped by time period."""
        cutoff = datetime.now(timezone.utc) - timedelta(days=days_back)

        if period_type == "daily":
            date_col = cast(Inspection.created_at, Date)
        else:
            date_col = func.date_trunc("month", Inspection.created_at)

        result = await self.db.execute(
            select(
                date_col.label("period"),
                func.count().label("total"),
                func.count().filter(Inspection.overall_result == "compliant").label("compliant"),
                func.count().filter(Inspection.overall_result == "violation").label("violations"),
                func.count().filter(Inspection.overall_result == "requires_review").label("pending_review"),
            )
            .where(Inspection.created_at >= cutoff)
            .group_by(date_col)
            .order_by(date_col)
        )

        return [
            {
                "period": str(row.period),
                "inspections": row.total,
                "compliant": row.compliant,
                "violations": row.violations,
                "pending_review": row.pending_review,
            }
            for row in result.all()
        ]
