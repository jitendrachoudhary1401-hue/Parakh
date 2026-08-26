"""
Project PARAKH — Base Rule Result Class

Shared data structure for Legal Metrology rule evaluation per §20.
"""

from __future__ import annotations

from typing import Optional


class RuleResult:
    """Result of a single compliance rule per §20."""

    def __init__(
        self,
        rule_id: str,
        rule_name: str,
        status: str,
        extracted_value: Optional[str] = None,
        explanation: str = "",
        confidence: Optional[float] = None,
        evidence_reference: Optional[str] = None,
    ):
        self.rule_id = rule_id
        self.rule_name = rule_name
        self.status = status  # PASS, FAIL, REVIEW, NOT_AVAILABLE
        self.extracted_value = extracted_value
        self.explanation = explanation
        self.confidence = confidence
        self.evidence_reference = evidence_reference

    def to_dict(self) -> dict:
        return {
            "rule_id": self.rule_id,
            "rule_name": self.rule_name,
            "status": self.status,
            "extracted_value": self.extracted_value,
            "explanation": self.explanation,
            "confidence": self.confidence,
            "evidence_reference": self.evidence_reference,
        }
