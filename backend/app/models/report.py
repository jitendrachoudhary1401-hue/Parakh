"""
Project PARAKH — Official Report Model

Stores metadata, cryptographic hashes, and storage paths for generated
statutory reports, evidentiary dossiers, and legal notices.
"""

from __future__ import annotations

import uuid
from datetime import datetime, timezone

from sqlalchemy import DateTime, ForeignKey, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.postgres import Base


class Report(Base):
    __tablename__ = "reports"

    report_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
    )
    inspection_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("inspections.inspection_id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    generated_by_user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.user_id", ondelete="RESTRICT"),
        nullable=False,
        index=True,
    )
    report_type: Mapped[str] = mapped_column(
        String(50),
        nullable=False,
        default="LEGAL_SHOW_CAUSE",
        index=True,
    )
    pdf_url: Mapped[str] = mapped_column(Text, nullable=False)
    file_hash: Mapped[str] = mapped_column(String(64), nullable=False)
    # Status lifecycle: DRAFT, PENDING_NODAL_REVIEW, FORWARDED_TO_COMMISSIONER, CERTIFIED
    status: Mapped[str] = mapped_column(String(50), nullable=False, default="DRAFT", index=True)

    # Inspector stage
    inspector_notes: Mapped[str | None] = mapped_column(Text, nullable=True)

    # Nodal Officer stage
    nodal_officer_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.user_id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    nodal_comments: Mapped[str | None] = mapped_column(Text, nullable=True)
    nodal_reviewed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    # Food Safety Commissioner stage
    commissioner_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.user_id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    commissioner_comments: Mapped[str | None] = mapped_column(Text, nullable=True)
    commissioner_certified_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    digital_signature_hash: Mapped[str | None] = mapped_column(String(64), nullable=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    # Relationships
    inspection = relationship("Inspection")
    generated_by = relationship("User", foreign_keys=[generated_by_user_id])
    nodal_officer = relationship("User", foreign_keys=[nodal_officer_id])
    commissioner = relationship("User", foreign_keys=[commissioner_id])

    def __repr__(self) -> str:
        return f"<Report {self.report_id} status={self.status} hash={self.file_hash[:8]}>"
