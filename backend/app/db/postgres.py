"""
Project PARAKH — PostgreSQL Database Connection

Async SQLAlchemy engine and session factory with connection pooling.
"""

from __future__ import annotations

from typing import AsyncGenerator

from sqlalchemy.ext.asyncio import (
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)
from sqlalchemy.orm import DeclarativeBase

from app.config import get_settings


class Base(DeclarativeBase):
    """Base class for all SQLAlchemy ORM models."""
    pass


def _build_engine():
    settings = get_settings()
    if "sqlite" in settings.database_url:
        return create_async_engine(
            settings.database_url,
            echo=settings.debug,
        )
    return create_async_engine(
        settings.database_url,
        pool_size=settings.db_pool_size,
        max_overflow=settings.db_max_overflow,
        pool_pre_ping=True,
        echo=settings.debug,
    )


engine = _build_engine()

async_session_factory = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
)


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """
    FastAPI dependency that provides an async database session.

    The session is automatically committed on success and rolled back on error.
    """
    async with async_session_factory() as session:
        try:
            yield session
            if session.is_active:
                await session.commit()
        except Exception:
            if session.is_active:
                await session.rollback()
            raise
        finally:
            await session.close()


async def init_db() -> None:
    """
    Initialise database tables and seed the 3 official SIH demo accounts:
    1. Food Inspector
    2. Nodal Officer
    3. Food Safety Commissioner
    """
    try:
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)

        async with async_session_factory() as session:
            from app.models.user import User, UserRole
            from app.core.security import hash_password
            from sqlalchemy import select

            demo_accounts = [
                {
                    "full_name": "Priya Sharma (Food Safety Officer)",
                    "email": "inspector.sharma@doca.gov.in",
                    "official_uid": "DOCA-FI-2026-0101",
                    "role": UserRole.FOOD_INSPECTOR,
                    "zone_id": "North Zone (New Delhi Division)",
                    "password": "Inspector@2026",
                },
                {
                    "full_name": "Rajesh Verma (Zonal Nodal Officer)",
                    "email": "nodal.verma@doca.gov.in",
                    "official_uid": "DOCA-NO-2026-0202",
                    "role": UserRole.NODAL_OFFICER,
                    "zone_id": "North Zone (New Delhi Division)",
                    "password": "Nodal@2026",
                },
                {
                    "full_name": "Dr. Ananya Iyer (Food Safety Commissioner)",
                    "email": "commissioner.iyer@doca.gov.in",
                    "official_uid": "DOCA-FSC-2026-0303",
                    "role": UserRole.FOOD_SAFETY_COMMISSIONER,
                    "zone_id": "National Headquarters (DoCA)",
                    "password": "Commissioner@2026",
                },
            ]

            for acc in demo_accounts:
                res = await session.execute(
                    select(User).where(
                        (User.email == acc["email"]) | (User.official_uid == acc["official_uid"])
                    )
                )
                existing = res.scalar_one_or_none()
                if not existing:
                    user_obj = User(
                        full_name=acc["full_name"],
                        email=acc["email"],
                        official_uid=acc["official_uid"],
                        hashed_password=hash_password(acc["password"]),
                        role=acc["role"],
                        zone_id=acc["zone_id"],
                        is_active=True,
                    )
                    session.add(user_obj)
                else:
                    # Update credentials / role if needed
                    existing.official_uid = acc["official_uid"]
                    existing.role = acc["role"]
                    existing.hashed_password = hash_password(acc["password"])
                    existing.full_name = acc["full_name"]
                    existing.zone_id = acc["zone_id"]

            await session.commit()
    except Exception as e:
        import logging
        logging.getLogger("parakh.db").warning("Database setup note: %s", str(e))


async def close_db() -> None:
    """Dispose of the engine connection pool."""
    await engine.dispose()
