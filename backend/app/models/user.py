"""
Project PARAKH — User Model

PostgreSQL table: users
Fields per §12: user_id, full_name, role, zone_id, timestamps, authentication metadata.
"""

from __future__ import annotations

import uuid
from datetime import datetime, timezone

from sqlalchemy import Boolean, DateTime, Enum, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.postgres import Base


class UserRole(str):
    """User role constants matching RBAC specification §11."""
    INSPECTOR = "inspector"
    ADMIN = "admin"
    CITIZEN = "citizen"


class User(Base):
    __tablename__ = "users"

    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
    )
    full_name: Mapped[str] = mapped_column(String(255), nullable=False)
    email: Mapped[str] = mapped_column(
        String(255), unique=True, nullable=False, index=True,
    )
    hashed_password: Mapped[str] = mapped_column(Text, nullable=False)
    role: Mapped[str] = mapped_column(
        String(20),
        nullable=False,
        index=True,
        default="citizen",
    )
    zone_id: Mapped[str | None] = mapped_column(String(50), nullable=True)
    phone: Mapped[str | None] = mapped_column(String(20), nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

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
    last_login_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True,
    )

    # Relationships
    inspections = relationship(
        "Inspection", back_populates="inspector", lazy="noload",
    )
    citizen_reports = relationship(
        "CitizenReport",
        back_populates="citizen",
        foreign_keys="[CitizenReport.citizen_id]",
        lazy="noload",
    )

    def __repr__(self) -> str:
        return f"<User {self.email} role={self.role}>"
