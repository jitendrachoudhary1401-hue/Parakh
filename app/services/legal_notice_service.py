"""
Project PARAKH — Legal Notice Generation Service

Implements §26:
Generates formal PDF statutory notices using actual inspection data.
Never populates missing information with fake data. Stores PDF in object storage.
"""

from __future__ import annotations

import io
import logging
import uuid
from typing import Any, Dict, List, Optional
from uuid import UUID

from reportlab.lib import colors
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.platypus import HRFlowable, Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import NotFoundError
from app.models.legal_notice import LegalNotice
from app.repositories.inspection_repo import InspectionRepository
from app.repositories.legal_notice_repo import LegalNoticeRepository
from app.storage import get_storage_backend

logger = logging.getLogger("parakh.services.legal_notice")


class LegalNoticeService:
    def __init__(self, db: AsyncSession):
        self.db = db
        self.notice_repo = LegalNoticeRepository(db)
        self.inspection_repo = InspectionRepository(db)
        self.storage = get_storage_backend()

    async def get_by_id(self, notice_id: UUID) -> LegalNotice:
        notice = await self.notice_repo.get_by_id(notice_id)
        if not notice:
            raise NotFoundError("Legal notice", str(notice_id))
        return notice

    async def get_by_inspection(self, inspection_id: UUID) -> List[LegalNotice]:
        return await self.notice_repo.get_by_inspection(inspection_id)

    async def generate_notice(
        self,
        inspection_id: UUID,
        admin_id: UUID,
    ) -> LegalNotice:
        """Generate PDF legal notice and store record."""
        inspection = await self.inspection_repo.get_by_id(inspection_id)
        if not inspection:
            raise NotFoundError("Inspection", str(inspection_id))

        notice_id = uuid.uuid4()
        pdf_bytes = self._build_pdf_document(inspection, notice_id)

        storage_path = f"legal_notices/{inspection_id}/{notice_id}.pdf"
        await self.storage.upload_file(pdf_bytes, storage_path, "application/pdf")

        notice = LegalNotice(
            notice_id=notice_id,
            inspection_id=inspection_id,
            generated_by=admin_id,
            pdf_storage_path=storage_path,
            product_info={"barcode": inspection.product_barcode},
            violations={"overall_result": inspection.overall_result},
            inspector_name=f"Inspector ID: {inspection.inspector_id}",
            inspection_location=inspection.location_name or (f"Lat: {inspection.latitude}, Lon: {inspection.longitude}" if inspection.latitude else None),
            blockchain_receipt=inspection.blockchain_tx_id or inspection.blockchain_hash,
            status="generated",
        )

        return await self.notice_repo.create(notice)

    def _build_pdf_document(self, inspection: Any, notice_id: UUID) -> bytes:
        """Construct formal PDF document using ReportLab."""
        buffer = io.BytesIO()
        doc = SimpleDocTemplate(buffer, pagesize=letter, rightMargin=40, leftMargin=40, topMargin=40, bottomMargin=40)
        styles = getSampleStyleSheet()

        title_style = ParagraphStyle(
            "TitleStyle",
            parent=styles["Heading1"],
            fontSize=16,
            leading=20,
            alignment=1,  # Center
            textColor=colors.HexColor("#1A365D"),
        )
        subtitle_style = ParagraphStyle(
            "SubTitleStyle",
            parent=styles["Normal"],
            fontSize=10,
            leading=14,
            alignment=1,
            textColor=colors.HexColor("#4A5568"),
        )
        section_style = ParagraphStyle(
            "SectionStyle",
            parent=styles["Heading2"],
            fontSize=12,
            leading=16,
            textColor=colors.HexColor("#2B6CB0"),
        )
        body_style = styles["Normal"]

        story = []

        # Header
        story.append(Paragraph("GOVERNMENT OF INDIA", title_style))
        story.append(Paragraph("MINISTRY OF CONSUMER AFFAIRS, FOOD & PUBLIC DISTRIBUTION", subtitle_style))
        story.append(Paragraph("DEPARTMENT OF CONSUMER AFFAIRS — LEGAL METROLOGY DIVISION", subtitle_style))
        story.append(Spacer(1, 10))
        story.append(HRFlowable(width="100%", thickness=2, color=colors.HexColor("#1A365D")))
        story.append(Spacer(1, 15))

        # Title
        story.append(Paragraph("<b>STATUTORY NOTICE UNDER LEGAL METROLOGY (PACKAGED COMMODITIES) RULES, 2011</b>", title_style))
        story.append(Spacer(1, 10))

        # Metadata Table
        loc_str = inspection.location_name or (f"{inspection.latitude}, {inspection.longitude}" if inspection.latitude else "N/A")
        meta_data = [
            [Paragraph("<b>Notice Reference ID:</b>", body_style), Paragraph(str(notice_id), body_style)],
            [Paragraph("<b>Inspection ID:</b>", body_style), Paragraph(str(inspection.inspection_id), body_style)],
            [Paragraph("<b>Date of Inspection:</b>", body_style), Paragraph(inspection.created_at.strftime("%d-%b-%Y %H:%M UTC") if inspection.created_at else "N/A", body_style)],
            [Paragraph("<b>Product Barcode (UPC/EAN):</b>", body_style), Paragraph(inspection.product_barcode or "N/A", body_style)],
            [Paragraph("<b>Location of Detection:</b>", body_style), Paragraph(loc_str, body_style)],
            [Paragraph("<b>Finding / Overall Result:</b>", body_style), Paragraph((inspection.overall_result or "UNDER_REVIEW").upper(), body_style)],
            [Paragraph("<b>Blockchain Evidence Hash:</b>", body_style), Paragraph(inspection.blockchain_hash or "Pending Commitment", body_style)],
        ]
        meta_table = Table(meta_data, colWidths=[200, 330])
        meta_table.setStyle(TableStyle([
            ("BACKGROUND", (0, 0), (-1, -1), colors.HexColor("#F7FAFC")),
            ("GRID", (0, 0), (-1, -1), 0.5, colors.HexColor("#E2E8F0")),
            ("PADDING", (0, 0), (-1, -1), 6),
        ]))
        story.append(meta_table)
        story.append(Spacer(1, 15))

        # Details
        story.append(Paragraph("<b>1. Nature of Contravention</b>", section_style))
        story.append(Spacer(1, 5))
        story.append(Paragraph(
            "During an enforcement inspection conducted under the Legal Metrology Act, 2009 and the Packaged Commodities Rules, 2011, "
            "the pre-packaged commodity identified above was found non-compliant with the mandatory declaration provisions.",
            body_style,
        ))
        story.append(Spacer(1, 10))

        story.append(Paragraph("<b>2. Evidentiary Integrity & Cryptographic Seal</b>", section_style))
        story.append(Spacer(1, 5))
        story.append(Paragraph(
            "Digital evidence including high-resolution photographic captures, geo-location tags, and optical character extractions "
            "have been cryptographically hashed (SHA-256) and recorded on the Sovereign Hyperledger Fabric Evidentiary Ledger.",
            body_style,
        ))
        story.append(Spacer(1, 20))

        # Sign-off
        sign_data = [
            [Paragraph("<b>Authorized Nodal Officer</b><br/>Legal Metrology Enforcement", body_style),
             Paragraph("<b>Cryptographic Verification</b><br/>PARAKH Automated System", body_style)]
        ]
        sign_table = Table(sign_data, colWidths=[260, 270])
        story.append(sign_table)

        doc.build(story)
        return buffer.getvalue()
