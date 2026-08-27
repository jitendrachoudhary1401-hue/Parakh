"""
Project PARAKH — Heatmap & Geospatial Analytics Service

Implements §29:
Returns actual geographic data from inspections. Never generates random coordinates.
Distinguishes historical observations vs predicted risk.
"""

from __future__ import annotations

import logging
from typing import Any, Dict, List

from sqlalchemy.ext.asyncio import AsyncSession

from app.ai.predictive import PredictiveAnalytics
from app.repositories.inspection_repo import InspectionRepository

logger = logging.getLogger("parakh.services.heatmap")


class HeatmapService:
    def __init__(self, db: AsyncSession):
        self.db = db
        self.inspection_repo = InspectionRepository(db)
        self.predictive_ai = PredictiveAnalytics()

    async def get_heatmap_data(self) -> Dict[str, Any]:
        """Aggregate actual geo-located inspections and generate risk clusters."""
        inspections = await self.inspection_repo.get_geographic_data()

        if not inspections:
            return {
                "status": "empty",
                "data_points": [],
                "total_observations": 0,
                "historical_count": 0,
                "predicted_count": 0,
                "message": "No geo-tagged inspection records found in database",
            }

        # Build historical data points
        historical_points = []
        historical_dicts = []

        for insp in inspections:
            weight = 1.0 if insp.overall_result == "violation" else (0.5 if insp.overall_result == "requires_review" else 0.2)
            historical_points.append({
                "latitude": insp.latitude,
                "longitude": insp.longitude,
                "weight": weight,
                "data_type": "historical",
                "label": f"Inspection: {insp.overall_result or 'pending'}",
                "count": 1,
            })
            historical_dicts.append({
                "latitude": insp.latitude,
                "longitude": insp.longitude,
                "status": insp.overall_result,
                "month": insp.created_at.month if insp.created_at else 1,
                "day_of_week": insp.created_at.weekday() if insp.created_at else 0,
            })

        # Generate predictions if sufficient data
        pred_result = await self.predictive_ai.predict_risk_areas(historical_dicts)
        predicted_points = []

        if pred_result.success and pred_result.status == "success":
            for p in pred_result.predictions:
                predicted_points.append({
                    "latitude": p.latitude,
                    "longitude": p.longitude,
                    "weight": p.risk_score,
                    "data_type": "predicted",
                    "label": f"Predicted {p.risk_category} risk zone",
                    "count": 1,
                })

        combined_points = historical_points + predicted_points

        return {
            "status": "success",
            "data_points": combined_points,
            "total_observations": len(combined_points),
            "historical_count": len(historical_points),
            "predicted_count": len(predicted_points),
            "message": None,
        }
