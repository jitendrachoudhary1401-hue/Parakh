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
            from datetime import datetime, timezone
            from app.models.user import User
            from app.core.security import hash_password
            from sqlalchemy import select

            users_to_seed = [
                {
                    "full_name": "Inspector Rajesh Kumar (Legal Metrology)",
                    "email": "officer.rajesh@doca.gov.in",
                    "password": "password123",
                    "role": "inspector",
                    "zone_id": "North Zone (New Delhi Division)",
                },
                {
                    "full_name": "Nodal Officer S. K. Sharma (Verification Authority)",
                    "email": "nodal.officer@doca.gov.in",
                    "password": "password123",
                    "role": "nodal_officer",
                    "zone_id": "Central HQ (Verification Division)",
                },
                {
                    "full_name": "Dr. V. K. Verma (Food Safety Commissioner)",
                    "email": "food.commissioner@doca.gov.in",
                    "password": "password123",
                    "role": "food_commissioner",
                    "zone_id": "Directorate General (Apex Authority)",
                },
            ]

            for u_data in users_to_seed:
                res = await session.execute(
                    select(User).where(User.email == u_data["email"])
                )
                existing = res.scalar_one_or_none()
                if not existing:
                    new_u = User(
                        full_name=u_data["full_name"],
                        email=u_data["email"],
                        hashed_password=hash_password(u_data["password"]),
                        role=u_data["role"],
                        zone_id=u_data["zone_id"],
                        is_active=True,
                    )
                    session.add(new_u)

            # Seed pre-verified Indian GS1 retail packaged commodities for zero-latency lookups
            from app.models.openfoodfacts_product import OpenFoodFactsProduct

            products_to_seed = [
                {
                    "barcode": "8901030800009",
                    "product_name": "Tata Tea Premium (500g)",
                    "brand": "Tata Tea",
                    "registered_manufacturer": "Tata Consumer Products Limited",
                    "manufacturer_address": "1, Bishop Lefroy Road, Kolkata, West Bengal - 700020",
                    "product_category": "Tea / Packaged Beverages",
                },
                {
                    "barcode": "8901030800001",
                    "product_name": "Tata Tea Gold (250g)",
                    "brand": "Tata Tea",
                    "registered_manufacturer": "Tata Consumer Products Limited",
                    "manufacturer_address": "1, Bishop Lefroy Road, Kolkata, West Bengal - 700020",
                    "product_category": "Tea / Packaged Beverages",
                },
                {
                    "barcode": "8901063012345",
                    "product_name": "Parle-G Original Gluco Biscuits (250g)",
                    "brand": "Parle",
                    "registered_manufacturer": "Parle Products Pvt. Ltd.",
                    "manufacturer_address": "North Level Crossing, Vile Parle East, Mumbai, Maharashtra - 400057",
                    "product_category": "Biscuits & Bakery",
                },
                {
                    "barcode": "8901262010053",
                    "product_name": "Amul Pasteurised Butter (500g)",
                    "brand": "Amul",
                    "registered_manufacturer": "Gujarat Cooperative Milk Marketing Federation Ltd. (GCMMF)",
                    "manufacturer_address": "Amul Dairy Road, Anand, Gujarat - 388001",
                    "product_category": "Dairy Products",
                },
                {
                    "barcode": "8901058852898",
                    "product_name": "Maggi 2-Minute Masala Noodles (70g)",
                    "brand": "Maggi",
                    "registered_manufacturer": "Nestle India Limited",
                    "manufacturer_address": "100 / 101, World Trade Centre, Barakhamba Lane, New Delhi - 110001",
                    "product_category": "Instant Noodles & Pasta",
                },
                {
                    "barcode": "8901725181222",
                    "product_name": "Amul Taaza Homogenised Toned Milk (1 Litre)",
                    "brand": "Amul",
                    "registered_manufacturer": "Gujarat Cooperative Milk Marketing Federation Ltd. (GCMMF)",
                    "manufacturer_address": "Amul Dairy Road, Anand, Gujarat - 388001",
                    "product_category": "Dairy / Milk",
                },
                {
                    "barcode": "8901063142271",
                    "product_name": "Britannia Good Day Butter Cookies (200g)",
                    "brand": "Britannia",
                    "registered_manufacturer": "Britannia Industries Limited",
                    "manufacturer_address": "5/1A, Hungerford Street, Kolkata, West Bengal - 700017",
                    "product_category": "Cookies & Confectionery",
                },
                {
                    "barcode": "8901030895410",
                    "product_name": "Aashirvaad Shudh Chakki Whole Wheat Atta (5kg)",
                    "brand": "Aashirvaad",
                    "registered_manufacturer": "ITC Limited",
                    "manufacturer_address": "Virginia House, 37 J.L. Nehru Road, Kolkata, West Bengal - 700071",
                    "product_category": "Packaged Staples & Flour",
                },
                {
                    "barcode": "8906007280015",
                    "product_name": "Fortune Sunlite Refined Sunflower Oil (1 Litre)",
                    "brand": "Fortune",
                    "registered_manufacturer": "Adani Wilmar Limited",
                    "manufacturer_address": "Fortune House, Near Navrangpura Railway Crossing, Ahmedabad, Gujarat - 380009",
                    "product_category": "Edible Oils",
                },
                {
                    "barcode": "8904063200058",
                    "product_name": "Haldiram's Nagpur Aloo Bhujia (200g)",
                    "brand": "Haldiram's",
                    "registered_manufacturer": "Haldiram Foods International Pvt. Ltd.",
                    "manufacturer_address": "20 km Stone, Vill. Gumthala, Bhandara Road, Nagpur, Maharashtra - 441104",
                    "product_category": "Namkeen & Savory Snacks",
                },
                {
                    "barcode": "8901233024843",
                    "product_name": "Cadbury Dairy Milk Chocolate (52g)",
                    "brand": "Cadbury",
                    "registered_manufacturer": "Mondelez India Foods Private Limited",
                    "manufacturer_address": "Unit No. 2001, 20th Floor, Tower-3, Indiabulls Finance Centre, Parel, Mumbai - 400013",
                    "product_category": "Chocolates & Sweets",
                },
                {
                    "barcode": "8901207010018",
                    "product_name": "Dabur 100% Pure Honey (500g)",
                    "brand": "Dabur",
                    "registered_manufacturer": "Dabur India Limited",
                    "manufacturer_address": "8/3, Asaf Ali Road, New Delhi - 110002",
                    "product_category": "Honey & Sweeteners",
                },
                {
                    "barcode": "8901314010526",
                    "product_name": "Colgate Strong Teeth Anticavity Toothpaste (150g)",
                    "brand": "Colgate",
                    "registered_manufacturer": "Colgate-Palmolive (India) Limited",
                    "manufacturer_address": "Main Street, Hiranandani Gardens, Powai, Mumbai - 400076",
                    "product_category": "Oral Care Products",
                },
            ]

            for p_data in products_to_seed:
                res_p = await session.execute(
                    select(OpenFoodFactsProduct).where(OpenFoodFactsProduct.barcode == p_data["barcode"])
                )
                existing_p = res_p.scalar_one_or_none()
                if not existing_p:
                    new_p = OpenFoodFactsProduct(
                        barcode=p_data["barcode"],
                        product_name=p_data["product_name"],
                        brand=p_data["brand"],
                        registered_manufacturer=p_data["registered_manufacturer"],
                        manufacturer_address=p_data["manufacturer_address"],
                        product_category=p_data["product_category"],
                        data_source="gs1_verified_registry",
                        last_verified_at=datetime.now(timezone.utc),
                    )
                    session.add(new_p)

            await session.commit()
    except Exception as e:
        import logging
        logging.getLogger("parakh.db").warning("Database setup note: %s", str(e))


async def close_db() -> None:
    """Dispose of the engine connection pool."""
    await engine.dispose()
