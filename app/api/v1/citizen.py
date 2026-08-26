"""
Project PARAKH — Citizen Crowdsourcing Router

Implements §9 & §30:
Submit reports, retrieve triage status, and administrative triage actions.
"""

from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Depends, File, Form, Query, Request, UploadFile
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_admin, get_current_user
from app.audit.logger import AuditService
from app.core.rate_limiter import limiter
from app.core.responses import paginated_response, success_response
from app.db.postgres import get_db
from app.models.user import User
from app.schemas.citizen import (
    CitizenReportResponse,
    CitizenReportStatus,
    CitizenReportTriageRequest,
)
from app.services.citizen_service import CitizenService

router = APIRouter(prefix="/citizen", tags=["Citizen Crowdsourcing"])


@router.post("/reports")
@limiter.limit("5/minute")
async def submit_citizen_report(
    request: Request,
    file: UploadFile = File(..., description="Photograph of non-compliant packaging"),
    description: Optional[str] = Form(None),
    product_barcode: Optional[str] = Form(None),
    latitude: Optional[float] = Form(None),
    longitude: Optional[float] = Form(None),
    location_name: Optional[str] = Form(None),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Citizen submission: upload packaging image, trigger automatic AI triage, and log complaint.
    """
    file_bytes = await file.read()
    service = CitizenService(db)
    report = await service.submit_report(
        citizen_id=current_user.user_id,
        file_bytes=file_bytes,
        filename=file.filename or "report.jpg",
        description=description,
        product_barcode=product_barcode,
        latitude=latitude,
        longitude=longitude,
        location_name=location_name,
        source="app",
    )

    # Audit log
    audit = AuditService(db)
    await audit.log_event(
        action="CITIZEN_REPORT_SUBMITTED",
        user_id=current_user.user_id,
        user_email=current_user.email,
        user_role=current_user.role,
        resource_type="citizen_report",
        resource_id=str(report.report_id),
        details={"ai_triage_status": report.ai_triage_status},
        ip_address=request.client.host if request.client else None,
    )

    return success_response(
        data=CitizenReportResponse.model_validate(report).model_dump(),
        message="Report submitted and triaged successfully",
        status_code=201,
    )


@router.get("/reports")
async def list_reports(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    admin_decision: Optional[str] = None,
    ai_triage_status: Optional[str] = None,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """List citizen reports. Citizens see own; Admins see triage console."""
    service = CitizenService(db)
    offset = (page - 1) * page_size
    citizen_filter = current_user.user_id if current_user.role == "citizen" else None

    reports, total = await service.list_reports(
        offset=offset,
        limit=page_size,
        citizen_id=citizen_filter,
        admin_decision=admin_decision,
        ai_triage_status=ai_triage_status,
    )
    data = [CitizenReportResponse.model_validate(r).model_dump() for r in reports]
    return paginated_response(data=data, total=total, page=page, page_size=page_size)


@router.get("/reports/{report_id}/status")
async def get_report_status(
    report_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Retrieve tracking status for a citizen report."""
    service = CitizenService(db)
    report = await service.get_by_id(report_id)
    return success_response(data=CitizenReportStatus.model_validate(report).model_dump())


@router.put("/reports/{report_id}/triage", dependencies=[Depends(get_current_admin)])
async def admin_triage_report(
    report_id: UUID,
    payload: CitizenReportTriageRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Admin-only: review citizen report and approve, reject, or assign for investigation."""
    service = CitizenService(db)
    updated = await service.triage_report(
        report_id=report_id,
        admin_id=current_user.user_id,
        decision=payload.decision,
        notes=payload.notes,
    )

    # Audit log
    audit = AuditService(db)
    await audit.log_event(
        action="CITIZEN_REPORT_TRIAGED",
        user_id=current_user.user_id,
        user_email=current_user.email,
        user_role=current_user.role,
        resource_type="citizen_report",
        resource_id=str(report_id),
        details={"decision": payload.decision},
    )

    return success_response(
        data=CitizenReportResponse.model_validate(updated).model_dump(),
        message=f"Report marked as {payload.decision}",
    )
