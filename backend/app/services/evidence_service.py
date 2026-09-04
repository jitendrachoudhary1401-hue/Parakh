"""
Project PARAKH — Evidence Management Service

Implements §8, §23, §24, §25:
Commit verified violation evidence to Hyperledger Fabric, store SHA-256 hashes, verify tamper-proofing.
"""

from __future__ import annotations

import logging
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional
from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession

from app.blockchain.evidence_chain import EvidenceChainService
from app.blockchain.verifier import EvidenceVerifier
from app.core.exceptions import NotFoundError
from app.models.evidence import Evidence
from app.repositories.evidence_repo import EvidenceRepository
from app.repositories.inspection_repo import InspectionRepository
from app.schemas.evidence import EvidenceCommitRequest

logger = logging.getLogger("parakh.services.evidence")


class EvidenceService:
    def __init__(self, db: AsyncSession):
        self.db = db
        self.evidence_repo = EvidenceRepository(db)
        self.inspection_repo = InspectionRepository(db)
        self.chain_service = EvidenceChainService()
        self.verifier = EvidenceVerifier(chain_service=self.chain_service)

    async def get_by_id(self, evidence_id: UUID) -> Evidence:
        evidence = await self.evidence_repo.get_by_id(evidence_id)
        if not evidence:
            raise NotFoundError("Evidence record", str(evidence_id))
        return evidence

    async def get_by_inspection(self, inspection_id: UUID) -> List[Evidence]:
        return await self.evidence_repo.get_by_inspection(inspection_id)

    async def commit_evidence(
        self,
        inspector_id: UUID,
        data: EvidenceCommitRequest,
    ) -> Evidence:
        """Construct evidence payload, compute SHA-256, commit to Hyperledger Fabric."""
        inspection = await self.inspection_repo.get_by_id(data.inspection_id)
        if not inspection:
            raise NotFoundError("Inspection", str(data.inspection_id))

        capture_time = data.capture_timestamp or inspection.created_at
        img_path = data.image_storage_path or inspection.image_storage_path
        lat = data.gps_latitude if data.gps_latitude is not None else inspection.latitude
        lon = data.gps_longitude if data.gps_longitude is not None else inspection.longitude

        # Compute SHA-256
        payload_hash = self.chain_service.calculate_payload_hash(
            image_storage_path=img_path,
            gps_latitude=lat,
            gps_longitude=lon,
            capture_timestamp=capture_time,
            ocr_text_snapshot=data.ocr_text_snapshot,
            inspector_id=str(inspector_id),
            violation_data=data.violation_data,
        )

        # Create local evidence entity
        evidence = Evidence(
            inspection_id=data.inspection_id,
            inspector_id=inspector_id,
            payload_hash=payload_hash,
            image_storage_path=img_path,
            gps_latitude=lat,
            gps_longitude=lon,
            capture_timestamp=capture_time,
            ocr_text_snapshot=data.ocr_text_snapshot,
            violation_data=data.violation_data,
            blockchain_status="pending",
        )
        saved_evidence = await self.evidence_repo.create(evidence)

        # Commit to Hyperledger Fabric
        tx_result = await self.chain_service.commit_evidence(
            evidence_id=str(saved_evidence.evidence_id),
            payload_hash=payload_hash,
            metadata={
                "inspection_id": str(data.inspection_id),
                "timestamp": capture_time.isoformat(),
                "inspector_id": str(inspector_id),
            },
        )

        if tx_result.success:
            saved_evidence.blockchain_status = "committed"
            saved_evidence.blockchain_tx_id = tx_result.tx_id
            saved_evidence.blockchain_receipt = tx_result.receipt
            # Also update inspection with blockchain hash
            inspection.blockchain_hash = payload_hash
            inspection.blockchain_tx_id = tx_result.tx_id
            await self.inspection_repo.update(inspection)
        else:
            saved_evidence.blockchain_status = tx_result.status
            logger.warning("Blockchain commitment result for %s: %s", saved_evidence.evidence_id, tx_result.status)

        return await self.evidence_repo.update(saved_evidence)

    async def verify_evidence(
        self, evidence_id: UUID, verified_by_user_id: Optional[UUID] = None,
    ) -> Dict[str, Any]:
        """Verify evidence payload against its SHA-256 hash and ledger receipt."""
        evidence = await self.get_by_id(evidence_id)
        result = await self.verifier.verify(evidence)

        evidence.verification_status = result["status"].lower()
        evidence.last_verified_at = datetime.now(timezone.utc)
        if verified_by_user_id:
            evidence.verified_by_user_id = verified_by_user_id
        await self.evidence_repo.update(evidence)

        result["evidence_id"] = evidence_id
        result["verified_by_user_id"] = verified_by_user_id
        return result
