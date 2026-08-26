"""
Project PARAKH — Citizen Crowdsourcing Service

Implements §30:
Submit report → Image upload & validation → AI triage → Admin review workflow → Status updates.
"""

from __future__ import annotations

import logging
import uuid
from datetime import datetime, timezone
from typing import List, Optional
from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession

from app.ai.ai_triage import AITriage
from app.ai.image_processor import ImageProcessor
from app.core.exceptions import NotFoundError
from app.models.citizen_report import CitizenReport
from app.repositories.citizen_repo import CitizenReportRepository
from app.security.file_validator import FileValidator
from app.storage import get_storage_backend

logger = logging.getLogger("parakh.services.citizen")


class CitizenService:
    def __init__(self, db: AsyncSession):
        self.db = db
        self.repo = CitizenReportRepository(db)
        self.storage = get_storage_backend()
        self.image_processor = ImageProcessor()
        self.triage = AITriage()

    async def get_by_id(self, report_id: UUID) -> CitizenReport:
        report = await self.repo.get_by_id(report_id)
        if not report:
            raise NotFoundError("Citizen report", str(report_id))
        return report

    async def list_reports(
        self,
        offset: int = 0,
        limit: int = 20,
        citizen_id: Optional[UUID] = None,
        admin_decision: Optional[str] = None,
        ai_triage_status: Optional[str] = None,
    ) -> tuple[List[CitizenReport], int]:
        return await self.repo.list_reports(
            offset=offset,
            limit=limit,
            citizen_id=citizen_id,
            admin_decision=admin_decision,
            ai_triage_status=ai_triage_status,
        )

    async def submit_report(
        self,
        citizen_id: UUID,
        file_bytes: bytes,
        filename: str,
        description: Optional[str] = None,
        product_barcode: Optional[str] = None,
        latitude: Optional[float] = None,
        longitude: Optional[float] = None,
        location_name: Optional[str] = None,
        source: str = "app",
    ) -> CitizenReport:
        """Process citizen report submission with AI triage."""
        # 1. Validate file
        is_valid, mime_type = FileValidator.validate_image_upload(file_bytes, filename)

        report_id = uuid.uuid4()
        extension = "jpg" if mime_type == "image/jpeg" else ("png" if mime_type == "image/png" else "webp")
        storage_path = f"citizen_reports/{citizen_id}/{report_id}/photo.{extension}"

        # 2. Upload to storage
        await self.storage.upload_file(file_bytes, storage_path, mime_type)

        # 3. AI Triage processing
        proc = self.image_processor.process(file_bytes)
        triage_status = "pending"
        triage_confidence = 0.0
        triage_details = {}

        if proc.success and proc.processed_image is not None:
            triage_res = self.triage.assess(proc.processed_image, ocr_text="")
            triage_status = triage_res.classification
            triage_confidence = triage_res.confidence
            triage_details = {
                "reason": triage_res.reason,
                "is_actionable": triage_res.is_actionable,
            }

        # 4. Save report entity
        report = CitizenReport(
            report_id=report_id,
            citizen_id=citizen_id,
            image_storage_path=storage_path,
            description=description,
            product_barcode=product_barcode,
            latitude=latitude,
            longitude=longitude,
            location_name=location_name,
            ai_triage_status=triage_status,
            ai_triage_confidence=triage_confidence,
            ai_triage_details=triage_details,
            admin_decision="pending",
            source=source,
        )

        return await self.repo.create(report)

    async def triage_report(
        self,
        report_id: UUID,
        admin_id: UUID,
        decision: str,
        notes: Optional[str] = None,
    ) -> CitizenReport:
        """Admin review and approval/rejection of citizen report."""
        report = await self.get_by_id(report_id)
        report.admin_decision = decision
        report.admin_notes = notes
        report.reviewed_by = admin_id
        report.reviewed_at = datetime.now(timezone.utc)
        return await self.repo.update(report)
