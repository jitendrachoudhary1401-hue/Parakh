"""
Project PARAKH — Compliance Rule Engine

Orchestrator per §19/§20 that runs all compliance rules and
aggregates results. Never marks compliant merely because data was unavailable.

Overall statuses: COMPLIANT, VIOLATION, REQUIRES_REVIEW,
INSUFFICIENT_DATA, SERVICE_UNAVAILABLE.
"""

from __future__ import annotations

import logging
from typing import Any, Dict, List, Optional

from app.ai.nlp_extractor import ExtractedEntity
from app.rules.base import RuleResult
from app.rules.mrp_rule import MRPRule
from app.rules.net_quantity_rule import NetQuantityRule
from app.rules.date_rule import DateRule
from app.rules.consumer_care_rule import ConsumerCareRule
from app.rules.manufacturer_rule import ManufacturerRule
from app.rules.gs1_rule import GS1Rule

logger = logging.getLogger("parakh.rules.engine")


class ComplianceEngine:
    """
    Central compliance rule engine orchestrator.

    Runs all Legal Metrology rules against extracted entities and
    determines overall compliance status.
    """

    def __init__(self):
        self.rules = [
            MRPRule(),
            NetQuantityRule(),
            DateRule(),
            ConsumerCareRule(),
            ManufacturerRule(),
            GS1Rule(),
        ]

    def evaluate(
        self,
        entities: List[ExtractedEntity],
        gs1_data: Optional[Dict[str, Any]] = None,
        ocr_text: str = "",
    ) -> Dict[str, Any]:
        """
        Evaluate all compliance rules.

        Args:
            entities: Extracted NLP entities.
            gs1_data: GS1 API lookup result (if available).
            ocr_text: Raw OCR text for context.

        Returns:
            Dict with 'overall_status', 'rule_results', 'requires_human_review',
            'review_reasons'.
        """
        entity_map = {e.entity_type: e for e in entities}
        results: List[RuleResult] = []
        review_reasons: List[str] = []

        for rule in self.rules:
            try:
                if isinstance(rule, GS1Rule):
                    result = rule.evaluate(entity_map, gs1_data)
                else:
                    result = rule.evaluate(entity_map)
                results.append(result)

                if result.status == "REVIEW":
                    review_reasons.append(
                        f"{result.rule_name}: {result.explanation}"
                    )
            except Exception as exc:
                logger.error("Rule %s failed: %s", rule.__class__.__name__, exc)
                results.append(RuleResult(
                    rule_id=getattr(rule, "RULE_ID", "unknown"),
                    rule_name=getattr(rule, "RULE_NAME", "Unknown Rule"),
                    status="NOT_AVAILABLE",
                    explanation=f"Rule evaluation error: {str(exc)}",
                ))

        # Determine overall status
        overall_status = self._determine_overall_status(results)
        requires_review = overall_status in ("REQUIRES_REVIEW", "INSUFFICIENT_DATA")

        logger.info(
            "Compliance evaluation: %s (%d rules, %d pass, %d fail, %d review)",
            overall_status,
            len(results),
            sum(1 for r in results if r.status == "PASS"),
            sum(1 for r in results if r.status == "FAIL"),
            sum(1 for r in results if r.status == "REVIEW"),
        )

        return {
            "overall_status": overall_status,
            "rule_results": [r.to_dict() for r in results],
            "requires_human_review": requires_review,
            "review_reasons": review_reasons,
        }

    def _determine_overall_status(self, results: List[RuleResult]) -> str:
        """
        Determine overall compliance status from individual rule results.

        Logic per §20:
        - Any FAIL → VIOLATION
        - All PASS → COMPLIANT
        - Any REVIEW (no FAIL) → REQUIRES_REVIEW
        - All NOT_AVAILABLE → INSUFFICIENT_DATA
        - Never compliant merely because data was unavailable
        """
        statuses = [r.status for r in results]

        if not statuses:
            return "INSUFFICIENT_DATA"

        has_fail = "FAIL" in statuses
        has_pass = "PASS" in statuses
        has_review = "REVIEW" in statuses
        has_unavailable = "NOT_AVAILABLE" in statuses

        # All results are NOT_AVAILABLE
        if all(s == "NOT_AVAILABLE" for s in statuses):
            return "INSUFFICIENT_DATA"

        # Any failure means violation
        if has_fail:
            return "VIOLATION"

        # Any REVIEW (without FAIL) means requires review
        if has_review:
            return "REQUIRES_REVIEW"

        # If some are NOT_AVAILABLE but rest are PASS — still requires review
        # (§20: Never mark compliant merely because data was unavailable)
        if has_unavailable and has_pass:
            return "REQUIRES_REVIEW"

        # All PASS
        if all(s == "PASS" for s in statuses):
            return "COMPLIANT"

        return "REQUIRES_REVIEW"
