"""
Project PARAKH — Compliance Analysis Router

Implements §8 & §19:
POST /api/v1/analysis/verify-compliance — Execute AI vision pipeline and rule engine.
"""

from uuid import UUID

from fastapi import APIRouter, Depends, Request
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_inspector
from app.audit.logger import AuditService
from app.core.rate_limiter import limiter
from app.core.responses import success_response
from app.db.postgres import get_db
from app.schemas.analysis import AnalysisRequest
from app.services.analysis_service import AnalysisService

router = APIRouter(prefix="/analysis", tags=["Compliance Analysis"])


@router.post("/verify-compliance")
@limiter.limit("10/minute")
async def verify_compliance(
    request: Request,
    payload: AnalysisRequest,
    user_payload: dict = Depends(get_current_inspector),
    db: AsyncSession = Depends(get_db),
):
    """
    Trigger full AI vision processing (Unwarping -> OCR -> NLP)
    and evaluate against Legal Metrology Compliance Rules.
    """
    analysis_service = AnalysisService(db)
    result = await analysis_service.verify_compliance(
        inspection_id=payload.inspection_id,
        product_barcode=payload.product_barcode,
    )

    # Audit log
    audit = AuditService(db)
    await audit.log_event(
        action="COMPLIANCE_ANALYSIS_EXECUTED",
        user_id=UUID(user_payload["sub"]),
        user_email=user_payload.get("email"),
        user_role=user_payload.get("role"),
        resource_type="inspection",
        resource_id=str(payload.inspection_id),
        details={"overall_status": result["overall_status"], "requires_review": result["requires_human_review"]},
        ip_address=request.client.host if request.client else None,
    )

    return success_response(
        data=result,
        message=f"Compliance check completed: {result['overall_status']}",
    )
