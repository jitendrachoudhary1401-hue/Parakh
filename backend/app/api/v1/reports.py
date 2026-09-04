from __future__ import annotations

from typing import List, Optional
from uuid import UUID

from fastapi import APIRouter, Body, Depends, Request
from fastapi.responses import Response
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.audit.logger import AuditService
from app.core.responses import success_response
from app.db.postgres import get_db
from app.models.user import User
from app.schemas.report import (
    ReportCreateRequest,
    ReportResponse,
    ReportSubmitToNodalRequest,
    ReportNodalReviewRequest,
    ReportCommissionerCertifyRequest,
)
from app.services.report_service import ReportService
from app.storage import get_storage_backend

router = APIRouter(prefix="/reports", tags=["Reports & Dossiers"])


@router.post("/generate")
async def generate_report(
    request: Request,
    payload: ReportCreateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Generate statutory report with SHA-256 cryptographic file hash."""
    service = ReportService(db)
    report = await service.generate_report(
        inspection_id=payload.inspection_id,
        generated_by_user_id=current_user.user_id,
        report_type=payload.report_type or "LEGAL_SHOW_CAUSE",
    )

    audit = AuditService(db)
    await audit.log_event(
        action="REPORT_GENERATED",
        user_id=current_user.user_id,
        user_email=current_user.email,
        user_role=current_user.role,
        resource_type="report",
        resource_id=str(report.report_id),
        details={"inspection_id": str(payload.inspection_id), "file_hash": report.file_hash},
        ip_address=request.client.host if request.client else None,
    )

    return success_response(
        data=ReportResponse.model_validate(report).model_dump(),
        message="Official statutory report generated successfully",
        status_code=201,
    )


@router.post("/create-or-get/{inspection_id}")
async def create_or_get_report(
    inspection_id: UUID,
    payload: Optional[ReportSubmitToNodalRequest] = None,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Generate or retrieve inspection report for inspector review."""
    service = ReportService(db)
    report = await service.create_or_get_report(
        inspection_id=inspection_id,
        generated_by_user_id=current_user.user_id,
        inspector_notes=payload.inspector_notes if payload else None,
    )
    return success_response(
        data=ReportResponse.model_validate(report).model_dump(),
        message="Report generated / loaded successfully",
    )


@router.post("/{report_id}/submit-to-nodal")
async def submit_to_nodal(
    report_id: UUID,
    payload: Optional[ReportSubmitToNodalRequest] = Body(default=None),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Stage 1: Food Inspector sends report to Nodal Officer for verification."""
    service = ReportService(db)
    report = await service.submit_to_nodal(
        report_id=report_id,
        inspector_user_id=current_user.user_id,
        inspector_notes=payload.effective_notes if payload else None,
    )
    return success_response(
        data=ReportResponse.model_validate(report).model_dump(),
        message="Report successfully submitted to Nodal Officer for statutory verification",
    )


@router.get("/queue/nodal")
async def get_nodal_queue(
    limit: int = 50,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Stage 2 Queue: Reports awaiting Nodal Officer review."""
    service = ReportService(db)
    reports = await service.get_pending_nodal_queue(limit=limit)
    data = [ReportResponse.model_validate(r).model_dump() for r in reports]
    return success_response(data=data)


@router.post("/{report_id}/nodal-forward")
async def nodal_forward(
    report_id: UUID,
    payload: Optional[ReportNodalReviewRequest] = Body(default=None),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Stage 2: Nodal Officer reviews evidence, attaches comments, and forwards to Commissioner."""
    service = ReportService(db)
    report = await service.nodal_review_and_forward(
        report_id=report_id,
        nodal_officer_id=current_user.user_id,
        nodal_comments=payload.effective_comments if payload else "",
    )
    return success_response(
        data=ReportResponse.model_validate(report).model_dump(),
        message="Report reviewed by Nodal Officer and forwarded to Food Safety Commissioner for certification",
    )


@router.get("/queue/commissioner")
async def get_commissioner_queue(
    limit: int = 50,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Stage 3 Queue: Reports awaiting Food Safety Commissioner certification & digital signature."""
    service = ReportService(db)
    reports = await service.get_pending_commissioner_queue(limit=limit)
    data = [ReportResponse.model_validate(r).model_dump() for r in reports]
    return success_response(data=data)


@router.post("/{report_id}/certify")
async def certify_report(
    report_id: UUID,
    payload: Optional[ReportCommissionerCertifyRequest] = Body(default=None),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Stage 3: Food Safety Commissioner certifies and digitally signs the statutory report."""
    service = ReportService(db)
    report = await service.commissioner_certify_and_sign(
        report_id=report_id,
        commissioner_id=current_user.user_id,
        commissioner_comments=payload.effective_comments if payload else None,
    )
    return success_response(
        data=ReportResponse.model_validate(report).model_dump(),
        message="Report certified and digitally signed by Food Safety Commissioner",
    )


@router.get("/{report_id}/pdf")
async def download_report_pdf(
    report_id: UUID,
    db: AsyncSession = Depends(get_db),
):
    """Download official PDF report bearing all 3 tier sign-offs and digital signatures."""
    service = ReportService(db)
    pdf_bytes = await service.get_report_pdf_bytes(report_id)
    return Response(
        content=pdf_bytes,
        media_type="application/pdf",
        headers={
            "Content-Disposition": f'attachment; filename="Statutory_Report_{report_id}.pdf"',
        },
    )


@router.get("/")
async def list_reports(
    limit: int = 50,
    offset: int = 0,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """List generated statutory reports and notices."""
    service = ReportService(db)
    reports = await service.list_reports(limit=limit, offset=offset)
    data = [ReportResponse.model_validate(r).model_dump() for r in reports]
    return success_response(data=data)


@router.get("/{report_id}")
async def get_report_detail(
    report_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Retrieve metadata of a specific report."""
    service = ReportService(db)
    report = await service.get_by_id(report_id)
    return success_response(data=ReportResponse.model_validate(report).model_dump())

