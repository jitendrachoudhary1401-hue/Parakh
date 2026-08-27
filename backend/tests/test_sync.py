"""
Project PARAKH — Offline Sync Endpoint Tests
"""

import pytest
from httpx import AsyncClient
from app.models.user import User

@pytest.mark.asyncio
async def test_offline_sync_upload(client: AsyncClient, inspector_token: str):
    """Test successful offline sync upload batch."""
    payload = [
        {
            "client_inspection_id": "INSP-2026-TEST-999",
            "product_barcode": "8901030382910",
            "latitude": 28.6315,
            "longitude": 77.2167,
            "location_name": "Connaught Place, New Delhi",
            "notes": "Basement Grocery Mart, Connaught Place",
            "client_timestamp": "2026-08-28T01:13:29.000Z"
        }
    ]

    response = await client.post(
        "/api/v1/sync/upload",
        json=payload,
        headers={"Authorization": f"Bearer {inspector_token}"},
    )

    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert data["data"]["synced_count"] == 1
    assert data["data"]["failed_count"] == 0
