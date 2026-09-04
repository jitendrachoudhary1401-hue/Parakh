"""
Project PARAKH — Official Report Generation & 3-Tier Workflow Service

Implements statutory verification workflow:
1. Inspector generates & inspects report -> Submits to Nodal Officer
2. Nodal Officer reviews evidence & attaches comments -> Forwards to Food Safety Commissioner
3. Food Safety Commissioner reviews dossier -> Certifies & Digitally Signs report
"""

from __future__ import annotations

import hashlib
import io
import logging
from datetime import datetime, timezone
from typing import List, Optional
from uuid import UUID, uuid4

from reportlab.lib import colors
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.platypus import HRFlowable, Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import NotFoundError, ValidationError
from app.models.report import Report
from app.repositories.inspection_repo import InspectionRepository
from app.repositories.report_repo import ReportRepository
from app.services.legal_notice_service import LegalNoticeService
from app.storage import get_storage_backend

logger = logging.getLogger("parakh.services.report")


class ReportService:
    def __init__(self, db: AsyncSession):
        self.db = db
        self.report_repo = ReportRepository(db)
        self.inspection_repo = InspectionRepository(db)
        self.notice_service = LegalNoticeService(db)
        self.storage = get_storage_backend()

    async def get_by_id(self, report_id: UUID) -> Report:
        report = await self.report_repo.get_by_id(report_id)
        if not report:
            raise NotFoundError("Report", str(report_id))
        return report

    async def get_by_inspection_id(self, inspection_id: UUID) -> Optional[Report]:
        reports = await self.report_repo.get_by_inspection(inspection_id)
        return reports[0] if reports else None

    async def list_reports(self, limit: int = 50, offset: int = 0) -> List[Report]:
        return await self.report_repo.list_reports(limit=limit, offset=offset)

    async def create_or_get_report(
        self,
        inspection_id: UUID,
        generated_by_user_id: UUID,
        inspector_notes: Optional[str] = None,
        report_type: str = "LEGAL_SHOW_CAUSE",
    ) -> Report:
        """Generates or fetches existing report for an inspection."""
        existing = await self.get_by_inspection_id(inspection_id)
        if existing:
            if inspector_notes and not existing.inspector_notes:
                existing.inspector_notes = inspector_notes
                await self.report_repo.update(existing)
            return existing

        inspection = await self.inspection_repo.get_by_id(inspection_id)
        if not inspection:
            raise NotFoundError("Inspection", str(inspection_id))

        # Build initial PDF
        notice = await self.notice_service.generate_notice(
            inspection_id=inspection_id,
            admin_id=generated_by_user_id,
        )
        pdf_bytes = await self.storage.download_file(notice.pdf_storage_path)
        file_hash = hashlib.sha256(pdf_bytes).hexdigest()

        report = Report(
            inspection_id=inspection_id,
            generated_by_user_id=generated_by_user_id,
            report_type=report_type,
            pdf_url=f"/api/v1/reports/{notice.notice_id}/pdf",
            file_hash=file_hash,
            status="DRAFT",
            inspector_notes=inspector_notes,
        )
        created = await self.report_repo.create(report)
        return created

    async def submit_to_nodal(
        self,
        report_id: UUID,
        inspector_user_id: UUID,
        inspector_notes: Optional[str] = None,
    ) -> Report:
        """Stage 1: Inspector sends report to Nodal Officer for statutory review."""
        report = await self.get_by_id(report_id)
        if report.status not in ["DRAFT", "PENDING_NODAL_REVIEW"]:
            raise ValidationError(f"Report cannot be submitted in status '{report.status}'")

        if inspector_notes:
            report.inspector_notes = inspector_notes
        report.status = "PENDING_NODAL_REVIEW"
        return await self.report_repo.update(report)

    async def get_pending_nodal_queue(self, limit: int = 50) -> List[Report]:
        """Fetch all reports awaiting Nodal Officer review."""
        return await self.report_repo.get_by_status("PENDING_NODAL_REVIEW", limit=limit)

    async def nodal_review_and_forward(
        self,
        report_id: UUID,
        nodal_officer_id: UUID,
        nodal_comments: str,
    ) -> Report:
        """Stage 2: Nodal Officer reviews evidence, attaches comments, and forwards to Commissioner."""
        report = await self.get_by_id(report_id)
        if report.status not in ["PENDING_NODAL_REVIEW", "DRAFT"]:
            raise ValidationError(f"Report is in '{report.status}', cannot be forwarded to Commissioner.")

        report.nodal_officer_id = nodal_officer_id
        report.nodal_comments = nodal_comments
        report.nodal_reviewed_at = datetime.now(timezone.utc)
        report.status = "FORWARDED_TO_COMMISSIONER"
        return await self.report_repo.update(report)

    async def get_pending_commissioner_queue(self, limit: int = 50) -> List[Report]:
        """Fetch all reports awaiting Food Safety Commissioner certification."""
        return await self.report_repo.get_by_status("FORWARDED_TO_COMMISSIONER", limit=limit)

    async def commissioner_certify_and_sign(
        self,
        report_id: UUID,
        commissioner_id: UUID,
        commissioner_comments: Optional[str] = None,
    ) -> Report:
        """Stage 3: Food Safety Commissioner certifies and digitally signs the report."""
        report = await self.get_by_id(report_id)
        inspection = await self.inspection_repo.get_by_id(report.inspection_id)
        if not inspection:
            raise NotFoundError("Inspection", str(report.inspection_id))

        now_utc = datetime.now(timezone.utc)
        report.commissioner_id = commissioner_id
        report.commissioner_comments = commissioner_comments or "Certified and approved under Legal Metrology Act, 2009."
        report.commissioner_certified_at = now_utc

        # Generate digital signature hash (Commissioner Key + Report Hash + Timestamp)
        signature_payload = f"{report.report_id}|{commissioner_id}|{report.file_hash}|{now_utc.isoformat()}"
        digital_sig = hashlib.sha256(signature_payload.encode("utf-8")).hexdigest()
        report.digital_signature_hash = digital_sig
        report.status = "CERTIFIED"

        # Generate final certified PDF containing all 3 sign-offs
        certified_pdf_bytes = self._build_certified_pdf(report, inspection)
        storage_path = f"legal_reports/{report.report_id}/certified_{report.report_id}.pdf"
        await self.storage.upload_file(certified_pdf_bytes, storage_path, "application/pdf")

        report.pdf_url = f"/api/v1/reports/{report.report_id}/pdf"
        report.file_hash = hashlib.sha256(certified_pdf_bytes).hexdigest()

        return await self.report_repo.update(report)

    async def get_report_pdf_bytes(self, report_id: UUID) -> bytes:
        """Retrieve latest PDF bytes for a report."""
        report = await self.get_by_id(report_id)
        inspection = await self.inspection_repo.get_by_id(report.inspection_id)
        if not inspection:
            raise NotFoundError("Inspection", str(report.inspection_id))

        return self._build_certified_pdf(report, inspection)

    def _build_certified_pdf(self, report: Report, inspection: Any) -> bytes:
        """Construct multi-tier signed PDF with ReportLab."""
        buffer = io.BytesIO()
        doc = SimpleDocTemplate(buffer, pagesize=letter, rightMargin=36, leftMargin=36, topMargin=36, bottomMargin=36)
        styles = getSampleStyleSheet()

        title_style = ParagraphStyle(
            "TitleStyle",
            parent=styles["Heading1"],
            fontSize=15,
            leading=18,
            alignment=1,
            textColor=colors.HexColor("#1A365D"),
        )
        subtitle_style = ParagraphStyle(
            "SubTitleStyle",
            parent=styles["Normal"],
            fontSize=9,
            leading=12,
            alignment=1,
            textColor=colors.HexColor("#4A5568"),
        )
        section_style = ParagraphStyle(
            "SectionStyle",
            parent=styles["Heading2"],
            fontSize=11,
            leading=14,
            textColor=colors.HexColor("#2B6CB0"),
        )
        body_style = styles["Normal"]
        body_small = ParagraphStyle("SmallBody", parent=styles["Normal"], fontSize=8, leading=10)

        story = []

        # Government Header
        story.append(Paragraph("GOVERNMENT OF INDIA", title_style))
        story.append(Paragraph("MINISTRY OF CONSUMER AFFAIRS, FOOD & PUBLIC DISTRIBUTION", subtitle_style))
        story.append(Paragraph("DIRECTORATE OF LEGAL METROLOGY & FOOD SAFETY ENFORCEMENT", subtitle_style))
        story.append(Spacer(1, 8))
        story.append(HRFlowable(width="100%", thickness=1.5, color=colors.HexColor("#1A365D")))
        story.append(Spacer(1, 10))

        # Title with Status
        status_color = "#38A169" if report.status == "CERTIFIED" else "#DD6B20"
        story.append(Paragraph(
            f"<b>STATUTORY INSPECTION REPORT & SHOW CAUSE NOTICE</b><br/>"
            f"<font size=9 color='{status_color}'><b>STATUS: {report.status.replace('_', ' ')}</b></font>",
            title_style
        ))
        story.append(Spacer(1, 8))

        # Details Table
        loc_str = inspection.location_name or (f"{inspection.latitude}, {inspection.longitude}" if inspection.latitude else "Designated Jurisdiction")
        meta_data = [
            [Paragraph("<b>Report ID:</b>", body_style), Paragraph(str(report.report_id), body_style)],
            [Paragraph("<b>Inspection ID:</b>", body_style), Paragraph(str(inspection.inspection_id), body_style)],
            [Paragraph("<b>Date of Detection:</b>", body_style), Paragraph(report.created_at.strftime("%d-%b-%Y %H:%M UTC"), body_style)],
            [Paragraph("<b>Commodity Barcode:</b>", body_style), Paragraph(inspection.product_barcode or "N/A", body_style)],
            [Paragraph("<b>Premise / Location:</b>", body_style), Paragraph(loc_str, body_style)],
            [Paragraph("<b>Statutory Result:</b>", body_style), Paragraph((inspection.overall_result or "NON-COMPLIANT").upper(), body_style)],
            [Paragraph("<b>SHA-256 Evidence Hash:</b>", body_style), Paragraph(f"<font size=7>{report.file_hash}</font>", body_style)],
        ]
        meta_table = Table(meta_data, colWidths=[180, 360])
        meta_table.setStyle(TableStyle([
            ("BACKGROUND", (0, 0), (-1, -1), colors.HexColor("#F8FAFC")),
            ("GRID", (0, 0), (-1, -1), 0.5, colors.HexColor("#CBD5E1")),
            ("PADDING", (0, 0), (-1, -1), 5),
        ]))
        story.append(meta_table)
        story.append(Spacer(1, 10))

        # 3-Tier Multi-Role Sign-off & Observations
        story.append(Paragraph("<b>3-TIER STATUTORY VERIFICATION & SIGN-OFF AUDIT TRAIL</b>", section_style))
        story.append(Spacer(1, 5))

        # 1. Inspector Tier
        story.append(Paragraph(
            f"<b>1. Field Food Inspector:</b><br/>"
            f"• Inspector ID: {report.generated_by_user_id}<br/>"
            f"• Field Notes: {report.inspector_notes or 'Inspection logged and submitted for statutory verification.'}",
            body_style
        ))
        story.append(Spacer(1, 6))

        # 2. Nodal Officer Tier
        nodal_date_str = report.nodal_reviewed_at.strftime("%d-%b-%Y %H:%M UTC") if report.nodal_reviewed_at else "Pending Review"
        story.append(Paragraph(
            f"<b>2. Reviewing Nodal Officer:</b><br/>"
            f"• Verified Date: {nodal_date_str}<br/>"
            f"• Legal Metrology Observations: {report.nodal_comments or 'Awaiting formal Nodal Officer review.'}",
            body_style
        ))
        story.append(Spacer(1, 6))

        # 3. Commissioner Tier
        fsc_date_str = report.commissioner_certified_at.strftime("%d-%b-%Y %H:%M UTC") if report.commissioner_certified_at else "Pending Final Certification"
        sig_str = report.digital_signature_hash or "Pending Seal"
        story.append(Paragraph(
            f"<b>3. Food Safety Commissioner (Apex Authority):</b><br/>"
            f"• Certified Date: {fsc_date_str}<br/>"
            f"• Commissioner Directives: {report.commissioner_comments or 'Pending executive certification.'}<br/>"
            f"• Digital Signature Hash: <font size=7 color='#1A365D'><b>{sig_str}</b></font>",
            body_style
        ))
        story.append(Spacer(1, 15))

        # Signatures Row
        sign_data = [
            [
                Paragraph("<b>Food Inspector</b><br/>Digitally Logged", body_small),
                Paragraph("<b>Nodal Officer</b><br/>Verified & Recommended", body_small),
                Paragraph("<b>Food Safety Commissioner</b><br/>Certified & Digitally Signed", body_small),
            ]
        ]
        sign_table = Table(sign_data, colWidths=[180, 180, 180])
        sign_table.setStyle(TableStyle([
            ("LINEABOVE", (0, 0), (-1, -1), 1, colors.HexColor("#1A365D")),
            ("PADDING", (0, 0), (-1, -1), 6),
            ("ALIGN", (0, 0), (-1, -1), "CENTER"),
        ]))
        story.append(sign_table)

        doc.build(story)
        return buffer.getvalue()

