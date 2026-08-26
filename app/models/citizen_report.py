"""
Project PARAKH — Citizen Report Model

PostgreSQL table: citizen_reports
Stores citizen-submitted product complaints. AI triage assists but
does not make legal determinations (§30).
"""

from __future__ import annotations

import uuid
from datetime import datetime, timezone

from sqlalchemy import DateTime, Float, ForeignKey, JSON, String, Text
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.postgres import Base


class CitizenReport(Base):
    __tablename__ = "citizen_reports"

    report_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
    )
    citizen_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.user_id", ondelete="RESTRICT"),
        nullable=False,
        index=True,
    )
    # Image path in object storage
    image_storage_path: Mapped[str | None] = mapped_column(Text, nullable=True)

    # Description from citizen
    description: Mapped[str | None] = mapped_column(Text, nullable=True)

    # Product barcode if scanned
    product_barcode: Mapped[str | None] = mapped_column(String(50), nullable=True)

    # Location
    latitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    longitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    location_name: Mapped[str | None] = mapped_column(String(500), nullable=True)

    # AI triage result (not a legal determination)
    # Values: blurry, irrelevant, potential_violation, apparently_compliant,
    #         requires_review, pending
    ai_triage_status: Mapped[str] = mapped_column(
        String(30), nullable=False, default="pending", index=True,
    )
    ai_triage_confidence: Mapped[float | None] = mapped_column(Float, nullable=True)
    ai_triage_details: Mapped[dict | None] = mapped_column(
        JSON().with_variant(JSONB, "postgresql"), nullable=True,
    )

    # Admin decision
    # Values: pending, approved, rejected, investigating
    admin_decision: Mapped[str] = mapped_column(
        String(20), nullable=False, default="pending", index=True,
    )
    admin_notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    reviewed_by: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.user_id", ondelete="SET NULL"),
        nullable=True,
    )

    # Source: "app", "whatsapp"
    source: Mapped[str] = mapped_column(
        String(20), nullable=False, default="app",
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
    reviewed_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True,
    )

    # Relationships
    citizen = relationship("User", back_populates="citizen_reports", foreign_keys=[citizen_id])

    def __repr__(self) -> str:
        return f"<CitizenReport {self.report_id} status={self.admin_decision}>"
