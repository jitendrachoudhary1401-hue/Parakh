"""
Project PARAKH — Manufacturer Declaration Rule

Validates presence and readability of Manufacturer Name and Address.
"""

from __future__ import annotations

from typing import Dict

from app.ai.nlp_extractor import ExtractedEntity
from app.rules.base import RuleResult


class ManufacturerRule:
    RULE_ID = "LM-005"
    RULE_NAME = "Manufacturer Declaration"

    def evaluate(self, entities: Dict[str, ExtractedEntity]) -> RuleResult:
        mfg_name = entities.get("MANUFACTURER_NAME")
        mfg_addr = entities.get("MANUFACTURER_ADDRESS")

        has_name = mfg_name is not None and bool(mfg_name.value.strip())
        has_addr = mfg_addr is not None and bool(mfg_addr.value.strip())

        if not has_name and not has_addr:
            return RuleResult(
                rule_id=self.RULE_ID,
                rule_name=self.RULE_NAME,
                status="FAIL",
                explanation="Manufacturer Name and Address not found on product label",
            )

        extracted_parts = []
        confidences = []

        if has_name:
            extracted_parts.append(f"Name: {mfg_name.value.strip()}")
            if mfg_name.confidence:
                confidences.append(mfg_name.confidence)
        if has_addr:
            extracted_parts.append(f"Address: {mfg_addr.value.strip()[:60]}...")
            if mfg_addr.confidence:
                confidences.append(mfg_addr.confidence)

        combined_value = " | ".join(extracted_parts)
        avg_confidence = sum(confidences) / len(confidences) if confidences else None

        if has_name and has_addr:
            if avg_confidence and avg_confidence < 0.5:
                return RuleResult(
                    rule_id=self.RULE_ID,
                    rule_name=self.RULE_NAME,
                    status="REVIEW",
                    extracted_value=combined_value,
                    explanation=f"Manufacturer declaration detected with low confidence ({avg_confidence:.2f})",
                    confidence=avg_confidence,
                )
            return RuleResult(
                rule_id=self.RULE_ID,
                rule_name=self.RULE_NAME,
                status="PASS",
                extracted_value=combined_value,
                explanation="Manufacturer Name and Address are present and readable",
                confidence=avg_confidence,
            )
        elif has_name:
            return RuleResult(
                rule_id=self.RULE_ID,
                rule_name=self.RULE_NAME,
                status="REVIEW",
                extracted_value=combined_value,
                explanation="Manufacturer Name present, but complete address could not be conclusively verified",
                confidence=avg_confidence,
            )

        return RuleResult(
            rule_id=self.RULE_ID,
            rule_name=self.RULE_NAME,
            status="FAIL",
            extracted_value=combined_value,
            explanation="Manufacturer declaration incomplete",
            confidence=avg_confidence,
        )
