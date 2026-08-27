"""
Project PARAKH — Citizen Crowdsourcing Tests
"""

import numpy as np
import pytest

from app.ai.ai_triage import AITriage


def test_ai_triage_blurry_detection():
    triage = AITriage()
    # Solid black image has 0 laplacian variance (blurry/blank)
    blurry_img = np.zeros((300, 300, 3), dtype=np.uint8)
    res = triage.assess(blurry_img)
    assert res.classification == "blurry"
    assert res.is_actionable is False


def test_ai_triage_actionable_potential_violation():
    triage = AITriage()
    # Create an image with high variance
    np.random.seed(42)
    textured_img = np.random.randint(0, 255, (300, 300, 3), dtype=np.uint8)
    ocr_text = "Brand Name Biscuits. Packed at Factory A."  # Missing MRP, Expiry, Contact
    res = triage.assess(textured_img, ocr_text)
    assert res.classification in ("potential_violation", "requires_review")
    assert res.is_actionable is True
