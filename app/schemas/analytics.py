"""
Project PARAKH — Analytics Schemas
"""

from __future__ import annotations

from typing import List, Optional

from pydantic import BaseModel


class DashboardMetrics(BaseModel):
    """Dashboard summary metrics — computed from actual data per §27."""
    total_inspections: int = 0
    compliant: int = 0
    violations: int = 0
    pending_review: int = 0
    citizen_reports: int = 0
    citizen_reports_pending: int = 0
    evidence_committed: int = 0
    legal_notices_generated: int = 0


class TrendDataPoint(BaseModel):
    """Single data point in a trend series."""
    period: str  # e.g., "2026-08", "2026-W34"
    inspections: int = 0
    compliant: int = 0
    violations: int = 0
    pending_review: int = 0


class TrendResponse(BaseModel):
    """Historical trend data."""
    period_type: str  # "daily", "weekly", "monthly"
    data_points: List[TrendDataPoint] = []


class PredictionResult(BaseModel):
    """Predictive analytics result per §28."""
    status: str  # "success" or "INSUFFICIENT_DATA"
    predictions: List[dict] = []
    model_used: Optional[str] = None
    data_points_used: int = 0
    message: Optional[str] = None
