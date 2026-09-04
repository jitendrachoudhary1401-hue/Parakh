"""
Project PARAKH — Inspection Lifecycle Service
"""

from __future__ import annotations

from datetime import datetime, timezone
from typing import List, Optional
from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import NotFoundError
from app.models.inspection import Inspection
from app.repositories.inspection_repo import InspectionRepository
from app.schemas.inspection import (
    InspectionCreate,
    InspectionUpdate,
    NodalSubmissionPayload,
)


class InspectionService:
    def __init__(self, db: AsyncSession):
        self.db = db
        self.repo = InspectionRepository(db)

    async def get_by_id(self, inspection_id: UUID) -> Inspection:
        inspection = await self.repo.get_by_id(inspection_id)
        if not inspection:
            raise NotFoundError("Inspection", str(inspection_id))
        return inspection

    async def list_inspections(
        self,
        offset: int = 0,
        limit: int = 20,
        status: Optional[str] = None,
        overall_result: Optional[str] = None,
        inspector_id: Optional[UUID] = None,
        product_barcode: Optional[str] = None,
        date_from: Optional[datetime] = None,
        date_to: Optional[datetime] = None,
    ) -> tuple[List[Inspection], int]:
        return await self.repo.list_inspections(
            offset=offset,
            limit=limit,
            status=status,
            overall_result=overall_result,
            inspector_id=inspector_id,
            product_barcode=product_barcode,
            date_from=date_from,
            date_to=date_to,
        )

    async def create_inspection(self, inspector_id: UUID, data: InspectionCreate) -> Inspection:
        inspection = Inspection(
            inspector_id=inspector_id,
            product_barcode=data.product_barcode,
            latitude=data.latitude,
            longitude=data.longitude,
            location_name=data.location_name,
            notes=data.notes,
            status="pending",
        )
        return await self.repo.create(inspection)

    async def update_status(self, inspection_id: UUID, data: InspectionUpdate) -> Inspection:
        inspection = await self.get_by_id(inspection_id)
        if data.status is not None:
            inspection.status = data.status
        if data.overall_result is not None:
            inspection.overall_result = data.overall_result
        if data.notes is not None:
            inspection.notes = data.notes

        return await self.repo.update(inspection)

    async def submit_to_nodal(
        self,
        inspection_id: UUID,
        payload: NodalSubmissionPayload,
    ) -> Inspection:
        """Submit finalized inspection report to Nodal Verifier with shop info, comments, and statutory rules."""
        inspection = await self.get_by_id(inspection_id)
        inspection.status = "pending_nodal_verification"
        if payload.notes:
            inspection.notes = payload.notes

        meta = dict(inspection.metadata_json or {})
        if payload.shop_name or payload.shop_owner_name or payload.shop_address:
            meta["establishment"] = {
                "shop_name": payload.shop_name or meta.get("establishment", {}).get("shop_name"),
                "shop_owner_name": payload.shop_owner_name or meta.get("establishment", {}).get("shop_owner_name"),
                "shop_address": payload.shop_address or meta.get("establishment", {}).get("shop_address"),
            }
            if payload.shop_name:
                inspection.location_name = payload.shop_name

        if payload.violation_rules is not None:
            meta["violation_rules"] = payload.violation_rules
            if len(payload.violation_rules) > 0:
                inspection.overall_result = "violation"

        if payload.evidence_images:
            meta["additional_evidence_images"] = payload.evidence_images

        meta["nodal_submission"] = {
            "submitted_at": datetime.now(timezone.utc).isoformat(),
            "target_verifier": "nodal.officer@doca.gov.in",
            "verifier_name": "Nodal Officer S. K. Sharma (Verification Authority)",
            "status": "PENDING_NODAL_VERIFICATION",
        }

        inspection.metadata_json = meta

        # Calculate cryptographic evidence hash
        from app.blockchain.evidence_chain import EvidenceChainService
        evidence_hash = EvidenceChainService.calculate_payload_hash(
            image_storage_path=inspection.image_storage_path,
            gps_latitude=inspection.latitude,
            gps_longitude=inspection.longitude,
            capture_timestamp=inspection.created_at or datetime.now(timezone.utc),
            ocr_text_snapshot=inspection.notes or "",
            inspector_id=str(inspection.inspector_id),
            violation_data=payload.violation_rules or [],
        )
        inspection.blockchain_hash = evidence_hash

        return await self.repo.update(inspection)
