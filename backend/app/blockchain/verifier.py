"""
Project PARAKH — Evidence Verification Service

Implements §25:
Stored evidence → Recalculate SHA-256 → Compare with ledger hash → Return VERIFIED, MISMATCH, UNAVAILABLE.
"""

from __future__ import annotations

import logging
from typing import Any, Dict, Optional

from app.blockchain.evidence_chain import EvidenceChainService
from app.blockchain.fabric_client import FabricClient
from app.models.evidence import Evidence

logger = logging.getLogger("parakh.blockchain.verifier")


class EvidenceVerifier:
    """Service to mathematically verify evidence integrity."""

    def __init__(
        self,
        chain_service: Optional[EvidenceChainService] = None,
        fabric_client: Optional[FabricClient] = None,
    ):
        self.chain_service = chain_service or EvidenceChainService()
        self.fabric_client = fabric_client or FabricClient()

    async def verify(self, evidence: Evidence) -> Dict[str, Any]:
        """
        Verify the integrity of a stored evidence record against its recalculation
        and the immutable Hyperledger Fabric ledger.
        """
        recalculated_hash = self.chain_service.calculate_payload_hash(
            image_storage_path=evidence.image_storage_path,
            gps_latitude=evidence.gps_latitude,
            gps_longitude=evidence.gps_longitude,
            capture_timestamp=evidence.capture_timestamp,
            ocr_text_snapshot=evidence.ocr_text_snapshot,
            inspector_id=str(evidence.inspector_id),
            violation_data=evidence.violation_data,
        )

        stored_hash = evidence.payload_hash

        # Step 1: Internal integrity check (stored payload vs recalculated hash)
        if recalculated_hash != stored_hash:
            logger.warning(
                "Evidence mismatch detected for evidence_id %s: stored=%s, recalc=%s",
                evidence.evidence_id, stored_hash, recalculated_hash,
            )
            return {
                "status": "MISMATCH",
                "stored_hash": stored_hash,
                "recalculated_hash": recalculated_hash,
                "ledger_hash": None,
                "message": "Cryptographic mismatch! Stored evidence payload data does not match the initial hash.",
            }

        # Step 2: Query Hyperledger Fabric if available
        ledger_data = await self.fabric_client.query_evidence_hash(str(evidence.evidence_id))
        ledger_hash = ledger_data.get("payload_hash") if ledger_data else None

        if ledger_hash:
            if ledger_hash == stored_hash:
                return {
                    "status": "VERIFIED",
                    "stored_hash": stored_hash,
                    "recalculated_hash": recalculated_hash,
                    "ledger_hash": ledger_hash,
                    "message": "Evidence verified! Stored hash matches both recalculation and Hyperledger Fabric ledger receipt.",
                }
            else:
                return {
                    "status": "MISMATCH",
                    "stored_hash": stored_hash,
                    "recalculated_hash": recalculated_hash,
                    "ledger_hash": ledger_hash,
                    "message": "Ledger mismatch! Stored record does not match Hyperledger Fabric ledger record.",
                }

        # If blockchain is disabled or record was not anchored
        if evidence.blockchain_status == "committed":
            return {
                "status": "UNAVAILABLE",
                "stored_hash": stored_hash,
                "recalculated_hash": recalculated_hash,
                "ledger_hash": None,
                "message": "Local payload integrity verified, but Hyperledger Fabric is currently unreachable for ledger verification.",
            }

        return {
            "status": "VERIFIED",
            "stored_hash": stored_hash,
            "recalculated_hash": recalculated_hash,
            "ledger_hash": None,
            "message": "Local evidence payload integrity successfully verified via SHA-256 recalculation.",
        }
