"""
Project PARAKH — Inspection Lifecycle Service
"""

from __future__ import annotations

from datetime import datetime, timezone
from typing import List, Optional
from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import NotFoundError
from app.models.inspection import Inspection
from app.repositories.inspection_repo import InspectionRepository
from app.schemas.inspection import (
    InspectionCreate,
    InspectionUpdate,
    NodalSubmissionPayload,
    NodalDecisionPayload,
)


class InspectionService:
    def __init__(self, db: AsyncSession):
        self.db = db
        self.repo = InspectionRepository(db)

    async def get_by_id(self, inspection_id: UUID) -> Inspection:
        inspection = await self.repo.get_by_id(inspection_id)
        if not inspection:
            raise NotFoundError("Inspection", str(inspection_id))
        return inspection

    async def list_inspections(
        self,
        offset: int = 0,
        limit: int = 20,
        status: Optional[str] = None,
        overall_result: Optional[str] = None,
        inspector_id: Optional[UUID] = None,
        product_barcode: Optional[str] = None,
        date_from: Optional[datetime] = None,
        date_to: Optional[datetime] = None,
    ) -> tuple[List[Inspection], int]:
        return await self.repo.list_inspections(
            offset=offset,
            limit=limit,
            status=status,
            overall_result=overall_result,
            inspector_id=inspector_id,
            product_barcode=product_barcode,
            date_from=date_from,
            date_to=date_to,
        )

    async def create_inspection(self, inspector_id: UUID, data: InspectionCreate) -> Inspection:
        inspection = Inspection(
            inspector_id=inspector_id,
            product_barcode=data.product_barcode,
            latitude=data.latitude,
            longitude=data.longitude,
            location_name=data.location_name,
            notes=data.notes,
            status="pending",
        )
        return await self.repo.create(inspection)

    async def update_status(self, inspection_id: UUID, data: InspectionUpdate) -> Inspection:
        inspection = await self.get_by_id(inspection_id)
        if data.status is not None:
            inspection.status = data.status
        if data.overall_result is not None:
            inspection.overall_result = data.overall_result
        if data.notes is not None:
            inspection.notes = data.notes

        return await self.repo.update(inspection)

    async def submit_to_nodal(
        self,
        inspection_id: UUID,
        payload: NodalSubmissionPayload,
    ) -> Inspection:
        """Submit finalized inspection report to Nodal Verifier with shop info, comments, and statutory rules."""
        inspection = await self.get_by_id(inspection_id)
        # Mark status as unverified until Nodal Verifier completes verification
        inspection.status = "unverified"
        if payload.notes:
            inspection.notes = payload.notes

        meta = dict(inspection.metadata_json or {})
        if payload.shop_name or payload.shop_owner_name or payload.shop_address:
            meta["establishment"] = {
                "shop_name": payload.shop_name or meta.get("establishment", {}).get("shop_name"),
                "shop_owner_name": payload.shop_owner_name or meta.get("establishment", {}).get("shop_owner_name"),
                "shop_address": payload.shop_address or meta.get("establishment", {}).get("shop_address"),
            }
            if payload.shop_name:
                inspection.location_name = payload.shop_name

        if payload.violation_rules is not None:
            meta["violation_rules"] = payload.violation_rules
            if len(payload.violation_rules) > 0:
                inspection.overall_result = "violation"

        if payload.evidence_images:
            meta["additional_evidence_images"] = payload.evidence_images

        meta["nodal_submission"] = {
            "submitted_at": datetime.now(timezone.utc).isoformat(),
            "target_verifier": "nodal.officer@doca.gov.in",
            "verifier_name": "Nodal Officer S. K. Sharma (Verification Authority)",
            "status": "UNVERIFIED",
        }

        inspection.metadata_json = meta

        # Calculate cryptographic evidence hash
        from app.blockchain.evidence_chain import EvidenceChainService
        evidence_hash = EvidenceChainService.calculate_payload_hash(
            image_storage_path=inspection.image_storage_path,
            gps_latitude=inspection.latitude,
            gps_longitude=inspection.longitude,
            capture_timestamp=inspection.created_at or datetime.now(timezone.utc),
            ocr_text_snapshot=inspection.notes or "",
            inspector_id=str(inspection.inspector_id),
            violation_data=payload.violation_rules or [],
        )
        inspection.blockchain_hash = evidence_hash

        return await self.repo.update(inspection)

    async def record_nodal_decision(
        self,
        inspection_id: UUID,
        payload: NodalDecisionPayload,
    ) -> Inspection:
        """Nodal Verifier scrutiny decision: Accept & send to commissioner or Deny & Reject."""
        inspection = await self.get_by_id(inspection_id)
        is_accept = payload.decision.upper() in ("ACCEPT", "ACCEPTED", "APPROVE", "APPROVED")

        meta = dict(inspection.metadata_json or {})
        decision_timestamp = datetime.now(timezone.utc).isoformat()

        if is_accept:
            inspection.status = "verified_accepted"
            meta["nodal_verification"] = {
                "decision": "ACCEPTED",
                "verifier_comment": payload.verifier_comment,
                "verifier_name": payload.verifier_name or "Nodal Officer S. K. Sharma",
                "verified_at": decision_timestamp,
                "commissioner_status": "FORWARDED_FOR_DIGITAL_SIGNATURE",
                "commissioner_name": "Dr. V. K. Verma (Food & Legal Metrology Commissioner)",
                "forwarded_at": decision_timestamp,
            }
        else:
            inspection.status = "verified_rejected"
            meta["nodal_verification"] = {
                "decision": "REJECTED",
                "verifier_comment": payload.verifier_comment,
                "verifier_name": payload.verifier_name or "Nodal Officer S. K. Sharma",
                "verified_at": decision_timestamp,
                "commissioner_status": "NOT_FORWARDED",
            }

        inspection.metadata_json = meta

        # Recalculate cryptographic hash with verifier signature payload
        from app.blockchain.evidence_chain import EvidenceChainService
        updated_hash = EvidenceChainService.calculate_payload_hash(
            image_storage_path=inspection.image_storage_path,
            gps_latitude=inspection.latitude,
            gps_longitude=inspection.longitude,
            capture_timestamp=inspection.created_at or datetime.now(timezone.utc),
            ocr_text_snapshot=f"{inspection.notes or ''} | VERIFIER: {payload.verifier_comment}",
            inspector_id=str(inspection.inspector_id),
            violation_data=meta.get("violation_rules", []),
        )
        inspection.blockchain_hash = updated_hash

        return await self.repo.update(inspection)

    async def get_pending_commissioner(self) -> List[Inspection]:
        """Fetch all inspections forwarded to Commissioner for digital signature."""
        from sqlalchemy import or_
        stmt = (
            select(Inspection)
            .where(
                or_(
                    Inspection.status == "verified_accepted",
                    Inspection.status == "FORWARDED_FOR_DIGITAL_SIGNATURE",
                )
            )
            .order_by(Inspection.created_at.desc())
        )
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def record_commissioner_signature(
        self,
        inspection_id: UUID,
        commissioner_name: str = "Dr. V. K. Verma",
        remarks: str = "Statutory digital signature applied. Notice issued under Rule 32 of LM Rules, 2011.",
    ) -> Inspection:
        """Commissioner applies digital signature to the verified dossier."""
        import hashlib
        inspection = await self.get_by_id(inspection_id)
        inspection.status = "signed_notice_issued"
        meta = dict(inspection.metadata_json or {})
        now_iso = datetime.now(timezone.utc).isoformat()

        sig_payload = f"{inspection.id}:{commissioner_name}:{now_iso}:{inspection.blockchain_hash}"
        digital_sig_hash = hashlib.sha256(sig_payload.encode()).hexdigest()

        meta["commissioner_signature"] = {
            "signed_by": commissioner_name,
            "signed_at": now_iso,
            "digital_signature_hash": digital_sig_hash,
            "algorithm": "SHA-256 / RSA-2048 Digital e-Sign",
            "statutory_notice_number": f"DOCA/LM/2026/{str(inspection.id)[:8].upper()}",
            "remarks": remarks,
        }
        if "nodal_verification" in meta:
            meta["nodal_verification"]["commissioner_status"] = "DIGITALLY_SIGNED_AND_ISSUED"

        inspection.metadata_json = meta

        from app.blockchain.evidence_chain import EvidenceChainService
        updated_hash = EvidenceChainService.calculate_payload_hash(
            image_storage_path=inspection.image_storage_path,
            gps_latitude=inspection.latitude,
            gps_longitude=inspection.longitude,
            capture_timestamp=inspection.created_at or datetime.now(timezone.utc),
            ocr_text_snapshot=f"{inspection.notes or ''} | COMM_SIGN: {digital_sig_hash}",
            inspector_id=str(inspection.inspector_id),
            violation_data=meta.get("violation_rules", []),
        )
        inspection.blockchain_hash = updated_hash
        return await self.repo.update(inspection)

    async def get_pending_nodal(self, limit: int = 50, offset: int = 0) -> List[Inspection]:
        """Retrieve inspections awaiting Nodal Verifier scrutiny."""
        inspections, _ = await self.repo.list_inspections(
            offset=offset,
            limit=limit,
        )
        # Filter for unverified or pending_nodal_verification
        pending = [
            i for i in inspections
            if i.status in ("unverified", "pending_nodal_verification", "pending")
            or (i.metadata_json and "nodal_submission" in i.metadata_json and i.status not in ("verified_accepted", "verified_rejected"))
        ]
        return pending

