"""
Project PARAKH — Open Food Facts Product Repository
"""

from __future__ import annotations

from typing import Optional

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.openfoodfacts_product import OpenFoodFactsProduct


class OpenFoodFactsRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_by_barcode(self, barcode: str) -> Optional[OpenFoodFactsProduct]:
        result = await self.db.execute(
            select(OpenFoodFactsProduct).where(OpenFoodFactsProduct.barcode == barcode)
        )
        return result.scalar_one_or_none()

    async def upsert(self, product: OpenFoodFactsProduct) -> OpenFoodFactsProduct:
        """Insert or update an Open Food Facts product record from API lookup."""
        existing = await self.get_by_barcode(product.barcode)
        if existing:
            existing.registered_manufacturer = product.registered_manufacturer
            existing.manufacturer_address = product.manufacturer_address
            existing.product_name = product.product_name
            existing.product_category = product.product_category
            existing.brand = product.brand
            existing.metadata_json = product.metadata_json
            existing.last_verified_at = product.last_verified_at
            await self.db.flush()
            await self.db.refresh(existing)
            return existing
        else:
            self.db.add(product)
            await self.db.flush()
            await self.db.refresh(product)
            return product


# Alias for backwards compatibility
GS1Repository = OpenFoodFactsRepository
