"""
Project PARAKH — Legal Document & Statutory Version Model

PostgreSQL table: legal_documents
Tracks official statutory documents (Acts, Rules, Gazette Amendments) and their
cryptographic SHA-256 hashes to establish an immutable audit trail for compliance checks.
"""

from __future__ import annotations

import uuid
from datetime import date, datetime, timezone

from sqlalchemy import Boolean, Date, DateTime, JSON, String, Text, ForeignKey
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.postgres import Base


class LegalDocument(Base):
    __tablename__ = "legal_documents"

    # law_id: UUID (PK) — Unique identifier for the document
    law_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
    )
    # title: VARCHAR — e.g., "Packaged Commodities Rules, 2011"
    title: Mapped[str] = mapped_column(
        String(255),
        nullable=False,
        index=True,
    )
    # version_hash: VARCHAR — SHA-256 hash of the PDF to detect changes
    version_hash: Mapped[str] = mapped_column(
        String(64),
        nullable=False,
        index=True,
    )
    # effective_date: DATE — When the rule or amendment went into effect
    effective_date: Mapped[date] = mapped_column(
        Date,
        nullable=False,
        index=True,
    )
    # document_url: VARCHAR — Link back to the official DoCA PDF
    document_url: Mapped[str] = mapped_column(
        String(500),
        nullable=False,
    )
    # Structured rules JSON payload
    rules_json: Mapped[dict | None] = mapped_column(
        JSON().with_variant(JSONB, "postgresql"),
        nullable=True,
    )
    # Active flag for latest statutory version
    is_active: Mapped[bool] = mapped_column(
        Boolean,
        default=True,
        nullable=False,
        index=True,
    )
    # Description / gazette notification number
    gazette_notification: Mapped[str | None] = mapped_column(
        String(255),
        nullable=True,
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

    # Relationships
    inspections = relationship("Inspection", back_populates="legal_document", lazy="selectin")
