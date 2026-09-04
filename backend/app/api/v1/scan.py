"""
Project PARAKH — Scan, OCR & Barcode Router

Implements §8 & §18:
- POST /api/v1/scan/upload — Receive product inspection images securely.
- GET /api/v1/scan/barcode/{gtin} — Query Open Food Facts registry for product/manufacturer lookup.
- POST /api/v1/scan/ocr — Execute Google Cloud Vision API on uploaded product label image.
"""

from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Depends, File, Form, HTTPException, Request, UploadFile
from sqlalchemy.ext.asyncio import AsyncSession

from app.ai.ocr_engine import OCREngine
from app.api.deps import get_current_inspector
from app.audit.logger import AuditService
from app.core.rate_limiter import limiter
from app.core.responses import success_response
from app.db.postgres import get_db
from app.integrations.openfoodfacts_client import OpenFoodFactsClient
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
    shop_name: Optional[str] = Form(None),
    shop_owner_name: Optional[str] = Form(None),
    shop_address: Optional[str] = Form(None),
    user_payload: dict = Depends(get_current_inspector),
    db: AsyncSession = Depends(get_db),
):
    """
    Receive product inspection image, validate MIME/integrity, store in object storage,
    and initialize an inspection entity with shop details.
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
        location_name=shop_name or location_name,
        notes=notes,
        shop_name=shop_name,
        shop_owner_name=shop_owner_name,
        shop_address=shop_address,
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


@router.get("/barcode/{gtin}")
@limiter.limit("30/minute")
async def lookup_barcode_info(
    request: Request,
    gtin: str,
):
    """
    Query Open Food Facts database for GTIN/EAN barcode product information.
    """
    off_client = OpenFoodFactsClient()
    lookup = await off_client.lookup_barcode(gtin)

    return success_response(
        data={
            "gtin": lookup.barcode,
            "status": lookup.status,
            "registered_manufacturer": lookup.registered_manufacturer,
            "manufacturer_address": lookup.manufacturer_address,
            "product_name": lookup.product_name,
            "product_category": lookup.product_category,
            "brand": lookup.brand,
            "quantity": lookup.quantity,
            "ingredients_text": lookup.ingredients_text,
            "image_url": lookup.image_url,
            "country_of_origin": lookup.country_of_origin,
            "error_message": lookup.error_message,
        },
        message="Open Food Facts barcode lookup completed",
    )


@router.post("/ocr")
@limiter.limit("15/minute")
async def process_ocr_image(
    request: Request,
    file: UploadFile = File(..., description="Image file to execute Cloud Vision OCR"),
    user_payload: dict = Depends(get_current_inspector),
):
    """
    Execute Google Cloud Vision OCR engine directly on an uploaded image file.
    """
    file_bytes = await file.read()
    if not file_bytes:
        raise HTTPException(status_code=400, detail="Empty image file provided")

    ocr_engine = OCREngine()
    result = await ocr_engine.extract_text(file_bytes)

    return success_response(
        data={
            "success": result.success,
            "raw_text": result.raw_text,
            "language": result.language,
            "confidence": result.confidence,
            "word_count": len(result.words),
            "paragraph_count": len(result.paragraphs),
            "words": [
                {
                    "text": w.text,
                    "confidence": w.confidence,
                    "bbox": {
                        "x": w.bounding_box.x,
                        "y": w.bounding_box.y,
                        "width": w.bounding_box.width,
                        "height": w.bounding_box.height,
                    } if w.bounding_box else None,
                }
                for w in result.words
            ],
            "error_message": result.error_message,
        },
        message="Google Cloud Vision OCR processing completed",
    )
