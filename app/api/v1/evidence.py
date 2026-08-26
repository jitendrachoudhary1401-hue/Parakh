"""
Project PARAKH — Evidence Management Router

Implements §8, §23, §24, §25:
Commit evidence to Hyperledger Fabric, retrieve cryptographic receipts, and verify evidence integrity.
"""

from typing import List
from uuid import UUID

from fastapi import APIRouter, Depends, Request
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_admin, get_current_inspector, get_current_user
from app.audit.logger import AuditService
from app.core.rate_limiter import limiter
from app.core.responses import success_response
from app.db.postgres import get_db
from app.models.user import User
from app.schemas.evidence import EvidenceCommitRequest, EvidenceResponse, EvidenceVerifyResponse
from app.services.evidence_service import EvidenceService

router = APIRouter(prefix="/evidence", tags=["Evidence & Blockchain"])


@router.post("/commit", dependencies=[Depends(get_current_inspector)])
@limiter.limit("10/minute")
async def commit_evidence(
    request: Request,
    payload: EvidenceCommitRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Construct evidentiary package, compute SHA-256 hash, and commit to Hyperledger Fabric.
    """
    service = EvidenceService(db)
    evidence = await service.commit_evidence(
        inspector_id=current_user.user_id,
        data=payload,
    )

    # Audit log
    audit = AuditService(db)
    await audit.log_event(
        action="EVIDENCE_COMMITTED_TO_BLOCKCHAIN",
        user_id=current_user.user_id,
        user_email=current_user.email,
        user_role=current_user.role,
        resource_type="evidence",
        resource_id=str(evidence.evidence_id),
        details={"payload_hash": evidence.payload_hash, "blockchain_status": evidence.blockchain_status},
        ip_address=request.client.host if request.client else None,
    )

    return success_response(
        data=EvidenceResponse.model_validate(evidence).model_dump(),
        message="Evidence hashed and dispatched to ledger",
        status_code=201,
    )


@router.get("/inspection/{inspection_id}")
async def get_inspection_evidence(
    inspection_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Retrieve all evidence records associated with an inspection."""
    service = EvidenceService(db)
    records = await service.get_by_inspection(inspection_id)
    data = [EvidenceResponse.model_validate(r).model_dump() for r in records]
    return success_response(data=data)


@router.get("/{evidence_id}")
async def get_evidence_detail(
    evidence_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Retrieve a single evidence record and its cryptographic metadata."""
    service = EvidenceService(db)
    evidence = await service.get_by_id(evidence_id)
    return success_response(data=EvidenceResponse.model_validate(evidence).model_dump())


@router.post("/{evidence_id}/verify", dependencies=[Depends(get_current_admin)])
async def verify_evidence_integrity(
    evidence_id: UUID,
    request: Request,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Verify evidence mathematical integrity:
    Stored evidence -> Recalculate SHA-256 -> Compare with ledger hash.
    """
    service = EvidenceService(db)
    verification = await service.verify_evidence(evidence_id)

    # Audit log
    audit = AuditService(db)
    await audit.log_event(
        action="EVIDENCE_INTEGRITY_VERIFIED",
        user_id=current_user.user_id,
        user_email=current_user.email,
        user_role=current_user.role,
        resource_type="evidence",
        resource_id=str(evidence_id),
        details={"status": verification["status"]},
        ip_address=request.client.host if request.client else None,
    )

    return success_response(
        data=verification,
        message=f"Evidence verification result: {verification['status']}",
    )
