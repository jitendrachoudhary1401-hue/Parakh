"""
Project PARAKH — Net Quantity Rule

Validates net quantity presence, unit, and standard formatting per §19.
"""

from __future__ import annotations

import re
from typing import Dict

from app.ai.nlp_extractor import ExtractedEntity
from app.rules.base import RuleResult


class NetQuantityRule:
    RULE_ID = "LM-002"
    RULE_NAME = "Net Quantity"

    VALID_UNITS = re.compile(
        r"\d+[\.,]?\d*\s*(?:g|gm|gms|kg|ml|l|ltr|litre|litres|cc|oz|pieces?|pcs?|nos?)\b",
        re.IGNORECASE,
    )

    def evaluate(self, entities: Dict[str, ExtractedEntity]) -> RuleResult:
        entity = entities.get("NET_QUANTITY")

        if entity is None:
            return RuleResult(
                rule_id=self.RULE_ID,
                rule_name=self.RULE_NAME,
                status="FAIL",
                explanation="Net Quantity declaration not found on product label",
            )

        value = entity.value.strip()
        confidence = entity.confidence

        if not value:
            return RuleResult(
                rule_id=self.RULE_ID,
                rule_name=self.RULE_NAME,
                status="FAIL",
                extracted_value=value,
                explanation="Net Quantity field is empty",
                confidence=confidence,
            )

        if self.VALID_UNITS.search(value):
            if confidence and confidence < 0.5:
                return RuleResult(
                    rule_id=self.RULE_ID,
                    rule_name=self.RULE_NAME,
                    status="REVIEW",
                    extracted_value=value,
                    explanation=f"Net Quantity detected with low confidence ({confidence:.2f})",
                    confidence=confidence,
                )
            return RuleResult(
                rule_id=self.RULE_ID,
                rule_name=self.RULE_NAME,
                status="PASS",
                extracted_value=value,
                explanation="Net Quantity is present with valid unit formatting",
                confidence=confidence,
            )
        else:
            return RuleResult(
                rule_id=self.RULE_ID,
                rule_name=self.RULE_NAME,
                status="REVIEW",
                extracted_value=value,
                explanation=f"Net Quantity '{value}' may have non-standard unit formatting",
                confidence=confidence,
            )
