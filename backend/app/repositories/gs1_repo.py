"""
Project PARAKH — GS1 Product Repository
"""

from __future__ import annotations

from typing import Optional

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.gs1_product import GS1Product


class GS1Repository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_by_barcode(self, barcode: str) -> Optional[GS1Product]:
        result = await self.db.execute(
            select(GS1Product).where(GS1Product.barcode == barcode)
        )
        return result.scalar_one_or_none()

    async def upsert(self, product: GS1Product) -> GS1Product:
        """Insert or update a GS1 product record from API lookup."""
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
