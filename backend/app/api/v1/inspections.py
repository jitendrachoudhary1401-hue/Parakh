"""
Project PARAKH — Inspection Lifecycle Router

Implements §9:
Create, retrieve, search, filter, update authorized status, and history.
"""

from datetime import datetime
from typing import Any, Dict, List, Optional
from uuid import UUID

from fastapi import APIRouter, Body, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_admin, get_current_inspector, get_current_nodal_officer, get_current_user
from app.core.responses import paginated_response, success_response
from app.db.postgres import get_db
from app.models.user import User
from app.schemas.inspection import (
    InspectionCreate,
    InspectionResponse,
    InspectionSummary,
    InspectionUpdate,
    NodalSubmissionPayload,
    NodalDecisionPayload,
)
from app.services.inspection_service import InspectionService

router = APIRouter(prefix="/inspections", tags=["Inspections"])


@router.get("/")
async def list_inspections(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    status: Optional[str] = None,
    overall_result: Optional[str] = None,
    product_barcode: Optional[str] = None,
    date_from: Optional[datetime] = None,
    date_to: Optional[datetime] = None,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """List and filter inspections. Inspectors see own or zone records; Admins see all."""
    service = InspectionService(db)
    offset = (page - 1) * page_size
    inspector_filter = current_user.user_id if current_user.role == "inspector" else None

    inspections, total = await service.list_inspections(
        offset=offset,
        limit=page_size,
        status=status,
        overall_result=overall_result,
        inspector_id=inspector_filter,
        product_barcode=product_barcode,
        date_from=date_from,
        date_to=date_to,
    )

    data = [InspectionResponse.model_validate(i).model_dump() for i in inspections]
    return paginated_response(data=data, total=total, page=page, page_size=page_size)


@router.post("/", dependencies=[Depends(get_current_inspector)])
async def create_inspection(
    payload: InspectionCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Create a new manual inspection record."""
    service = InspectionService(db)
    created = await service.create_inspection(current_user.user_id, payload)
    return success_response(
        data=InspectionResponse.model_validate(created).model_dump(),
        message="Inspection created successfully",
        status_code=201,
    )


@router.get("/pending-nodal", dependencies=[Depends(get_current_nodal_officer)])
async def get_pending_nodal_inspections(
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Nodal Verifier: List all dossiers awaiting statutory verification scrutiny."""
    service = InspectionService(db)
    offset = (page - 1) * page_size
    pending = await service.get_pending_nodal(limit=page_size, offset=offset)
    return success_response(
        data=[InspectionResponse.model_validate(i).model_dump() for i in pending],
        message=f"Retrieved {len(pending)} pending dossiers for Nodal scrutiny",
    )


@router.get("/{inspection_id}")
async def get_inspection(
    inspection_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get detailed inspection metadata and findings."""
    service = InspectionService(db)
    inspection = await service.get_by_id(inspection_id)
    return success_response(data=InspectionResponse.model_validate(inspection).model_dump())


@router.patch("/{inspection_id}/status", dependencies=[Depends(get_current_admin)])
async def update_inspection_status(
    inspection_id: UUID,
    payload: InspectionUpdate,
    db: AsyncSession = Depends(get_db),
):
    """Admin-only: update inspection status or override determination."""
    service = InspectionService(db)
    updated = await service.update_status(inspection_id, payload)
    return success_response(
        data=InspectionResponse.model_validate(updated).model_dump(),
        message="Inspection updated successfully",
    )


@router.patch("/{inspection_id}/comment", dependencies=[Depends(get_current_inspector)])
async def update_inspection_comment(
    inspection_id: UUID,
    payload: InspectionUpdate,
    db: AsyncSession = Depends(get_db),
):
    """Inspector: update/append notes & comments for an inspection."""
    service = InspectionService(db)
    updated = await service.update_status(inspection_id, payload)
    return success_response(
        data=InspectionResponse.model_validate(updated).model_dump(),
        message="Comment updated successfully",
    )


@router.post("/{inspection_id}/submit-nodal", dependencies=[Depends(get_current_inspector)])
async def submit_inspection_to_nodal(
    inspection_id: UUID,
    payload: NodalSubmissionPayload,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Inspector: Transmit finalized inspection dossier (shop details, remarks, evidence photos,
    statutory violation rules) to Nodal Verifier queue for legal scrutiny.
    """
    service = InspectionService(db)
    updated = await service.submit_to_nodal(inspection_id, payload)
    return success_response(
        data=InspectionResponse.model_validate(updated).model_dump(),
        message="Inspection dossier successfully transmitted to Nodal Verification Authority (S. K. Sharma)",
    )


@router.post("/{inspection_id}/nodal-decision", dependencies=[Depends(get_current_nodal_officer)])
async def record_nodal_decision(
    inspection_id: UUID,
    payload: NodalDecisionPayload,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Nodal Verifier: Record statutory scrutiny decision.
    - Accept and forward to Commissioner for digital signature
    - Deny and Reject
    Requires verifier comments.
    """
    service = InspectionService(db)
    updated = await service.record_nodal_decision(inspection_id, payload)
    is_accept = payload.decision.upper() in ("ACCEPT", "ACCEPTED", "APPROVE", "APPROVED")
    decision_verb = "accepted and forwarded to Commissioner for digital signature" if is_accept else "rejected"
    return success_response(
        data=InspectionResponse.model_validate(updated).model_dump(),
        message=f"Dossier successfully {decision_verb} by Nodal Verifier",
    )


@router.get("/pending-commissioner")
async def get_pending_commissioner(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """List all dossiers forwarded to Commissioner for digital signature."""
    service = InspectionService(db)
    items = await service.get_pending_commissioner()
    return success_response(
        data=[InspectionResponse.model_validate(i).model_dump() for i in items],
        message=f"Found {len(items)} dossiers awaiting Commissioner digital signature",
    )


@router.post("/{inspection_id}/commissioner-sign")
async def record_commissioner_signature(
    inspection_id: UUID,
    payload: Optional[Dict[str, Any]] = Body(default=None),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Commissioner: Apply digital e-Signature and issue statutory enforcement notice."""
    service = InspectionService(db)
    comm_name = (payload or {}).get("commissioner_name") or current_user.full_name or "Dr. V. K. Verma"
    remarks = (payload or {}).get("remarks") or "Digital signature applied. Statutory legal notice issued under Rule 32 of LM Rules, 2011."
    updated = await service.record_commissioner_signature(
        inspection_id=inspection_id,
        commissioner_name=comm_name,
        remarks=remarks,
    )
    return success_response(
        data=InspectionResponse.model_validate(updated).model_dump(),
        message="Statutory digital signature applied successfully. Notice issued.",
    )


@router.get("/{inspection_id}/export/pdf")
async def export_inspection_pdf(
    inspection_id: UUID,
    db: AsyncSession = Depends(get_db),
):
    """Generate and return formal PDF Legal Metrology Compliance Notice / Certificate."""
    from fastapi.responses import Response
    from app.services.legal_notice_service import LegalNoticeService
    import uuid

    service = InspectionService(db)
    inspection = await service.get_by_id(inspection_id)
    notice_service = LegalNoticeService(db)
    pdf_bytes = notice_service._build_pdf_document(inspection, uuid.uuid4())

    return Response(
        content=pdf_bytes,
        media_type="application/pdf",
        headers={
            "Content-Disposition": f'attachment; filename="LEGAL_NOTICE_{inspection_id}.pdf"'
        },
    )


@router.get("/{inspection_id}/export/json")
async def export_inspection_json(
    inspection_id: UUID,
    db: AsyncSession = Depends(get_db),
):
    """Export complete statutory inspection dossier in editable JSON format."""
    from fastapi.responses import JSONResponse

    service = InspectionService(db)
    inspection = await service.get_by_id(inspection_id)
    data = InspectionResponse.model_validate(inspection).model_dump()
    return JSONResponse(
        content=data,
        headers={
            "Content-Disposition": f'attachment; filename="DOSSIER_{inspection_id}.json"'
        },
    )


@router.get("/{inspection_id}/export/csv")
async def export_inspection_csv(
    inspection_id: UUID,
    db: AsyncSession = Depends(get_db),
):
    """Export statutory inspection record in editable CSV format."""
    from fastapi.responses import Response
    import csv
    import io

    service = InspectionService(db)
    inspection = await service.get_by_id(inspection_id)
    data = InspectionResponse.model_validate(inspection).model_dump()

    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow(["Field", "Value"])
    for key, val in data.items():
        writer.writerow([key, str(val)])

    return Response(
        content=output.getvalue(),
        media_type="text/csv",
        headers={
            "Content-Disposition": f'attachment; filename="DOSSIER_{inspection_id}.csv"'
        },
    )


