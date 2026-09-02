"""
Project PARAKH — Barcode & Open Food Facts Cross-Referencing Rule

Compares extracted label manufacturer/brand with Open Food Facts registered product database.
Returns PASS, FAIL, REVIEW, or NOT_AVAILABLE.
Never fabricates database records.
"""

from __future__ import annotations

from typing import Any, Dict, Optional

from app.ai.nlp_extractor import ExtractedEntity
from app.rules.base import RuleResult


class OpenFoodFactsRule:
    RULE_ID = "LM-006"
    RULE_NAME = "Barcode & Open Food Facts Cross-Verification"

    def evaluate(
        self,
        entities: Dict[str, ExtractedEntity],
        product_data: Optional[Dict[str, Any]] = None,
    ) -> RuleResult:
        mfg_entity = entities.get("MANUFACTURER_NAME")
        extracted_name = mfg_entity.value.strip() if mfg_entity and mfg_entity.value else None

        if product_data is None:
            return RuleResult(
                rule_id=self.RULE_ID,
                rule_name=self.RULE_NAME,
                status="NOT_AVAILABLE",
                extracted_value=extracted_name,
                explanation="No barcode product data provided for cross-verification",
            )

        status = product_data.get("status")
        if status == "SERVICE_UNAVAILABLE":
            return RuleResult(
                rule_id=self.RULE_ID,
                rule_name=self.RULE_NAME,
                status="NOT_AVAILABLE",
                extracted_value=extracted_name,
                explanation="Open Food Facts API is currently unavailable; cross-verification skipped",
            )

        registered_mfg = product_data.get("registered_manufacturer") or product_data.get("brand")
        barcode = product_data.get("barcode", "")

        if not registered_mfg:
            return RuleResult(
                rule_id=self.RULE_ID,
                rule_name=self.RULE_NAME,
                status="REVIEW",
                extracted_value=f"Extracted: {extracted_name or 'N/A'} | Barcode: {barcode}",
                explanation=f"Barcode {barcode} has no registered manufacturer in Open Food Facts database",
            )

        if not extracted_name:
            return RuleResult(
                rule_id=self.RULE_ID,
                rule_name=self.RULE_NAME,
                status="REVIEW",
                extracted_value=f"Open Food Facts: {registered_mfg}",
                explanation="Registered product manufacturer found in Open Food Facts, but label manufacturer text was unreadable",
            )

        # Simple fuzzy/substring comparison
        ext_norm = (
            extracted_name.lower()
            .replace("pvt", "")
            .replace("ltd", "")
            .replace("private", "")
            .replace("limited", "")
            .replace(".", "")
            .replace(",", "")
            .strip()
        )
        reg_norm = (
            registered_mfg.lower()
            .replace("pvt", "")
            .replace("ltd", "")
            .replace("private", "")
            .replace("limited", "")
            .replace(".", "")
            .replace(",", "")
            .strip()
        )

        words_ext = set(ext_norm.split())
        words_reg = set(reg_norm.split())

        intersection = words_ext.intersection(words_reg)
        similarity = (
            len(intersection) / max(len(words_ext), len(words_reg))
            if (words_ext and words_reg)
            else 0
        )

        combined = f"Extracted: {extracted_name} | Open Food Facts: {registered_mfg}"

        if similarity >= 0.3 or ext_norm in reg_norm or reg_norm in ext_norm:
            return RuleResult(
                rule_id=self.RULE_ID,
                rule_name=self.RULE_NAME,
                status="PASS",
                extracted_value=combined,
                explanation=f"Manufacturer aligns with registered brand owner ({registered_mfg})",
            )
        else:
            return RuleResult(
                rule_id=self.RULE_ID,
                rule_name=self.RULE_NAME,
                status="FAIL",
                extracted_value=combined,
                explanation=f"Potential Ghost Manufacturer: Scanned barcode is registered to '{registered_mfg}' in Open Food Facts, but label declares '{extracted_name}'",
            )


# Alias for backward compatibility
GS1Rule = OpenFoodFactsRule
