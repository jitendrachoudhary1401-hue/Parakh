"""
Project PARAKH — Report Schemas
"""

from __future__ import annotations

from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel


class ReportCreateRequest(BaseModel):
    inspection_id: UUID
    report_type: Optional[str] = "LEGAL_SHOW_CAUSE"
    inspector_notes: Optional[str] = None


class ReportSubmitToNodalRequest(BaseModel):
    inspector_notes: Optional[str] = None
    notes: Optional[str] = None

    @property
    def effective_notes(self) -> Optional[str]:
        return self.inspector_notes or self.notes


class ReportNodalReviewRequest(BaseModel):
    nodal_comments: Optional[str] = None
    comments: Optional[str] = None

    @property
    def effective_comments(self) -> str:
        return self.nodal_comments or self.comments or ""


class ReportCommissionerCertifyRequest(BaseModel):
    commissioner_comments: Optional[str] = None
    comments: Optional[str] = None

    @property
    def effective_comments(self) -> Optional[str]:
        return self.commissioner_comments or self.comments


class ReportResponse(BaseModel):
    report_id: UUID
    inspection_id: UUID
    generated_by_user_id: UUID
    report_type: str
    pdf_url: str
    file_hash: str
    status: str
    created_at: datetime

    # Workflow fields
    inspector_notes: Optional[str] = None
    nodal_officer_id: Optional[UUID] = None
    nodal_comments: Optional[str] = None
    nodal_reviewed_at: Optional[datetime] = None
    commissioner_id: Optional[UUID] = None
    commissioner_comments: Optional[str] = None
    commissioner_certified_at: Optional[datetime] = None
    digital_signature_hash: Optional[str] = None

    model_config = {"from_attributes": True}
