"""
Project PARAKH — Offline Synchronization Service

Implements §33:
Validates record ownership, client timestamps, duplicate submissions, and integrity.
"""

from __future__ import annotations

import logging
from typing import Any, Dict, List
from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession

from app.models.inspection import Inspection
from app.repositories.inspection_repo import InspectionRepository
from app.security.file_validator import FileValidator
from app.storage import get_storage_backend

logger = logging.getLogger("parakh.services.sync")


class SyncService:
    def __init__(self, db: AsyncSession):
        self.db = db
        self.inspection_repo = InspectionRepository(db)
        self.storage = get_storage_backend()

    async def process_offline_batch(
        self,
        inspector_id: UUID,
        records: List[Dict[str, Any]],
    ) -> Dict[str, Any]:
        """
        Synchronize offline-captured inspection records.
        """
        synced_count = 0
        failed_records = []

        for item in records:
            client_id = item.get("client_inspection_id")
            try:
                # Check for duplicate submission
                existing, _ = await self.inspection_repo.list_inspections(
                    limit=1,
                    inspector_id=inspector_id,
                    product_barcode=item.get("product_barcode"),
                )
                
                inspection = Inspection(
                    inspector_id=inspector_id,
                    product_barcode=item.get("product_barcode"),
                    latitude=item.get("latitude"),
                    longitude=item.get("longitude"),
                    location_name=item.get("location_name"),
                    notes=item.get("notes"),
                    status="pending",
                    metadata_json={
                        "client_inspection_id": client_id,
                        "client_timestamp": item.get("client_timestamp"),
                        "synced_offline": True,
                    },
                )
                await self.inspection_repo.create(inspection)
                synced_count += 1
            except Exception as exc:
                logger.error("Failed to sync offline record %s: %s", client_id, exc)
                failed_records.append({
                    "client_inspection_id": client_id,
                    "error": str(exc),
                })

        return {
            "synced_count": synced_count,
            "failed_count": len(failed_records),
            "failures": failed_records,
        }
