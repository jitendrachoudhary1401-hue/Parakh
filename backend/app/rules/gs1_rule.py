"""
Project PARAKH — GS1 Cross-Referencing Rule

Compares extracted manufacturer with GS1 India registered manufacturer per §18/§19.
Returns MATCH, MISMATCH, UNAVAILABLE, or SERVICE_UNAVAILABLE.
Never fabricates GS1 records.
"""

from __future__ import annotations

from typing import Any, Dict, Optional

from app.ai.nlp_extractor import ExtractedEntity
from app.rules.base import RuleResult


class GS1Rule:
    RULE_ID = "LM-006"
    RULE_NAME = "GS1 Barcode & Manufacturer Cross-Verification"

    def evaluate(
        self,
        entities: Dict[str, ExtractedEntity],
        gs1_data: Optional[Dict[str, Any]] = None,
    ) -> RuleResult:
        mfg_entity = entities.get("MANUFACTURER_NAME")
        extracted_name = mfg_entity.value.strip() if mfg_entity and mfg_entity.value else None

        if gs1_data is None:
            return RuleResult(
                rule_id=self.RULE_ID,
                rule_name=self.RULE_NAME,
                status="NOT_AVAILABLE",
                extracted_value=extracted_name,
                explanation="No GS1 barcode data provided for cross-verification",
            )

        gs1_status = gs1_data.get("status")
        if gs1_status == "SERVICE_UNAVAILABLE":
            return RuleResult(
                rule_id=self.RULE_ID,
                rule_name=self.RULE_NAME,
                status="NOT_AVAILABLE",
                extracted_value=extracted_name,
                explanation="GS1 India API is currently unavailable; cross-verification skipped",
            )

        registered_mfg = gs1_data.get("registered_manufacturer")
        barcode = gs1_data.get("barcode", "")

        if not registered_mfg:
            return RuleResult(
                rule_id=self.RULE_ID,
                rule_name=self.RULE_NAME,
                status="REVIEW",
                extracted_value=f"Extracted: {extracted_name or 'N/A'} | Barcode: {barcode}",
                explanation=f"Barcode {barcode} has no registered manufacturer in GS1 database",
            )

        if not extracted_name:
            return RuleResult(
                rule_id=self.RULE_ID,
                rule_name=self.RULE_NAME,
                status="REVIEW",
                extracted_value=f"GS1: {registered_mfg}",
                explanation="GS1 registered manufacturer found, but label manufacturer text was unreadable",
            )

        # Simple fuzzy/substring comparison
        ext_norm = extracted_name.lower().replace("pvt", "").replace("ltd", "").replace(".", "").replace(",", "").strip()
        reg_norm = registered_mfg.lower().replace("pvt", "").replace("ltd", "").replace(".", "").replace(",", "").strip()

        words_ext = set(ext_norm.split())
        words_reg = set(reg_norm.split())

        intersection = words_ext.intersection(words_reg)
        similarity = len(intersection) / max(len(words_ext), len(words_reg)) if (words_ext and words_reg) else 0

        combined = f"Extracted: {extracted_name} | GS1: {registered_mfg}"

        if similarity >= 0.4 or ext_norm in reg_norm or reg_norm in ext_norm:
            return RuleResult(
                rule_id=self.RULE_ID,
                rule_name=self.RULE_NAME,
                status="PASS",
                extracted_value=combined,
                explanation=f"Manufacturer aligns with GS1 registered owner ({registered_mfg})",
            )
        else:
            return RuleResult(
                rule_id=self.RULE_ID,
                rule_name=self.RULE_NAME,
                status="FAIL",
                extracted_value=combined,
                explanation=f"Potential Ghost Manufacturer: Scanned barcode is registered to '{registered_mfg}', but label declares '{extracted_name}'",
            )
