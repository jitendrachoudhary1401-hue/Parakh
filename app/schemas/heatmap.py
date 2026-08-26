"""
Project PARAKH — Heatmap Schemas

Per §29: Return actual geographic data. Never generate random coordinates.
"""

from __future__ import annotations

from typing import List, Optional

from pydantic import BaseModel, Field


class HeatmapPoint(BaseModel):
    """Single geographic point with observation data."""
    latitude: float = Field(..., ge=-90, le=90)
    longitude: float = Field(..., ge=-180, le=180)
    weight: float = Field(..., ge=0)
    data_type: str  # "historical" or "predicted"
    label: Optional[str] = None
    count: int = 0


class HeatmapResponse(BaseModel):
    """Heatmap API response per §29."""
    status: str  # "success", "empty", "INSUFFICIENT_DATA"
    data_points: List[HeatmapPoint] = []
    total_observations: int = 0
    historical_count: int = 0
    predicted_count: int = 0
    message: Optional[str] = None
