"""
Project PARAKH — PostgreSQL Task Queue Model

PostgreSQL table: task_queue
Provides background job queuing, task lifecycle tracking, and retry management directly in PostgreSQL.
"""

from __future__ import annotations

import uuid
from datetime import datetime, timezone

from sqlalchemy import DateTime, Integer, JSON, String, Text
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import Mapped, mapped_column

from app.db.postgres import Base


class TaskQueue(Base):
    __tablename__ = "task_queue"

    task_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
    )
    # Task type, e.g., 'ocr_extraction', 'compliance_analysis', 'blockchain_anchor', 'notice_generation'
    task_type: Mapped[str] = mapped_column(
        String(100),
        nullable=False,
        index=True,
    )
    # Status: pending, processing, completed, failed, retrying
    status: Mapped[str] = mapped_column(
        String(30),
        nullable=False,
        default="pending",
        index=True,
    )
    # Job payload & configuration
    payload: Mapped[dict | None] = mapped_column(
        JSON().with_variant(JSONB, "postgresql"),
        nullable=True,
    )
    # Job result or error output
    result: Mapped[dict | None] = mapped_column(
        JSON().with_variant(JSONB, "postgresql"),
        nullable=True,
    )
    error_message: Mapped[str | None] = mapped_column(
        Text,
        nullable=True,
    )

    # Queue management
    priority: Mapped[int] = mapped_column(
        Integer,
        default=0,
        index=True,
    )
    attempts: Mapped[int] = mapped_column(
        Integer,
        default=0,
    )
    max_attempts: Mapped[int] = mapped_column(
        Integer,
        default=3,
    )

    # Timestamps
    scheduled_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
        index=True,
    )
    started_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )
    completed_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    def __repr__(self) -> str:
        return f"<TaskQueue id={self.task_id} type='{self.task_type}' status='{self.status}'>"
