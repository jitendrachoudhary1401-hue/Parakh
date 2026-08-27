"""
Project PARAKH — Analytics & Dashboard Router

Implements §9, §27, §28:
Dashboard metrics, historical trends, and predictive risk analytics.
"""

from typing import Optional

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_admin
from app.core.responses import success_response
from app.db.postgres import get_db
from app.services.analytics_service import AnalyticsService

router = APIRouter(prefix="/analytics", tags=["Analytics & Reporting"])


@router.get("/dashboard", dependencies=[Depends(get_current_admin)])
async def get_dashboard_metrics(db: AsyncSession = Depends(get_db)):
    """Fetch live aggregated dashboard counters and metrics."""
    service = AnalyticsService(db)
    metrics = await service.get_dashboard_metrics()
    return success_response(data=metrics)


@router.get("/trends", dependencies=[Depends(get_current_admin)])
async def get_historical_trends(
    period_type: str = Query("daily", pattern="^(daily|monthly)$"),
    days_back: int = Query(30, ge=1, le=365),
    db: AsyncSession = Depends(get_db),
):
    """Fetch historical inspection and violation volume trends."""
    service = AnalyticsService(db)
    trends = await service.get_trends(period_type=period_type, days_back=days_back)
    return success_response(data={"period_type": period_type, "data_points": trends})


@router.get("/predictions", dependencies=[Depends(get_current_admin)])
async def get_predictive_analytics(db: AsyncSession = Depends(get_db)):
    """Run ML predictive analytics on historical violation dataset."""
    service = AnalyticsService(db)
    predictions = await service.get_predictions()
    return success_response(data=predictions)
