"""
Project PARAKH — OCR & Vision Pipeline Tests
"""

import numpy as np
import pytest
from unittest.mock import MagicMock, patch

from app.ai.image_processor import ImageProcessor
from app.ai.nlp_extractor import NLPExtractor
from app.ai.ocr_engine import OCREngine


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


@pytest.mark.asyncio
async def test_ocr_engine_empty_input():
    """OCR engine handles empty input gracefully."""
    engine = OCREngine()
    result = await engine.extract_text(b"")
    assert result.success is False
    assert "Empty image bytes" in result.error_message


@pytest.mark.asyncio
async def test_ocr_engine_vision_client_mock():
    """OCREngine extracts text from Google Cloud Vision response."""
    engine = OCREngine()

    mock_client = MagicMock()
    mock_annotation = MagicMock()
    mock_annotation.text = "MRP Rs 150 Net Wt 500g Manufactured by Britannia"
    mock_annotation.pages = []
    
    mock_response = MagicMock()
    mock_response.error.message = ""
    mock_response.full_text_annotation = mock_annotation

    mock_client.document_text_detection.return_value = mock_response

    with patch.object(engine, "_get_client", return_value=mock_client):
        result = await engine.extract_text(b"fake_image_bytes")
        assert result.success is True
        assert "Britannia" in result.raw_text
        assert "MRP" in result.raw_text
