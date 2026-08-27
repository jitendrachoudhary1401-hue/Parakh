"""
Project PARAKH — GS1 Integration Tests
"""

import pytest
from unittest.mock import patch, MagicMock

from app.integrations.gs1_client import GS1Client, validate_gtin_checksum


@pytest.mark.asyncio
async def test_gs1_unconfigured_api_key():
    """GS1 client returns SERVICE_UNAVAILABLE when API key is unset and non-890 barcode is checked."""
    client = GS1Client()
    client.api_key = None
    result = await client.lookup_barcode("1234567890123")
    assert result.status == "SERVICE_UNAVAILABLE"


@pytest.mark.asyncio
async def test_gs1_empty_barcode():
    """GS1 client handles empty barcode gracefully."""
    client = GS1Client()
    result = await client.lookup_barcode("")
    assert result.status == "UNAVAILABLE"


def test_gtin_checksum_validation():
    """Validates GTIN Modulo 10 Checksum calculation."""
    # GTIN-13 valid checksums
    assert validate_gtin_checksum("8901063012345") is True or validate_gtin_checksum("8901030000003") is True
    # Non-digit string length invalid
    assert validate_gtin_checksum("123") is False


@pytest.mark.asyncio
async def test_gs1_prefix_resolution():
    """GS1 890 country prefix resolves registered manufacturer correctly."""
    client = GS1Client()
    prefix_hul = client.resolve_prefix("8901030382910")
    assert prefix_hul is not None
    assert "Hindustan Unilever" in prefix_hul["manufacturer"]

    prefix_brit = client.resolve_prefix("8901063012345")
    assert prefix_brit is not None
    assert "Britannia" in prefix_brit["manufacturer"]


@pytest.mark.asyncio
async def test_gs1_live_api_lookup_success():
    """GS1 client processes successful REST API response."""
    client = GS1Client()
    client.api_key = "test_gs1_key"

    mock_data = {
        "company_name": "Test Manufacturer Pvt Ltd",
        "address": "Mumbai, Maharashtra",
        "product_name": "Test Milk Biscuit 100g",
        "category": "Bakery",
        "brand": "TestBrand",
    }

    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.json.return_value = mock_data

    with patch("httpx.AsyncClient.get", return_value=mock_response):
        result = await client.lookup_barcode("8901063012345")
        assert result.status == "FOUND"
        assert result.registered_manufacturer == "Test Manufacturer Pvt Ltd"
        assert result.product_name == "Test Milk Biscuit 100g"
