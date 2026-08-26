"""
Project PARAKH — Heatmaps Router

Implements §8 & §29:
GET /api/v1/dashboard/heatmaps — Return actual aggregated geospatial analytics.
"""

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_admin
from app.core.responses import success_response
from app.db.postgres import get_db
from app.services.heatmap_service import HeatmapService

router = APIRouter(tags=["Geospatial Heatmaps"])


@router.get("/dashboard/heatmaps", dependencies=[Depends(get_current_admin)])
async def get_geospatial_heatmaps(db: AsyncSession = Depends(get_db)):
    """
    Return actual geo-located inspections and predictive risk clusters.
    Never generates random mock coordinates.
    """
    service = HeatmapService(db)
    heatmap_data = await service.get_heatmap_data()
    return success_response(data=heatmap_data)
