"""
Project PARAKH — Test Configuration & Fixtures
"""

from __future__ import annotations

import asyncio
import os
import uuid
from typing import AsyncGenerator

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

# Set test environment flags
os.environ["APP_ENV"] = "testing"
os.environ["DATABASE_URL"] = "sqlite+aiosqlite:///:memory:"
os.environ["REDIS_URL"] = "memory://"
os.environ["JWT_SECRET_KEY"] = "test-secret-key-for-unit-testing-32-chars-long"

from app.core.security import create_access_token, hash_password
from app.db.postgres import Base, get_db
from app.main import app
from app.models.user import User

TEST_DB_URL = "sqlite+aiosqlite:///:memory:"


@pytest.fixture(scope="session")
def event_loop():
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()


@pytest_asyncio.fixture(scope="function")
async def test_db_session() -> AsyncGenerator[AsyncSession, None]:
    """Provide isolated in-memory database session for tests."""
    engine = create_async_engine(TEST_DB_URL, echo=False)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async_session = async_sessionmaker(engine, expire_on_commit=False, class_=AsyncSession)
    async with async_session() as session:
        yield session

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
    await engine.dispose()


@pytest_asyncio.fixture(scope="function")
async def client(test_db_session: AsyncSession) -> AsyncGenerator[AsyncClient, None]:
    """FastAPI TestClient with overridden database dependency."""
    async def override_get_db():
        yield test_db_session

    app.dependency_overrides[get_db] = override_get_db
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac
    app.dependency_overrides.clear()


@pytest_asyncio.fixture
async def sample_inspector(test_db_session: AsyncSession) -> User:
    """Create test inspector user."""
    user = User(
        user_id=uuid.uuid4(),
        full_name="Inspector Rajesh Kumar",
        email="inspector@parakh.gov.in",
        hashed_password=hash_password("Password123!"),
        role="inspector",
        zone_id="ZONE-NORTH-01",
        is_active=True,
    )
    test_db_session.add(user)
    await test_db_session.commit()
    await test_db_session.refresh(user)
    return user


@pytest_asyncio.fixture
async def sample_admin(test_db_session: AsyncSession) -> User:
    """Create test admin user."""
    user = User(
        user_id=uuid.uuid4(),
        full_name="Nodal Officer Sharma",
        email="admin@parakh.gov.in",
        hashed_password=hash_password("AdminPass123!"),
        role="admin",
        zone_id="HQ",
        is_active=True,
    )
    test_db_session.add(user)
    await test_db_session.commit()
    await test_db_session.refresh(user)
    return user


@pytest.fixture
def inspector_token(sample_inspector: User) -> str:
    claims = {
        "sub": str(sample_inspector.user_id),
        "email": sample_inspector.email,
        "role": sample_inspector.role,
        "zone_id": sample_inspector.zone_id,
    }
    return create_access_token(claims)


@pytest.fixture
def admin_token(sample_admin: User) -> str:
    claims = {
        "sub": str(sample_admin.user_id),
        "email": sample_admin.email,
        "role": sample_admin.role,
        "zone_id": sample_admin.zone_id,
    }
    return create_access_token(claims)
