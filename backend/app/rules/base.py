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
        clause_id: Optional[str] = None,
        rule_number: Optional[str] = None,
        severity: Optional[str] = None,
        act_section: Optional[str] = None,
        default_notice_clause: Optional[str] = None,
    ):
        self.rule_id = rule_id
        self.rule_name = rule_name
        self.status = status  # PASS, FAIL, REVIEW, NOT_AVAILABLE
        self.extracted_value = extracted_value
        self.explanation = explanation
        self.confidence = confidence
        self.evidence_reference = evidence_reference
        self.clause_id = clause_id
        self.rule_number = rule_number
        self.severity = severity
        self.act_section = act_section
        self.default_notice_clause = default_notice_clause

    def to_dict(self) -> dict:
        return {
            "rule_id": self.rule_id,
            "rule_name": self.rule_name,
            "status": self.status,
            "extracted_value": self.extracted_value,
            "explanation": self.explanation,
            "confidence": self.confidence,
            "evidence_reference": self.evidence_reference,
            "clause_id": self.clause_id,
            "rule_number": self.rule_number,
            "severity": self.severity,
            "act_section": self.act_section,
            "default_notice_clause": self.default_notice_clause,
        }
