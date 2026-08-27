"""
Project PARAKH — Inspection Repository
"""

from __future__ import annotations

from datetime import datetime
from typing import List, Optional
from uuid import UUID

from sqlalchemy import select, func, and_
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.inspection import Inspection


class InspectionRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_by_id(self, inspection_id: UUID) -> Optional[Inspection]:
        result = await self.db.execute(
            select(Inspection).where(Inspection.inspection_id == inspection_id)
        )
        return result.scalar_one_or_none()

    async def list_inspections(
        self,
        offset: int = 0,
        limit: int = 20,
        status: Optional[str] = None,
        overall_result: Optional[str] = None,
        inspector_id: Optional[UUID] = None,
        product_barcode: Optional[str] = None,
        date_from: Optional[datetime] = None,
        date_to: Optional[datetime] = None,
    ) -> tuple[List[Inspection], int]:
        query = select(Inspection)
        count_query = select(func.count()).select_from(Inspection)

        conditions = []
        if status:
            conditions.append(Inspection.status == status)
        if overall_result:
            conditions.append(Inspection.overall_result == overall_result)
        if inspector_id:
            conditions.append(Inspection.inspector_id == inspector_id)
        if product_barcode:
            conditions.append(Inspection.product_barcode == product_barcode)
        if date_from:
            conditions.append(Inspection.created_at >= date_from)
        if date_to:
            conditions.append(Inspection.created_at <= date_to)

        if conditions:
            combined = and_(*conditions)
            query = query.where(combined)
            count_query = count_query.where(combined)

        query = query.order_by(Inspection.created_at.desc()).offset(offset).limit(limit)

        result = await self.db.execute(query)
        total_result = await self.db.execute(count_query)

        return list(result.scalars().all()), total_result.scalar_one()

    async def create(self, inspection: Inspection) -> Inspection:
        self.db.add(inspection)
        await self.db.flush()
        await self.db.refresh(inspection)
        return inspection

    async def update(self, inspection: Inspection) -> Inspection:
        await self.db.flush()
        await self.db.refresh(inspection)
        return inspection

    async def count_by_status(self) -> dict[str, int]:
        """Count inspections grouped by status for analytics."""
        result = await self.db.execute(
            select(Inspection.status, func.count())
            .group_by(Inspection.status)
        )
        return {row[0]: row[1] for row in result.all()}

    async def count_by_result(self) -> dict[str, int]:
        """Count inspections grouped by overall_result."""
        result = await self.db.execute(
            select(Inspection.overall_result, func.count())
            .group_by(Inspection.overall_result)
        )
        return {(row[0] or "null"): row[1] for row in result.all()}

    async def get_geographic_data(self) -> List[Inspection]:
        """Get inspections with valid geographic coordinates for heatmaps."""
        result = await self.db.execute(
            select(Inspection)
            .where(
                and_(
                    Inspection.latitude.isnot(None),
                    Inspection.longitude.isnot(None),
                )
            )
        )
        return list(result.scalars().all())
