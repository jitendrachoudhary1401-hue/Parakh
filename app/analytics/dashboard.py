"""
Project PARAKH — Dashboard Analytics Aggregator

Implements §27:
All metrics computed from actual database records. No hardcoded or fake numbers.
"""

from __future__ import annotations

import logging
from typing import Any, Dict, List

from sqlalchemy.ext.asyncio import AsyncSession

from app.repositories.analytics_repo import AnalyticsRepository

logger = logging.getLogger("parakh.analytics.dashboard")


class DashboardService:
    """Computes real-time and historical analytics from database records."""

    def __init__(self, db: AsyncSession):
        self.analytics_repo = AnalyticsRepository(db)

    async def get_summary_metrics(self) -> Dict[str, int]:
        """Compute aggregate overview metrics for Nodal Officer dashboard."""
        insp_counts = await self.analytics_repo.get_inspection_counts()
        citizen_counts = await self.analytics_repo.get_citizen_report_counts()
        evidence_count = await self.analytics_repo.get_evidence_committed_count()
        notices_count = await self.analytics_repo.get_legal_notices_count()

        return {
            "total_inspections": insp_counts.get("total", 0),
            "compliant": insp_counts.get("compliant", 0),
            "violations": insp_counts.get("violation", 0),
            "pending_review": insp_counts.get("requires_review", 0) + insp_counts.get("pending", 0),
            "citizen_reports": citizen_counts.get("total", 0),
            "citizen_reports_pending": citizen_counts.get("pending", 0),
            "evidence_committed": evidence_count,
            "legal_notices_generated": notices_count,
        }

    async def get_historical_trends(
        self,
        period_type: str = "daily",
        days_back: int = 30,
    ) -> List[Dict[str, Any]]:
        """Fetch temporal compliance trends."""
        return await self.analytics_repo.get_trend_data(
            period_type=period_type,
            days_back=days_back,
        )
