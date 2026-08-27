"""
Project PARAKH — MRP Rule

Validates MRP presence, formatting, and readability per §19.
"""

from __future__ import annotations

import re
from typing import Dict, Optional

from app.ai.nlp_extractor import ExtractedEntity
from app.rules.base import RuleResult


class MRPRule:
    RULE_ID = "LM-001"
    RULE_NAME = "Maximum Retail Price (MRP)"

    # Valid MRP pattern: currency symbol + number
    MRP_PATTERN = re.compile(
        r"^(?:Rs\.?|₹|INR)?\s*\d+[\.,]?\d*$", re.IGNORECASE
    )

    def evaluate(self, entities: Dict[str, ExtractedEntity]) -> RuleResult:
        """Evaluate MRP presence and formatting."""
        entity = entities.get("MRP")

        if entity is None:
            return RuleResult(
                rule_id=self.RULE_ID,
                rule_name=self.RULE_NAME,
                status="FAIL",
                explanation="MRP declaration not found on product label",
            )

        value = entity.value.strip()
        confidence = entity.confidence

        if not value:
            return RuleResult(
                rule_id=self.RULE_ID,
                rule_name=self.RULE_NAME,
                status="FAIL",
                extracted_value=value,
                explanation="MRP field is empty",
                confidence=confidence,
            )

        # Check formatting
        # Remove common prefixes for validation
        clean_value = re.sub(r"^(?:MRP|M\.R\.P\.?)\s*[:\-]?\s*", "", value, flags=re.IGNORECASE)

        if self.MRP_PATTERN.match(clean_value):
            if confidence and confidence < 0.5:
                return RuleResult(
                    rule_id=self.RULE_ID,
                    rule_name=self.RULE_NAME,
                    status="REVIEW",
                    extracted_value=value,
                    explanation=f"MRP detected but with low confidence ({confidence:.2f})",
                    confidence=confidence,
                )
            return RuleResult(
                rule_id=self.RULE_ID,
                rule_name=self.RULE_NAME,
                status="PASS",
                extracted_value=value,
                explanation="MRP is present and correctly formatted",
                confidence=confidence,
            )
        else:
            return RuleResult(
                rule_id=self.RULE_ID,
                rule_name=self.RULE_NAME,
                status="REVIEW",
                extracted_value=value,
                explanation=f"MRP value '{value}' may not be correctly formatted",
                confidence=confidence,
            )
