"""
Project PARAKH — OCR & Vision Pipeline Tests
"""

import numpy as np
import pytest

from app.ai.image_processor import ImageProcessor
from app.ai.nlp_extractor import NLPExtractor


def test_image_processor_blur_and_quality():
    processor = ImageProcessor()
    # Create blank solid image (low contrast/sharpness)
    blank_img = np.zeros((700, 700, 3), dtype=np.uint8)
    img_bytes = processor.image_to_bytes(blank_img)

    result = processor.process(img_bytes)
    assert result.quality_score < 0.3


@pytest.mark.asyncio
async def test_nlp_entity_extraction_patterns():
    extractor = NLPExtractor()
    sample_text = (
        "M.R.P. Rs. 145.00 (Incl. of all taxes)\n"
        "Net Weight: 400 g\n"
        "Mfg Date: 08/2026\n"
        "Exp Date: 08/2027\n"
        "Manufactured by: Parakh Agro Industries\n"
        "Consumer Care No: +91-1800-222-333\n"
        "Email: support@parakhagro.in\n"
    )
    result = await extractor.extract_entities(sample_text)
    assert result.success is True
    types = [e.entity_type for e in result.entities]
    assert "MRP" in types
    assert "NET_QUANTITY" in types
    assert "MFG_DATE" in types
    assert "CONSUMER_CARE_PHONE" in types
    assert "CONSUMER_CARE_EMAIL" in types
