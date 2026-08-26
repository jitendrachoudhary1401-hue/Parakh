"""
Project PARAKH — Legal Notice Model

PostgreSQL table: legal_notices
Stores generated PDF legal notices based on actual inspection data (§26).
Never populates missing information with fake data.
"""

from __future__ import annotations

import uuid
from datetime import datetime, timezone

from sqlalchemy import DateTime, ForeignKey, JSON, String, Text
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.postgres import Base


class LegalNotice(Base):
    __tablename__ = "legal_notices"

    notice_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
    )
    inspection_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("inspections.inspection_id", ondelete="RESTRICT"),
        nullable=False,
        index=True,
    )
    generated_by: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.user_id", ondelete="RESTRICT"),
        nullable=False,
    )

    # PDF storage
    pdf_storage_path: Mapped[str | None] = mapped_column(Text, nullable=True)

    # Notice content snapshot
    product_info: Mapped[dict | None] = mapped_column(
        JSON().with_variant(JSONB, "postgresql"), nullable=True,
    )
    violations: Mapped[dict | None] = mapped_column(
        JSON().with_variant(JSONB, "postgresql"), nullable=True,
    )
    compliance_results: Mapped[dict | None] = mapped_column(
        JSON().with_variant(JSONB, "postgresql"), nullable=True,
    )
    evidence_references: Mapped[dict | None] = mapped_column(
        JSON().with_variant(JSONB, "postgresql"), nullable=True,
    )

    # Inspector / location info
    inspector_name: Mapped[str | None] = mapped_column(String(255), nullable=True)
    inspection_location: Mapped[str | None] = mapped_column(Text, nullable=True)
    blockchain_receipt: Mapped[str | None] = mapped_column(String(256), nullable=True)

    # Status: draft, generated, served, acknowledged
    status: Mapped[str] = mapped_column(
        String(20), nullable=False, default="draft", index=True,
    )

    # Timestamps
    generated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )
    served_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True,
    )

    # Relationships
    inspection = relationship("Inspection", back_populates="legal_notices")

    def __repr__(self) -> str:
        return f"<LegalNotice {self.notice_id} status={self.status}>"
