"""
Project PARAKH — Legal Notices Router

Implements §9 & §26:
Generate and retrieve statutory PDF legal notices based on actual inspection data.
"""

from uuid import UUID

from fastapi import APIRouter, Depends, Request
from fastapi.responses import Response
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_food_inspector, get_current_user
from app.audit.logger import AuditService
from app.core.exceptions import NotFoundError
from app.core.responses import success_response
from app.db.postgres import get_db
from app.models.user import User
from app.schemas.legal_notice import LegalNoticeGenerateRequest, LegalNoticeResponse
from app.services.legal_notice_service import LegalNoticeService
from app.storage import get_storage_backend

router = APIRouter(prefix="/legal-notices", tags=["Legal Notices"])


@router.post("/generate", dependencies=[Depends(get_current_food_inspector)])
async def generate_legal_notice(
    request: Request,
    payload: LegalNoticeGenerateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Generate statutory PDF legal notice embedding violation data & blockchain seal."""
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


@router.get("/{notice_id}")
async def get_legal_notice(
    notice_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Retrieve metadata of a generated legal notice."""
    service = LegalNoticeService(db)
    notice = await service.get_by_id(notice_id)
    return success_response(data=LegalNoticeResponse.model_validate(notice).model_dump())


@router.get("/{notice_id}/download")
async def download_legal_notice_pdf(
    notice_id: UUID,
    current_user: User = Depends(get_current_user),
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


@router.get("/download/{identifier}")
async def download_notice_by_identifier(
    identifier: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Download raw PDF by notice_id or inspection_id (auto-generates if not yet created)."""
    service = LegalNoticeService(db)
    storage = get_storage_backend()

    try:
        parsed_id = UUID(identifier)
    except ValueError:
        from fastapi import HTTPException
        raise HTTPException(status_code=400, detail="Invalid UUID identifier")

    try:
        notice = await service.get_by_id(parsed_id)
    except NotFoundError:
        notices = await service.get_by_inspection(parsed_id)
        if notices:
            notice = notices[0]
        else:
            notice = await service.generate_notice(parsed_id, current_user.user_id)

    pdf_bytes = await storage.download_file(notice.pdf_storage_path)
    return Response(
        content=pdf_bytes,
        media_type="application/pdf",
        headers={"Content-Disposition": f"attachment; filename=Notice_{notice.notice_id}.pdf"},
    )
