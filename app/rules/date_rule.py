"""
Project PARAKH — Date Rule (Manufacturing, Packaging & Expiry)

Validates presence and readability of Month/Year of Manufacture or Packaging,
and Expiry Date where applicable under Legal Metrology Rules, 2011.
"""

from __future__ import annotations

import re
from typing import Dict

from app.ai.nlp_extractor import ExtractedEntity
from app.rules.base import RuleResult


class DateRule:
    RULE_ID = "LM-003"
    RULE_NAME = "Manufacturing / Packaging / Expiry Date"

    # Matches MM/YYYY, MM-YYYY, MMM YYYY, DD/MM/YYYY, etc.
    DATE_PATTERN = re.compile(
        r"^(?:\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4}|\d{1,2}[\/\-\.]\d{2,4}|(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*[\s\.\,\/\-]*\d{2,4}|\d+\s*(?:months?|days?|years?)\s*(?:from|of)?\s*(?:mfg|pkg|pkd)?)$",
        re.IGNORECASE,
    )

    def evaluate(self, entities: Dict[str, ExtractedEntity]) -> RuleResult:
        mfg_entity = entities.get("MFG_DATE")
        pkg_entity = entities.get("PKG_DATE")
        exp_entity = entities.get("EXPIRY_DATE")

        # Either Manufacturing date or Packaging date is mandatory
        primary_date_entity = mfg_entity or pkg_entity

        if primary_date_entity is None and exp_entity is None:
            return RuleResult(
                rule_id=self.RULE_ID,
                rule_name=self.RULE_NAME,
                status="FAIL",
                explanation="No Manufacturing, Packaging, or Expiry date declaration found on product label",
            )

        extracted_parts = []
        confidences = []

        if primary_date_entity:
            val = primary_date_entity.value.strip()
            date_type = "Mfg" if primary_date_entity == mfg_entity else "Pkg"
            extracted_parts.append(f"{date_type}: {val}")
            if primary_date_entity.confidence:
                confidences.append(primary_date_entity.confidence)

        if exp_entity:
            exp_val = exp_entity.value.strip()
            extracted_parts.append(f"Exp: {exp_val}")
            if exp_entity.confidence:
                confidences.append(exp_entity.confidence)

        combined_value = " | ".join(extracted_parts)
        avg_confidence = sum(confidences) / len(confidences) if confidences else None

        if primary_date_entity:
            date_val = primary_date_entity.value.strip()
            if self.DATE_PATTERN.match(date_val) or any(char.isdigit() for char in date_val):
                if avg_confidence and avg_confidence < 0.5:
                    return RuleResult(
                        rule_id=self.RULE_ID,
                        rule_name=self.RULE_NAME,
                        status="REVIEW",
                        extracted_value=combined_value,
                        explanation=f"Date declarations detected with low confidence ({avg_confidence:.2f})",
                        confidence=avg_confidence,
                    )
                return RuleResult(
                    rule_id=self.RULE_ID,
                    rule_name=self.RULE_NAME,
                    status="PASS",
                    extracted_value=combined_value,
                    explanation="Manufacturing/Packaging date declaration is present and readable",
                    confidence=avg_confidence,
                )

        return RuleResult(
            rule_id=self.RULE_ID,
            rule_name=self.RULE_NAME,
            status="REVIEW",
            extracted_value=combined_value,
            explanation="Date declaration found but format requires verification",
            confidence=avg_confidence,
        )
