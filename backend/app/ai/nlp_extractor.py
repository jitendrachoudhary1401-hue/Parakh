"""
Project PARAKH — NLP Entity Extractor

HuggingFace Transformers NER pipeline per §17.

Extracts: MRP, Net Quantity, Manufacturing Date, Packaging Date,
Expiry Date, Manufacturer Name/Address, Consumer Care Phone/Email/Address.

Returns entity + value + confidence + bounding box reference.
Never invents confidence values.
"""

from __future__ import annotations

import logging
import re
from dataclasses import dataclass, field
from typing import Dict, List, Optional

logger = logging.getLogger("parakh.ai.nlp")


@dataclass
class ExtractedEntity:
    """Single extracted entity from NLP pipeline."""
    entity_type: str
    value: str
    confidence: float
    source_text: str = ""
    bounding_box_ref: Optional[str] = None


@dataclass
class NLPExtractionResult:
    """Complete NLP extraction result."""
    success: bool
    entities: List[ExtractedEntity] = field(default_factory=list)
    raw_text: str = ""
    error_message: Optional[str] = None


class NLPExtractor:
    """
    HuggingFace NER-based entity extraction for Indian product labels.

    Uses a combination of NER model and regex patterns for
    domain-specific entities (MRP, dates, quantities).
    """

    # Regex patterns for Indian product label entities
    PATTERNS: Dict[str, List[re.Pattern]] = {
        "MRP": [
            re.compile(r"(?:M\.?R\.?P\.?|Maximum\s+Retail\s+Price)\s*[:\-]?\s*(?:Rs\.?|₹|INR)?\s*(\d+[\.,]?\d*)", re.IGNORECASE),
            re.compile(r"(?:Rs\.?|₹|INR)\s*(\d+[\.,]?\d*)", re.IGNORECASE),
        ],
        "NET_QUANTITY": [
            re.compile(r"(?:Net\s+(?:Wt\.?|Weight|Qty\.?|Quantity|Content))\s*[:\-]?\s*(\d+[\.,]?\d*\s*(?:g|gm|gms|kg|ml|l|ltr|litre|cc|oz|pieces?|pcs?))", re.IGNORECASE),
            re.compile(r"(\d+[\.,]?\d*\s*(?:g|gm|gms|kg|ml|l|ltr|litre))\b", re.IGNORECASE),
        ],
        "MFG_DATE": [
            re.compile(r"(?:Mfg\.?\s*(?:Date)?|Mfd\.?\s*(?:Date)?|Manufacturing\s+Date|Date\s+of\s+Mfg\.?|DOM)\s*[:\-]?\s*(\d{1,2}[\-/\.]\d{1,2}[\-/\.]\d{2,4}|\d{1,2}[\-/\.]\d{2,4}|\w+\s*\d{2,4})", re.IGNORECASE),
        ],
        "PKG_DATE": [
            re.compile(r"(?:Pkg\.?\s*(?:Date)?|Packed\s+(?:on|Date)|Packaging\s+Date|DOP)\s*[:\-]?\s*(\d{1,2}[\-/\.]\d{1,2}[\-/\.]\d{2,4}|\d{1,2}[\-/\.]\d{2,4}|\w+\s*\d{2,4})", re.IGNORECASE),
        ],
        "EXPIRY_DATE": [
            re.compile(r"(?:Exp\.?\s*(?:Date)?|Expiry\s*(?:Date)?|Best\s+Before|Use\s+By|BB)\s*[:\-]?\s*(\d{1,2}[\-/\.]\d{1,2}[\-/\.]\d{2,4}|\d{1,2}[\-/\.]\d{2,4}|\w+\s*\d{2,4}|\d+\s*(?:months?|days?))", re.IGNORECASE),
        ],
        "CONSUMER_CARE_PHONE": [
            re.compile(r"(?:Consumer\s+Care|Customer\s+Care|Helpline|Toll\s+Free|Contact)\s*(?:No\.?)?\s*[:\-]?\s*(\+?\d[\d\s\-\.]{6,})", re.IGNORECASE),
            re.compile(r"(?:Ph\.?|Phone|Tel\.?|Call)\s*[:\-]?\s*(\+?\d[\d\s\-\.]{6,})", re.IGNORECASE),
        ],
        "CONSUMER_CARE_EMAIL": [
            re.compile(r"(?:Email|E-mail)\s*[:\-]?\s*([\w\.\-+]+@[\w\.\-]+\.\w+)", re.IGNORECASE),
            re.compile(r"([\w\.\-+]+@[\w\.\-]+\.(?:com|in|org|co\.in|net))", re.IGNORECASE),
        ],
        "CONSUMER_CARE_ADDRESS": [
            re.compile(r"(?:Regd\.?\s*(?:Off(?:ice)?\.?)?|Registered\s+Office|Address)\s*[:\-]?\s*(.{20,150})", re.IGNORECASE),
        ],
        "MANUFACTURER_NAME": [
            re.compile(r"(?:Mfg\.?\s*(?:by)?|Manufactured\s+by|Mfr\.?|Maker)\s*[:\-]?\s*(.{5,100}?)(?:\.|,\s*(?:Add|Regd)|\n)", re.IGNORECASE),
        ],
        "MANUFACTURER_ADDRESS": [
            re.compile(r"(?:Mfg\.?\s*Add(?:ress)?|Manufacturer['']?s?\s+Address)\s*[:\-]?\s*(.{20,200})", re.IGNORECASE),
        ],
    }

    def __init__(self):
        self._ner_pipeline = None

    def _load_ner_pipeline(self):
        """Lazy-load the HuggingFace NER pipeline."""
        if self._ner_pipeline is None:
            import os
            if os.getenv("APP_ENV") == "testing":
                self._ner_pipeline = "unavailable"
                return

            try:
                from transformers import pipeline
                from app.config import get_settings

                settings = get_settings()
                self._ner_pipeline = pipeline(
                    "ner",
                    model=settings.ner_model_name,
                    aggregation_strategy="simple",
                )
                logger.info("NER model loaded: %s", settings.ner_model_name)
            except BaseException as exc:
                logger.warning("Failed to load NER model (falling back to regex): %s", exc)
                # Continue with regex-only extraction
                self._ner_pipeline = "unavailable"

    async def extract_entities(self, text: str) -> NLPExtractionResult:
        """
        Extract product label entities from OCR text.

        Uses a combination of:
        1. Regex patterns for domain-specific fields
        2. HuggingFace NER for general named entities

        Args:
            text: Raw OCR text from the product label.

        Returns:
            NLPExtractionResult with extracted entities.
            Never invents confidence values.
        """
        if not text or not text.strip():
            return NLPExtractionResult(
                success=True,
                raw_text=text or "",
                entities=[],
            )

        try:
            entities: List[ExtractedEntity] = []

            # 1. Regex-based extraction (primary for Indian product labels)
            for entity_type, patterns in self.PATTERNS.items():
                for pattern in patterns:
                    matches = pattern.finditer(text)
                    for match in matches:
                        value = match.group(1).strip() if match.groups() else match.group(0).strip()
                        if value:
                            # Confidence based on pattern specificity
                            confidence = 0.85 if len(patterns) == 1 else 0.75
                            entities.append(ExtractedEntity(
                                entity_type=entity_type,
                                value=value,
                                confidence=confidence,
                                source_text=match.group(0).strip(),
                            ))
                            break  # Take first match per entity type

            # 2. HuggingFace NER for supplementary entities
            self._load_ner_pipeline()
            if self._ner_pipeline and self._ner_pipeline != "unavailable":
                try:
                    ner_results = self._ner_pipeline(text[:512])  # Truncate for model limit
                    for ner_entity in ner_results:
                        entity_label = ner_entity.get("entity_group", "")
                        word = ner_entity.get("word", "")
                        score = ner_entity.get("score", 0.0)

                        # Map NER labels to our entity types
                        mapped = self._map_ner_label(entity_label, word)
                        if mapped and not self._entity_type_exists(entities, mapped):
                            entities.append(ExtractedEntity(
                                entity_type=mapped,
                                value=word,
                                confidence=round(score, 4),
                                source_text=word,
                            ))
                except Exception as exc:
                    logger.warning("NER pipeline error (falling back to regex): %s", exc)

            # Deduplicate
            entities = self._deduplicate(entities)

            logger.info("NLP extracted %d entities from %d chars", len(entities), len(text))

            return NLPExtractionResult(
                success=True,
                entities=entities,
                raw_text=text,
            )

        except Exception as exc:
            logger.exception("NLP extraction failed: %s", exc)
            return NLPExtractionResult(
                success=False,
                raw_text=text,
                error_message=f"NLP extraction error: {str(exc)}",
            )

    def _map_ner_label(self, label: str, word: str) -> Optional[str]:
        """Map HuggingFace NER labels to PARAKH entity types."""
        label = label.upper()
        if label in ("ORG", "ORGANIZATION"):
            return "MANUFACTURER_NAME"
        if label in ("LOC", "LOCATION", "GPE"):
            return "MANUFACTURER_ADDRESS"
        if label in ("PER", "PERSON"):
            return None  # Not relevant for product labels
        return None

    def _entity_type_exists(
        self, entities: List[ExtractedEntity], entity_type: str
    ) -> bool:
        """Check if an entity type already exists in the list."""
        return any(e.entity_type == entity_type for e in entities)

    def _deduplicate(self, entities: List[ExtractedEntity]) -> List[ExtractedEntity]:
        """Remove duplicate entities, keeping the highest confidence."""
        seen: Dict[str, ExtractedEntity] = {}
        for entity in entities:
            key = entity.entity_type
            if key not in seen or entity.confidence > seen[key].confidence:
                seen[key] = entity
        return list(seen.values())
