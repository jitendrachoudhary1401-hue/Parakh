"""
Project PARAKH — Hyperledger Fabric Blockchain Client Adapter

Handles connection to Hyperledger Fabric network per §24.
Never fabricates transaction IDs or blockchain receipts.
If Hyperledger is disabled or unavailable, returns structured service unavailable status.
"""

from __future__ import annotations

import logging
from dataclasses import dataclass
from typing import Any, Dict, Optional

from app.config import get_settings

logger = logging.getLogger("parakh.blockchain.fabric")


@dataclass
class BlockchainTxResult:
    success: bool
    status: str  # "committed", "failed", "BLOCKCHAIN_SERVICE_UNAVAILABLE"
    tx_id: Optional[str] = None
    receipt: Optional[Dict[str, Any]] = None
    error_message: Optional[str] = None


class FabricClient:
    """Hyperledger Fabric client adapter."""

    def __init__(self):
        self.settings = get_settings()
        self.enabled = self.settings.blockchain_enabled
        self.endpoint = self.settings.blockchain_endpoint
        self.channel = self.settings.blockchain_channel
        self.chaincode = self.settings.blockchain_chaincode

    async def commit_evidence_hash(
        self,
        evidence_id: str,
        payload_hash: str,
        metadata: Dict[str, Any],
    ) -> BlockchainTxResult:
        """
        Commit SHA-256 evidence hash and metadata to Hyperledger Fabric.

        Args:
            evidence_id: Unique evidence identifier
            payload_hash: SHA-256 hash of evidentiary package
            metadata: Associated non-PII verification metadata
        """
        if not self.enabled:
            logger.info("Blockchain commitment skipped: BLOCKCHAIN_ENABLED=false")
            return BlockchainTxResult(
                success=False,
                status="BLOCKCHAIN_SERVICE_UNAVAILABLE",
                error_message="Hyperledger Fabric integration is currently disabled in configuration",
            )

        try:
            # When Fabric SDK is configured with MSP and peer certs:
            # Here we connect to the peer endpoint, invoke chaincode function 'RecordEvidence'
            # In live production environment, invokes the hfc Python SDK:
            # client = hfc.fabric_ca.caservice.FabricCAService(...)
            # response = await channel.send_transaction(...)
            
            logger.info(
                "Submitting evidence hash %s to channel %s / chaincode %s",
                payload_hash, self.channel, self.chaincode,
            )

            # Check network connection: if peer is unreachable, return unavailable
            # (No mock / fake receipt generation!)
            import httpx
            # If endpoint is an HTTP/gRPC gateway or REST proxy for Fabric:
            if self.endpoint.startswith("http"):
                async with httpx.AsyncClient(timeout=10.0) as http_client:
                    resp = await http_client.post(
                        f"{self.endpoint}/channels/{self.channel}/chaincodes/{self.chaincode}",
                        json={
                            "fcn": "RecordEvidence",
                            "args": [evidence_id, payload_hash, str(metadata)],
                        },
                    )
                    if resp.status_code == 200:
                        data = resp.json()
                        return BlockchainTxResult(
                            success=True,
                            status="committed",
                            tx_id=data.get("transaction_id"),
                            receipt=data,
                        )
                    else:
                        return BlockchainTxResult(
                            success=False,
                            status="failed",
                            error_message=f"Fabric node responded with HTTP {resp.status_code}: {resp.text}",
                        )
            
            # If gRPC direct endpoint is configured but not responsive:
            return BlockchainTxResult(
                success=False,
                status="BLOCKCHAIN_SERVICE_UNAVAILABLE",
                error_message=f"Cannot establish connection to Hyperledger Fabric peer at {self.endpoint}",
            )

        except Exception as exc:
            logger.exception("Hyperledger Fabric transaction error: %s", exc)
            return BlockchainTxResult(
                success=False,
                status="BLOCKCHAIN_SERVICE_UNAVAILABLE",
                error_message=f"Blockchain service error: {str(exc)}",
            )

    async def query_evidence_hash(self, evidence_id: str) -> Optional[Dict[str, Any]]:
        """Query ledger for a previously committed evidence hash."""
        if not self.enabled:
            return None

        try:
            if self.endpoint.startswith("http"):
                import httpx
                async with httpx.AsyncClient(timeout=10.0) as http_client:
                    resp = await http_client.get(
                        f"{self.endpoint}/channels/{self.channel}/chaincodes/{self.chaincode}?args={evidence_id}"
                    )
                    if resp.status_code == 200:
                        return resp.json()
            return None
        except Exception as exc:
            logger.error("Failed to query Hyperledger Fabric: %s", exc)
            return None
