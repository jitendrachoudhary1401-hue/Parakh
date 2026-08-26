"""
Project PARAKH — Authentication & RBAC Tests

Per §46: Valid login, invalid login, expired token, RBAC authorization.
"""

import pytest
from httpx import AsyncClient

from app.models.user import User


@pytest.mark.asyncio
async def test_valid_login(client: AsyncClient, sample_inspector: User):
    """Test successful login returns access and refresh tokens."""
    response = await client.post(
        "/api/v1/auth/login",
        json={"email": sample_inspector.email, "password": "Password123!"},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert "access_token" in data["data"]
    assert "refresh_token" in data["data"]
    assert data["data"]["token_type"] == "bearer"


@pytest.mark.asyncio
async def test_invalid_login(client: AsyncClient, sample_inspector: User):
    """Test login with wrong password fails with 401."""
    response = await client.post(
        "/api/v1/auth/login",
        json={"email": sample_inspector.email, "password": "WrongPassword123!"},
    )
    assert response.status_code == 401
    data = response.json()
    assert data["success"] is False
    assert data["error"]["code"] == "UNAUTHORIZED"


@pytest.mark.asyncio
async def test_rbac_inspector_access(client: AsyncClient, inspector_token: str):
    """Inspector should access /api/v1/users/me."""
    response = await client.get(
        "/api/v1/users/me",
        headers={"Authorization": f"Bearer {inspector_token}"},
    )
    assert response.status_code == 200
    assert response.json()["data"]["role"] == "inspector"


@pytest.mark.asyncio
async def test_rbac_inspector_forbidden_on_admin_endpoint(client: AsyncClient, inspector_token: str):
    """Inspector should be blocked from accessing admin-only endpoint /api/v1/users/."""
    response = await client.get(
        "/api/v1/users/",
        headers={"Authorization": f"Bearer {inspector_token}"},
    )
    assert response.status_code == 403


@pytest.mark.asyncio
async def test_rbac_admin_allowed_on_admin_endpoint(client: AsyncClient, admin_token: str):
    """Admin should successfully access /api/v1/users/."""
    response = await client.get(
        "/api/v1/users/",
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert response.status_code == 200
