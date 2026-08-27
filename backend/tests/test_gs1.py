"""
Project PARAKH — GS1 Integration Tests
"""

import pytest

from app.integrations.gs1_client import GS1Client


@pytest.mark.asyncio
async def test_gs1_unconfigured_api_key():
    """GS1 client returns SERVICE_UNAVAILABLE when API key is unset."""
    client = GS1Client()
    client.api_key = None
    result = await client.lookup_barcode("8901030000000")
    assert result.status == "SERVICE_UNAVAILABLE"


@pytest.mark.asyncio
async def test_gs1_empty_barcode():
    """GS1 client handles empty barcode gracefully."""
    client = GS1Client()
    result = await client.lookup_barcode("")
    assert result.status == "UNAVAILABLE"
