"""
Project PARAKH — Analysis / Compliance Verification Schemas
"""

from __future__ import annotations

from typing import Any, Dict, List, Optional
from uuid import UUID

from pydantic import BaseModel, Field


class AnalysisRequest(BaseModel):
    """Request body for compliance analysis."""
    inspection_id: UUID
    product_barcode: Optional[str] = None
    # If image was already uploaded, reference it; otherwise include base64
    image_storage_path: Optional[str] = None


class ExtractedEntity(BaseModel):
    """A single entity extracted by NLP."""
    entity: str  # e.g., "MRP", "NET_QUANTITY", "MFG_DATE"
    value: Optional[str] = None
    confidence: Optional[float] = Field(None, ge=0.0, le=1.0)
    bounding_box: Optional[Dict[str, Any]] = None


class RuleResult(BaseModel):
    """Result of a single compliance rule per §20."""
    rule_id: str
    rule_name: str
    status: str  # PASS, FAIL, REVIEW, NOT_AVAILABLE
    extracted_value: Optional[str] = None
    explanation: str
    confidence: Optional[float] = Field(None, ge=0.0, le=1.0)
    evidence_reference: Optional[str] = None


class GS1ComparisonResult(BaseModel):
    """GS1 manufacturer cross-reference result per §18."""
    status: str  # MATCH, MISMATCH, UNAVAILABLE, SERVICE_UNAVAILABLE
    extracted_manufacturer: Optional[str] = None
    registered_manufacturer: Optional[str] = None
    barcode: Optional[str] = None


class AnomalyResult(BaseModel):
    """Anomaly detection result per §22."""
    anomaly_type: str  # logo, typography, color_gradient, packaging
    description: str
    confidence: Optional[float] = Field(None, ge=0.0, le=1.0)
    is_potential_anomaly: bool


class AnalysisResponse(BaseModel):
    """Full compliance analysis result."""
    inspection_id: UUID
    overall_status: str  # COMPLIANT, VIOLATION, REQUIRES_REVIEW,
    #                      INSUFFICIENT_DATA, SERVICE_UNAVAILABLE
    extracted_entities: List[ExtractedEntity] = []
    rule_results: List[RuleResult] = []
    gs1_comparison: Optional[GS1ComparisonResult] = None
    anomalies: List[AnomalyResult] = []
    raw_ocr_text: Optional[str] = None
    processing_time_ms: Optional[float] = None
    requires_human_review: bool = False
    review_reasons: List[str] = []
