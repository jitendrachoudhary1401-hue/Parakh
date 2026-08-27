"""
Project PARAKH — PostgreSQL Cache Store Model

PostgreSQL table: cache_entries
Provides key-value caching and rate-limiting storage directly in PostgreSQL.
"""

from __future__ import annotations

from datetime import datetime, timezone
from sqlalchemy import DateTime, String, Text, BigInteger
from sqlalchemy.orm import Mapped, mapped_column

from app.db.postgres import Base


class CacheEntry(Base):
    __tablename__ = "cache_entries"

    key: Mapped[str] = mapped_column(
        String(255),
        primary_key=True,
        index=True,
    )
    value: Mapped[str] = mapped_column(
        Text,
        nullable=False,
    )
    # Integer value for counter operations (rate limiting, sequence numbers)
    counter: Mapped[int | None] = mapped_column(
        BigInteger,
        nullable=True,
        default=0,
    )
    expires_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
        index=True,
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
        return f"<CacheEntry key='{self.key}' expires_at={self.expires_at}>"
