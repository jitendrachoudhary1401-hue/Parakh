"""
Project PARAKH — Legal Notice Schemas
"""

from __future__ import annotations

from datetime import datetime
from typing import Any, Dict, List, Optional
from uuid import UUID

from pydantic import BaseModel


class LegalNoticeGenerateRequest(BaseModel):
    """Request to generate a legal notice from inspection data."""
    inspection_id: UUID


class LegalNoticeResponse(BaseModel):
    """Legal notice detail."""
    notice_id: UUID
    inspection_id: UUID
    generated_by: UUID
    pdf_storage_path: Optional[str] = None
    product_info: Optional[Dict[str, Any]] = None
    violations: Optional[Dict[str, Any]] = None
    compliance_results: Optional[Dict[str, Any]] = None
    evidence_references: Optional[Dict[str, Any]] = None
    inspector_name: Optional[str] = None
    inspection_location: Optional[str] = None
    blockchain_receipt: Optional[str] = None
    status: str
    generated_at: datetime
    served_at: Optional[datetime] = None

    model_config = {"from_attributes": True}
