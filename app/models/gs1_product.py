"""
Project PARAKH — GS1 Product Model

PostgreSQL table: gs1_products
Fields per §12: barcode, registered manufacturer, product category, metadata.
Data comes from GS1 India API — never fabricated.
"""

from __future__ import annotations

from datetime import datetime, timezone

from sqlalchemy import DateTime, JSON, String, Text
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from app.db.postgres import Base


class GS1Product(Base):
    __tablename__ = "gs1_products"

    barcode: Mapped[str] = mapped_column(
        String(50), primary_key=True,
    )
    registered_manufacturer: Mapped[str | None] = mapped_column(
        String(500), nullable=True,
    )
    manufacturer_address: Mapped[str | None] = mapped_column(
        Text, nullable=True,
    )
    product_name: Mapped[str | None] = mapped_column(
        String(500), nullable=True,
    )
    product_category: Mapped[str | None] = mapped_column(
        String(255), nullable=True, index=True,
    )
    brand: Mapped[str | None] = mapped_column(
        String(255), nullable=True,
    )
    metadata_json: Mapped[dict | None] = mapped_column(
        JSON().with_variant(JSONB, "postgresql"), nullable=True,
    )
    # Source: "gs1_api", "manual_entry"
    data_source: Mapped[str] = mapped_column(
        String(50), nullable=False, default="gs1_api",
    )
    last_verified_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True,
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    def __repr__(self) -> str:
        return f"<GS1Product barcode={self.barcode}>"
