"""
Project PARAKH — Inspection Model

PostgreSQL table: inspections
Fields per §12: inspection_id, inspector_id, timestamp, geographic location,
status, blockchain hash/reference, product reference.
"""

from __future__ import annotations

import uuid
from datetime import datetime, timezone

from sqlalchemy import DateTime, Float, ForeignKey, JSON, String, Text
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.postgres import Base


class Inspection(Base):
    __tablename__ = "inspections"

    inspection_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
    )
    inspector_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.user_id", ondelete="RESTRICT"),
        nullable=False,
        index=True,
    )
    product_barcode: Mapped[str | None] = mapped_column(
        String(50), nullable=True, index=True,
    )
    # Geographic location
    latitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    longitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    location_name: Mapped[str | None] = mapped_column(String(500), nullable=True)

    # Status: pending, processing, compliant, violation, requires_review,
    # insufficient_data, error
    status: Mapped[str] = mapped_column(
        String(30), nullable=False, default="pending", index=True,
    )

    # Overall compliance result
    overall_result: Mapped[str | None] = mapped_column(
        String(30), nullable=True,
    )

    # Image reference in object storage
    image_storage_path: Mapped[str | None] = mapped_column(Text, nullable=True)
    processed_image_path: Mapped[str | None] = mapped_column(Text, nullable=True)

    # Blockchain reference
    blockchain_hash: Mapped[str | None] = mapped_column(String(128), nullable=True)
    blockchain_tx_id: Mapped[str | None] = mapped_column(String(256), nullable=True)

    # Metadata
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    metadata_json: Mapped[dict | None] = mapped_column(
        JSON().with_variant(JSONB, "postgresql"), nullable=True,
    )

    # Timestamps
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
        index=True,
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    # Relationships
    inspector = relationship("User", back_populates="inspections")
    evidence_records = relationship(
        "Evidence", back_populates="inspection", lazy="selectin",
    )
    legal_notices = relationship(
        "LegalNotice", back_populates="inspection", lazy="selectin",
    )

    def __repr__(self) -> str:
        return f"<Inspection {self.inspection_id} status={self.status}>"
