"""
Project PARAKH — AI Triage for Citizen Reports

Per §30: AI triage assists but does not make legal determinations.
Classifications: BLURRY, IRRELEVANT, POTENTIAL_VIOLATION,
APPARENTLY_COMPLIANT, REQUIRES_REVIEW.
"""

from __future__ import annotations

import logging
from dataclasses import dataclass
from typing import Optional

import numpy as np

logger = logging.getLogger("parakh.ai.triage")


@dataclass
class TriageResult:
    """AI triage classification for a citizen report."""
    classification: str
    confidence: float
    reason: str
    is_actionable: bool


class AITriage:
    """
    AI-powered triage for citizen-submitted reports.

    Filters out blurry, irrelevant, or apparently compliant
    submissions before they reach admin review.
    Not a legal determination.
    """

    def assess(self, image: np.ndarray, ocr_text: str = "") -> TriageResult:
        """
        Assess a citizen-submitted image for report quality and relevance.

        Args:
            image: Uploaded image (OpenCV ndarray).
            ocr_text: Optional OCR text already extracted.

        Returns:
            TriageResult with classification and confidence.
        """
        try:
            import cv2

            # 1. Check for blurriness
            gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
            laplacian_var = cv2.Laplacian(gray, cv2.CV_64F).var()

            if laplacian_var < 100:
                return TriageResult(
                    classification="blurry",
                    confidence=min(0.9, 1.0 - laplacian_var / 100.0),
                    reason="Image is too blurry for reliable analysis",
                    is_actionable=False,
                )

            # 2. Check if image contains text (product label relevance)
            text_density = len(ocr_text.strip()) if ocr_text else 0

            if text_density < 10:
                # Very little text — may not be a product image
                return TriageResult(
                    classification="irrelevant",
                    confidence=0.6,
                    reason="Insufficient text content detected; may not be a product label",
                    is_actionable=False,
                )

            # 3. Check for product-label keywords
            product_keywords = [
                "mrp", "price", "net", "weight", "quantity",
                "mfg", "manufactured", "expiry", "best before",
                "consumer", "care", "packed", "ingredients",
            ]
            text_lower = ocr_text.lower()
            keyword_hits = sum(1 for kw in product_keywords if kw in text_lower)

            if keyword_hits == 0:
                return TriageResult(
                    classification="irrelevant",
                    confidence=0.55,
                    reason="No product-label keywords detected in image",
                    is_actionable=False,
                )

            # 4. Quick compliance indicators
            has_mrp = any(kw in text_lower for kw in ["mrp", "₹", "rs.", "price"])
            has_dates = any(kw in text_lower for kw in ["mfg", "expiry", "best before", "exp"])
            has_contact = any(kw in text_lower for kw in ["consumer care", "helpline", "customer care", "@"])

            missing_count = sum(1 for check in [has_mrp, has_dates, has_contact] if not check)

            if missing_count >= 2:
                return TriageResult(
                    classification="potential_violation",
                    confidence=0.65,
                    reason=f"Multiple required label elements appear missing ({missing_count}/3 checks failed)",
                    is_actionable=True,
                )
            elif missing_count == 1:
                return TriageResult(
                    classification="requires_review",
                    confidence=0.55,
                    reason="Some label elements may be missing; admin review recommended",
                    is_actionable=True,
                )
            else:
                return TriageResult(
                    classification="apparently_compliant",
                    confidence=0.50,
                    reason="Label appears to contain required elements; admin may verify",
                    is_actionable=True,
                )

        except Exception as exc:
            logger.exception("AI triage failed: %s", exc)
            return TriageResult(
                classification="requires_review",
                confidence=0.0,
                reason=f"Triage error: {str(exc)}; defaulting to manual review",
                is_actionable=True,
            )
