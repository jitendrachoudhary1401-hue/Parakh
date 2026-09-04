"""
Project PARAKH — Scan & Upload Service

Handles secure image reception, validation, object storage dispatch, and inspection initialization per §8/§14/§36.
"""

from __future__ import annotations

import logging
import uuid
from typing import Optional
from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession

from app.models.inspection import Inspection
from app.repositories.inspection_repo import InspectionRepository
from app.security.file_validator import FileValidator
from app.storage import get_storage_backend

logger = logging.getLogger("parakh.services.scan")


class ScanService:
    def __init__(self, db: AsyncSession):
        self.db = db
        self.inspection_repo = InspectionRepository(db)
        self.storage = get_storage_backend()

    async def handle_image_upload(
        self,
        inspector_id: UUID,
        file_bytes: bytes,
        filename: str,
        product_barcode: Optional[str] = None,
        latitude: Optional[float] = None,
        longitude: Optional[float] = None,
        location_name: Optional[str] = None,
        notes: Optional[str] = None,
        shop_name: Optional[str] = None,
        shop_owner_name: Optional[str] = None,
        shop_address: Optional[str] = None,
    ) -> Inspection:
        """Validate uploaded image, store in object storage, and create inspection entity."""
        # 1. Strict file validation
        is_valid, mime_type = FileValidator.validate_image_upload(file_bytes, filename)

        inspection_id = uuid.uuid4()
        extension = "jpg" if mime_type == "image/jpeg" else ("png" if mime_type == "image/png" else "webp")
        storage_path = f"inspections/{inspector_id}/{inspection_id}/raw.{extension}"

        # 2. Upload to MinIO / Local storage
        await self.storage.upload_file(
            file_bytes=file_bytes,
            destination_path=storage_path,
            content_type=mime_type,
        )

        metadata = {}
        if shop_name or shop_owner_name or shop_address:
            metadata["establishment"] = {
                "shop_name": shop_name,
                "shop_owner_name": shop_owner_name,
                "shop_address": shop_address,
            }

        # 3. Create inspection record
        inspection = Inspection(
            inspection_id=inspection_id,
            inspector_id=inspector_id,
            product_barcode=product_barcode,
            latitude=latitude,
            longitude=longitude,
            location_name=shop_name or location_name,
            status="pending",
            image_storage_path=storage_path,
            notes=notes,
            metadata_json=metadata if metadata else None,
        )

        created_inspection = await self.inspection_repo.create(inspection)
        logger.info("Created inspection %s for inspector %s", inspection_id, inspector_id)
        return created_inspection
