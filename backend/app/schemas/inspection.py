"""
Project PARAKH — Inspection Schemas
"""

from __future__ import annotations

from datetime import datetime
from typing import Any, Dict, List, Optional
from uuid import UUID

from pydantic import BaseModel, Field


class InspectionCreate(BaseModel):
    """Create an inspection record."""
    product_barcode: Optional[str] = None
    latitude: Optional[float] = Field(None, ge=-90, le=90)
    longitude: Optional[float] = Field(None, ge=-180, le=180)
    location_name: Optional[str] = None
    notes: Optional[str] = None


class InspectionUpdate(BaseModel):
    """Update inspection status (admin)."""
    status: Optional[str] = None
    overall_result: Optional[str] = None
    notes: Optional[str] = None


class NodalSubmissionPayload(BaseModel):
    """Payload sent by Field Inspector when transmitting report to Nodal Verifier."""
    shop_name: Optional[str] = None
    shop_owner_name: Optional[str] = None
    shop_address: Optional[str] = None
    notes: Optional[str] = None
    violation_rules: Optional[List[Dict[str, Any]]] = None
    evidence_images: Optional[List[str]] = None


class NodalDecisionPayload(BaseModel):
    """Payload submitted by Nodal Verifier during statutory scrutiny."""
    decision: str  # "ACCEPT" or "REJECT"
    verifier_comment: str
    verifier_name: Optional[str] = "Nodal Officer S. K. Sharma"


class InspectionResponse(BaseModel):
    """Inspection detail response."""
    inspection_id: UUID
    inspector_id: UUID
    product_barcode: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    location_name: Optional[str] = None
    status: str
    overall_result: Optional[str] = None
    image_storage_path: Optional[str] = None
    blockchain_hash: Optional[str] = None
    blockchain_tx_id: Optional[str] = None
    notes: Optional[str] = None
    metadata_json: Optional[Dict[str, Any]] = None
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class InspectionSummary(BaseModel):
    """Minimal inspection for list views."""
    inspection_id: UUID
    inspector_id: UUID
    product_barcode: Optional[str] = None
    status: str
    overall_result: Optional[str] = None
    location_name: Optional[str] = None
    created_at: datetime

    model_config = {"from_attributes": True}


class InspectionFilter(BaseModel):
    """Inspection search/filter parameters."""
    status: Optional[str] = None
    overall_result: Optional[str] = None
    inspector_id: Optional[UUID] = None
    product_barcode: Optional[str] = None
    date_from: Optional[datetime] = None
    date_to: Optional[datetime] = None
    zone_id: Optional[str] = None
