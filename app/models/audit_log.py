"""
Project PARAKH — Audit Log Model

PostgreSQL table: audit_logs
Immutable audit trail per §37. Records all security-relevant events.
"""

from __future__ import annotations

import uuid
from datetime import datetime, timezone

from sqlalchemy import DateTime, JSON, String, Text
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import Mapped, mapped_column

from app.db.postgres import Base


class AuditLog(Base):
    __tablename__ = "audit_logs"

    log_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
    )
    # Who performed the action (nullable for system events)
    user_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), nullable=True, index=True,
    )
    user_email: Mapped[str | None] = mapped_column(
        String(255), nullable=True,
    )
    user_role: Mapped[str | None] = mapped_column(
        String(20), nullable=True,
    )

    # What happened
    action: Mapped[str] = mapped_column(
        String(100), nullable=False, index=True,
    )
    # Resource type: user, inspection, evidence, citizen_report, legal_notice, etc.
    resource_type: Mapped[str | None] = mapped_column(
        String(50), nullable=True, index=True,
    )
    resource_id: Mapped[str | None] = mapped_column(
        String(100), nullable=True,
    )

    # Details of the action
    details: Mapped[dict | None] = mapped_column(
        JSON().with_variant(JSONB, "postgresql"), nullable=True,
    )

    # Request metadata
    ip_address: Mapped[str | None] = mapped_column(String(45), nullable=True)
    user_agent: Mapped[str | None] = mapped_column(Text, nullable=True)
    request_method: Mapped[str | None] = mapped_column(String(10), nullable=True)
    request_path: Mapped[str | None] = mapped_column(String(500), nullable=True)

    # Outcome
    status: Mapped[str] = mapped_column(
        String(20), nullable=False, default="success",
    )

    # Immutable timestamp
    timestamp: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
        index=True,
    )

    def __repr__(self) -> str:
        return f"<AuditLog {self.action} by={self.user_email} at={self.timestamp}>"
