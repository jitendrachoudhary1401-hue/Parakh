"""
Project PARAKH — Legal Notices Router

Implements §9 & §26:
Generate and retrieve statutory PDF legal notices based on actual inspection data.
"""

from __future__ import annotations

from uuid import UUID

from fastapi import APIRouter, Depends, Request
from fastapi.responses import Response
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_admin, get_current_user
from app.audit.logger import AuditService
from app.core.responses import success_response
from app.db.postgres import get_db
from app.models.user import User
from app.schemas.legal_notice import LegalNoticeGenerateRequest, LegalNoticeResponse
from app.services.legal_notice_service import LegalNoticeService
from app.storage import get_storage_backend

router = APIRouter(prefix="/legal-notices", tags=["Legal Notices"])


@router.post("/generate", dependencies=[Depends(get_current_admin)])
async def generate_legal_notice(
    request: Request,
    payload: LegalNoticeGenerateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Admin-only: generate statutory PDF legal notice embedding violation data & blockchain seal."""
    service = LegalNoticeService(db)
    notice = await service.generate_notice(payload.inspection_id, current_user.user_id)

    # Audit log
    audit = AuditService(db)
    await audit.log_event(
        action="LEGAL_NOTICE_GENERATED",
        user_id=current_user.user_id,
        user_email=current_user.email,
        user_role=current_user.role,
        resource_type="legal_notice",
        resource_id=str(notice.notice_id),
        details={"inspection_id": str(payload.inspection_id)},
        ip_address=request.client.host if request.client else None,
    )

    return success_response(
        data=LegalNoticeResponse.model_validate(notice).model_dump(),
        message="Statutory PDF notice generated successfully",
        status_code=201,
    )


@router.get("/{notice_id}", dependencies=[Depends(get_current_admin)])
async def get_legal_notice(
    notice_id: UUID,
    db: AsyncSession = Depends(get_db),
):
    """Retrieve metadata of a generated legal notice."""
    service = LegalNoticeService(db)
    notice = await service.get_by_id(notice_id)
    return success_response(data=LegalNoticeResponse.model_validate(notice).model_dump())


@router.get("/{notice_id}/download", dependencies=[Depends(get_current_admin)])
async def download_legal_notice_pdf(
    notice_id: UUID,
    db: AsyncSession = Depends(get_db),
):
    """Download the raw PDF binary of a generated legal notice."""
    service = LegalNoticeService(db)
    notice = await service.get_by_id(notice_id)
    storage = get_storage_backend()
    pdf_bytes = await storage.download_file(notice.pdf_storage_path)

    return Response(
        content=pdf_bytes,
        media_type="application/pdf",
        headers={"Content-Disposition": f"attachment; filename=Notice_{notice_id}.pdf"},
    )
