"""
Project PARAKH — Offline Sync Router

Implements §33:
Mobile edge client offline sync endpoint.
"""

from __future__ import annotations

from typing import Any, Dict, List
from uuid import UUID

from fastapi import APIRouter, Body, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_inspector
from app.core.responses import success_response
from app.db.postgres import get_db
from app.services.sync_service import SyncService

router = APIRouter(prefix="/sync", tags=["Offline Sync"])


@router.post("/upload")
async def sync_offline_inspections(
    records: List[Dict[str, Any]] = Body(..., description="Batch of offline captured inspection records"),
    user_payload: dict = Depends(get_current_inspector),
    db: AsyncSession = Depends(get_db),
):
    """
    Receive batch of offline captured inspection metadata.
    Validates ownership, timestamps, and prevents duplicate records.
    """
    inspector_id = UUID(user_payload["sub"])
    service = SyncService(db)
    result = await service.process_offline_batch(inspector_id=inspector_id, records=records)
    return success_response(
        data=result,
        message=f"Sync complete: {result['synced_count']} synced, {result['failed_count']} failed",
    )
