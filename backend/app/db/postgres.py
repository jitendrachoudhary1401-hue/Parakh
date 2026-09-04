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
    Initialise database tables and seed default admin/inspector accounts.
    """
    try:
        import app.models  # Ensures all ORM models are registered with Base.metadata
        from sqlalchemy import text

        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)

            # Ensure schema columns exist on existing tables (non-destructive sync)
            migration_sqls = [
                "ALTER TABLE inspections ADD COLUMN IF NOT EXISTS law_id UUID;",
                "ALTER TABLE inspections ADD COLUMN IF NOT EXISTS metadata_json JSONB;",
                "ALTER TABLE inspections ADD COLUMN IF NOT EXISTS processed_image_path TEXT;",
                "ALTER TABLE inspections ADD COLUMN IF NOT EXISTS overall_result VARCHAR(30);",
                "ALTER TABLE inspections ADD COLUMN IF NOT EXISTS blockchain_hash VARCHAR(128);",
                "ALTER TABLE inspections ADD COLUMN IF NOT EXISTS blockchain_tx_id VARCHAR(256);",
                "ALTER TABLE inspections ADD COLUMN IF NOT EXISTS location_name VARCHAR(500);",
            ]
            for stmt in migration_sqls:
                try:
                    await conn.execute(text(stmt))
                except Exception as alter_e:
                    import logging
                    logging.getLogger("parakh.db").debug("Migration statement skipped: %s", alter_e)

        async with async_session_factory() as session:
            from app.models.user import User
            from app.core.security import hash_password
            from sqlalchemy import select

            result = await session.execute(
                select(User).where(User.email == "officer.rajesh@doca.gov.in")
            )
            user = result.scalar_one_or_none()
            if not user:
                default_user = User(
                    full_name="Inspector Rajesh Kumar (Legal Metrology)",
                    email="officer.rajesh@doca.gov.in",
                    hashed_password=hash_password("password123"),
                    role="inspector",
                    zone_id="North Zone (New Delhi Division)",
                    is_active=True,
                )
                session.add(default_user)
                await session.commit()
    except Exception as e:
        import logging
        logging.getLogger("parakh.db").warning("Database setup note: %s", str(e))


async def close_db() -> None:
    """Dispose of the engine connection pool."""
    await engine.dispose()
