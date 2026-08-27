"""
Project PARAKH — Compliance Schemas
"""

from __future__ import annotations

from typing import List, Optional
from uuid import UUID

from pydantic import BaseModel

from app.schemas.analysis import RuleResult


class ComplianceResponse(BaseModel):
    """Compliance result for an inspection."""
    inspection_id: UUID
    overall_status: str
    rule_results: List[RuleResult] = []
    requires_human_review: bool = False
    review_reasons: List[str] = []
