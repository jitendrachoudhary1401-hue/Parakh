"""
Project PARAKH — Consumer Care Rule

Validates mandatory Consumer Care details (Phone and Email/Address) per Legal Metrology Rules.
"""

from __future__ import annotations

import re
from typing import Dict

from app.ai.nlp_extractor import ExtractedEntity
from app.rules.base import RuleResult


class ConsumerCareRule:
    RULE_ID = "LM-004"
    RULE_NAME = "Consumer Care Contact Information"

    PHONE_PATTERN = re.compile(r"^\+?[\d\s\-]{8,15}$")
    EMAIL_PATTERN = re.compile(r"^[\w\.\-+]+@[\w\.\-]+\.\w+$")

    def evaluate(self, entities: Dict[str, ExtractedEntity]) -> RuleResult:
        phone_entity = entities.get("CONSUMER_CARE_PHONE")
        email_entity = entities.get("CONSUMER_CARE_EMAIL")
        address_entity = entities.get("CONSUMER_CARE_ADDRESS")

        has_phone = phone_entity is not None and bool(phone_entity.value.strip())
        has_email = email_entity is not None and bool(email_entity.value.strip())
        has_address = address_entity is not None and bool(address_entity.value.strip())

        if not has_phone and not has_email and not has_address:
            return RuleResult(
                rule_id=self.RULE_ID,
                rule_name=self.RULE_NAME,
                status="FAIL",
                explanation="No Consumer Care contact information (Phone, Email, or Address) found on label",
            )

        extracted_items = []
        confidences = []

        if has_phone:
            extracted_items.append(f"Phone: {phone_entity.value.strip()}")
            if phone_entity.confidence:
                confidences.append(phone_entity.confidence)
        if has_email:
            extracted_items.append(f"Email: {email_entity.value.strip()}")
            if email_entity.confidence:
                confidences.append(email_entity.confidence)
        if has_address:
            extracted_items.append(f"Address: {address_entity.value.strip()[:60]}...")
            if address_entity.confidence:
                confidences.append(address_entity.confidence)

        combined_value = " | ".join(extracted_items)
        avg_confidence = sum(confidences) / len(confidences) if confidences else None

        # Mandatory: Phone AND at least one of Email/Address
        if has_phone and (has_email or has_address):
            if avg_confidence and avg_confidence < 0.5:
                return RuleResult(
                    rule_id=self.RULE_ID,
                    rule_name=self.RULE_NAME,
                    status="REVIEW",
                    extracted_value=combined_value,
                    explanation=f"Consumer Care info present with low confidence ({avg_confidence:.2f})",
                    confidence=avg_confidence,
                )
            return RuleResult(
                rule_id=self.RULE_ID,
                rule_name=self.RULE_NAME,
                status="PASS",
                extracted_value=combined_value,
                explanation="Complete Consumer Care details (Phone and Email/Address) verified",
                confidence=avg_confidence,
            )
        elif has_phone or has_email or has_address:
            return RuleResult(
                rule_id=self.RULE_ID,
                rule_name=self.RULE_NAME,
                status="REVIEW",
                extracted_value=combined_value,
                explanation="Partial Consumer Care details found (mandatory: Phone + Email/Address)",
                confidence=avg_confidence,
            )

        return RuleResult(
            rule_id=self.RULE_ID,
            rule_name=self.RULE_NAME,
            status="FAIL",
            extracted_value=combined_value,
            explanation="Consumer Care details are insufficient under Legal Metrology Rules",
            confidence=avg_confidence,
        )
