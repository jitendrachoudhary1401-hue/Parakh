"""
Project PARAKH — Evidence Packaging & Blockchain Commitment Service

Implements §23 & §24:
Payload = {Image S3 URL, GPS, Timestamp, OCR Text Data, Inspector ID, Violation Data}
Generate SHA-256 → Commit to Hyperledger Fabric.
"""

from __future__ import annotations

import hashlib
import json
import logging
from datetime import datetime, timezone
from typing import Any, Dict, Optional
from uuid import UUID

from app.blockchain.fabric_client import FabricClient, BlockchainTxResult

logger = logging.getLogger("parakh.blockchain.evidence_chain")


class EvidenceChainService:
    """Service to create SHA-256 hashed evidence packages and commit to ledger."""

    def __init__(self, fabric_client: Optional[FabricClient] = None):
        self.fabric_client = fabric_client or FabricClient()

    @staticmethod
    def calculate_payload_hash(
        image_storage_path: Optional[str],
        gps_latitude: Optional[float],
        gps_longitude: Optional[float],
        capture_timestamp: Optional[datetime],
        ocr_text_snapshot: Optional[str],
        inspector_id: str,
        violation_data: Optional[Dict[str, Any]],
    ) -> str:
        """
        Compute deterministic SHA-256 hash of evidentiary components.
        """
        ts_str = capture_timestamp.isoformat() if capture_timestamp else ""
        lat_str = f"{gps_latitude:.6f}" if gps_latitude is not None else ""
        lon_str = f"{gps_longitude:.6f}" if gps_longitude is not None else ""
        v_str = json.dumps(violation_data, sort_keys=True) if violation_data else ""
        
        canonical_string = (
            f"IMAGE:{image_storage_path or ''}|"
            f"GPS:{lat_str},{lon_str}|"
            f"TIME:{ts_str}|"
            f"INSPECTOR:{inspector_id}|"
            f"OCR:{ocr_text_snapshot or ''}|"
            f"VIOLATIONS:{v_str}"
        )

        return hashlib.sha256(canonical_string.encode("utf-8")).hexdigest()

    async def commit_evidence(
        self,
        evidence_id: str,
        payload_hash: str,
        metadata: Dict[str, Any],
    ) -> BlockchainTxResult:
        """Commit evidence hash to Hyperledger Fabric."""
        return await self.fabric_client.commit_evidence_hash(
            evidence_id=evidence_id,
            payload_hash=payload_hash,
            metadata=metadata,
        )
