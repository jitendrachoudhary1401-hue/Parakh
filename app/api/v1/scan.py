"""
Project PARAKH — Scan & Image Upload Router

Implements §8:
POST /api/v1/scan/upload — Receive product inspection images securely.
"""

from __future__ import annotations

from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Depends, File, Form, Request, UploadFile
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_inspector
from app.audit.logger import AuditService
from app.core.rate_limiter import limiter
from app.core.responses import success_response
from app.db.postgres import get_db
from app.services.scan_service import ScanService

router = APIRouter(prefix="/scan", tags=["Scan & Upload"])


@router.post("/upload")
@limiter.limit("20/minute")
async def upload_inspection_image(
    request: Request,
    file: UploadFile = File(..., description="Product packaging photo"),
    product_barcode: Optional[str] = Form(None),
    latitude: Optional[float] = Form(None),
    longitude: Optional[float] = Form(None),
    location_name: Optional[str] = Form(None),
    notes: Optional[str] = Form(None),
    user_payload: dict = Depends(get_current_inspector),
    db: AsyncSession = Depends(get_db),
):
    """
    Receive product inspection image, validate MIME/integrity, store in object storage,
    and initialize an inspection entity.
    """
    file_bytes = await file.read()
    inspector_id = UUID(user_payload["sub"])

    scan_service = ScanService(db)
    inspection = await scan_service.handle_image_upload(
        inspector_id=inspector_id,
        file_bytes=file_bytes,
        filename=file.filename or "upload.jpg",
        product_barcode=product_barcode,
        latitude=latitude,
        longitude=longitude,
        location_name=location_name,
        notes=notes,
    )

    # Audit log
    audit = AuditService(db)
    await audit.log_event(
        action="INSPECTION_IMAGE_UPLOADED",
        user_id=inspector_id,
        user_email=user_payload.get("email"),
        user_role=user_payload.get("role"),
        resource_type="inspection",
        resource_id=str(inspection.inspection_id),
        details={"barcode": product_barcode, "storage_path": inspection.image_storage_path},
        ip_address=request.client.host if request.client else None,
    )

    return success_response(
        data={
            "inspection_id": inspection.inspection_id,
            "image_storage_path": inspection.image_storage_path,
            "status": inspection.status,
            "product_barcode": inspection.product_barcode,
        },
        message="Inspection image received and verified",
        status_code=201,
    )
