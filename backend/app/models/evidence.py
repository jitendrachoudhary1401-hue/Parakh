"""
Project PARAKH — Evidence Model

PostgreSQL table: evidence
Stores blockchain-committed evidence packages with SHA-256 hashes (§23, §24).
Never fabricates transaction IDs or blockchain receipts.
"""

from __future__ import annotations

import uuid
from datetime import datetime, timezone

from sqlalchemy import DateTime, Float, ForeignKey, JSON, String, Text
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.postgres import Base


class Evidence(Base):
    __tablename__ = "evidence"

    evidence_id: Mapped[uuid.UUID] = mapped_column(
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
    inspector_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.user_id", ondelete="RESTRICT"),
        nullable=False,
    )

    # Evidence payload hash (SHA-256)
    payload_hash: Mapped[str] = mapped_column(
        String(128), nullable=False, index=True,
    )

    # Payload contents (for recalculation / verification)
    image_storage_path: Mapped[str | None] = mapped_column(Text, nullable=True)
    gps_latitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    gps_longitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    capture_timestamp: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True,
    )
    ocr_text_snapshot: Mapped[str | None] = mapped_column(Text, nullable=True)
    violation_data: Mapped[dict | None] = mapped_column(
        JSON().with_variant(JSONB, "postgresql"), nullable=True,
    )

    # Blockchain commitment status
    # Values: pending, committed, failed, unavailable
    blockchain_status: Mapped[str] = mapped_column(
        String(20), nullable=False, default="pending", index=True,
    )
    blockchain_tx_id: Mapped[str | None] = mapped_column(
        String(256), nullable=True,
    )
    blockchain_receipt: Mapped[dict | None] = mapped_column(
        JSON().with_variant(JSONB, "postgresql"), nullable=True,
    )

    # Verification
    # Values: unverified, verified, mismatch
    verification_status: Mapped[str] = mapped_column(
        String(20), nullable=False, default="unverified",
    )
    last_verified_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True,
    )
    verified_by_user_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.user_id", ondelete="SET NULL"),
        nullable=True,
    )

    # Timestamps
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    # Relationships
    inspection = relationship("Inspection", back_populates="evidence_records")

    def __repr__(self) -> str:
        return (
            f"<Evidence {self.evidence_id} "
            f"blockchain={self.blockchain_status}>"
        )
