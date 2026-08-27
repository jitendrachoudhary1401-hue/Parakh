"""
Project PARAKH — Open Food Facts API Integration Tests
"""

import pytest
from unittest.mock import patch, MagicMock

from app.integrations.openfoodfacts_client import OpenFoodFactsClient
from app.integrations.gs1_client import GS1Client


@pytest.mark.asyncio
async def test_openfoodfacts_empty_barcode():
    """Open Food Facts client handles empty barcode gracefully."""
    client = OpenFoodFactsClient()
    result = await client.lookup_barcode("")
    assert result.status == "UNAVAILABLE"
    assert "No barcode provided" in result.error_message


@pytest.mark.asyncio
async def test_openfoodfacts_invalid_barcode():
    """Open Food Facts client handles invalid non-digit barcode."""
    client = OpenFoodFactsClient()
    result = await client.lookup_barcode("abc")
    assert result.status == "UNAVAILABLE"


@pytest.mark.asyncio
async def test_openfoodfacts_live_api_lookup_success():
    """Open Food Facts client parses valid v2 product JSON response correctly."""
    client = OpenFoodFactsClient()

    mock_data = {
        "code": "8901030382910",
        "status": 1,
        "status_verbose": "product found",
        "product": {
            "product_name": "Lipton Green Tea Honey Lemon",
            "brands": "Lipton, Hindustan Unilever Limited",
            "manufacturing_places": "Mumbai, Maharashtra, India",
            "categories": "Beverages, Teas, Green teas",
            "quantity": "250 g",
            "countries": "India",
            "ingredients_text": "Green tea leaves, Honey, Lemon flavor",
        },
    }

    mock_response = MagicMock()
    mock_response.status_code = 200
    mock_response.json.return_value = mock_data

    with patch("httpx.AsyncClient.get", return_value=mock_response):
        result = await client.lookup_barcode("8901030382910")
        assert result.status == "FOUND"
        assert result.product_name == "Lipton Green Tea Honey Lemon"
        assert "Lipton" in result.brand
        assert result.quantity == "250 g"


@pytest.mark.asyncio
async def test_gs1_client_backwards_compatibility():
    """GS1Client inherits OpenFoodFactsClient behavior."""
    client = GS1Client()
    result = await client.lookup_barcode("")
    assert result.status == "UNAVAILABLE"
