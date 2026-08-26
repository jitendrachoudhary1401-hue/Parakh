"""
Project PARAKH — Analytics & Prediction Service
"""

from __future__ import annotations

from typing import Any, Dict, List

from sqlalchemy.ext.asyncio import AsyncSession

from app.ai.predictive import PredictiveAnalytics
from app.analytics.dashboard import DashboardService
from app.repositories.inspection_repo import InspectionRepository


class AnalyticsService:
    def __init__(self, db: AsyncSession):
        self.db = db
        self.dashboard = DashboardService(db)
        self.inspection_repo = InspectionRepository(db)
        self.predictive_ai = PredictiveAnalytics()

    async def get_dashboard_metrics(self) -> Dict[str, int]:
        return await self.dashboard.get_summary_metrics()

    async def get_trends(self, period_type: str = "daily", days_back: int = 30) -> List[Dict[str, Any]]:
        return await self.dashboard.get_historical_trends(period_type, days_back)

    async def get_predictions(self) -> Dict[str, Any]:
        inspections = await self.inspection_repo.get_geographic_data()
        hist_data = [
            {
                "latitude": i.latitude,
                "longitude": i.longitude,
                "status": i.overall_result,
                "month": i.created_at.month if i.created_at else 1,
                "day_of_week": i.created_at.weekday() if i.created_at else 0,
            }
            for i in inspections
        ]
        result = await self.predictive_ai.predict_risk_areas(hist_data)
        return {
            "status": result.status,
            "predictions": [
                {
                    "latitude": p.latitude,
                    "longitude": p.longitude,
                    "risk_score": p.risk_score,
                    "risk_category": p.risk_category,
                    "contributing_factors": p.contributing_factors,
                }
                for p in result.predictions
            ],
            "model_used": result.model_used,
            "data_points_used": result.data_points_used,
            "message": result.message,
        }
