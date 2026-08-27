"""
Project PARAKH — Citizen Report Schemas
"""

from __future__ import annotations

from datetime import datetime
from typing import Any, Dict, Optional
from uuid import UUID

from pydantic import BaseModel, Field


class CitizenReportCreate(BaseModel):
    """Citizen report submission."""
    description: Optional[str] = None
    product_barcode: Optional[str] = None
    latitude: Optional[float] = Field(None, ge=-90, le=90)
    longitude: Optional[float] = Field(None, ge=-180, le=180)
    location_name: Optional[str] = None
    source: str = "app"  # "app" or "whatsapp"


class CitizenReportTriageRequest(BaseModel):
    """Admin triage decision on a citizen report."""
    decision: str = Field(..., pattern="^(approved|rejected|investigating)$")
    notes: Optional[str] = None


class CitizenReportResponse(BaseModel):
    """Citizen report detail response."""
    report_id: UUID
    citizen_id: UUID
    image_storage_path: Optional[str] = None
    description: Optional[str] = None
    product_barcode: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    location_name: Optional[str] = None
    ai_triage_status: str
    ai_triage_confidence: Optional[float] = None
    ai_triage_details: Optional[Dict[str, Any]] = None
    admin_decision: str
    admin_notes: Optional[str] = None
    source: str
    created_at: datetime
    updated_at: datetime
    reviewed_at: Optional[datetime] = None

    model_config = {"from_attributes": True}


class CitizenReportStatus(BaseModel):
    """Minimal status for citizen's own view."""
    report_id: UUID
    ai_triage_status: str
    admin_decision: str
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}
