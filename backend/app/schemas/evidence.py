"""
Project PARAKH — Evidence Schemas
"""

from __future__ import annotations

from datetime import datetime
from typing import Any, Dict, Optional
from uuid import UUID

from pydantic import BaseModel, Field


class EvidenceCommitRequest(BaseModel):
    """Request to commit evidence to blockchain."""
    inspection_id: UUID
    image_storage_path: Optional[str] = None
    gps_latitude: Optional[float] = Field(None, ge=-90, le=90)
    gps_longitude: Optional[float] = Field(None, ge=-180, le=180)
    capture_timestamp: Optional[datetime] = None
    ocr_text_snapshot: Optional[str] = None
    violation_data: Optional[Dict[str, Any]] = None


class EvidenceResponse(BaseModel):
    """Evidence record response."""
    evidence_id: UUID
    inspection_id: UUID
    inspector_id: UUID
    payload_hash: str
    blockchain_status: str  # pending, committed, failed, unavailable
    blockchain_tx_id: Optional[str] = None
    verification_status: str  # unverified, verified, mismatch
    image_storage_path: Optional[str] = None
    gps_latitude: Optional[float] = None
    gps_longitude: Optional[float] = None
    capture_timestamp: Optional[datetime] = None
    last_verified_at: Optional[datetime] = None
    verified_by_user_id: Optional[UUID] = None
    created_at: datetime

    model_config = {"from_attributes": True}


class EvidenceVerifyResponse(BaseModel):
    """Evidence integrity verification result per §25."""
    evidence_id: UUID
    status: str  # VERIFIED, MISMATCH, UNAVAILABLE
    stored_hash: str
    recalculated_hash: str
    ledger_hash: Optional[str] = None
    verified_by_user_id: Optional[UUID] = None
    message: str
