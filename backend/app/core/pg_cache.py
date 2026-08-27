"""
Project PARAKH — PostgreSQL Cache Manager

Replaces Redis key-value storage with PostgreSQL-backed cache store.
Supports TTL expiration, atomic counters (rate limiting), and JSON serialization.
"""

from __future__ import annotations

import json
from datetime import datetime, timedelta, timezone
from typing import Any, Optional

from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.postgres import async_session_factory
from app.models.cache_entry import CacheEntry


class PostgresCache:
    """Async Key-Value Cache client backed by PostgreSQL."""

    def __init__(self, session_factory=async_session_factory):
        self.session_factory = session_factory

    async def get(self, key: str) -> Optional[str]:
        """
        Get a string value by key. Returns None if key does not exist or has expired.
        """
        async with self.session_factory() as session:
            now = datetime.now(timezone.utc)
            stmt = select(CacheEntry).where(CacheEntry.key == key)
            result = await session.execute(stmt)
            entry = result.scalar_one_or_none()

            if not entry:
                return None

            if entry.expires_at and entry.expires_at <= now:
                # Expired key: remove from cache
                await session.execute(delete(CacheEntry).where(CacheEntry.key == key))
                await session.commit()
                return None

            return entry.value

    async def get_json(self, key: str) -> Optional[Any]:
        """Get and deserialize JSON object from cache."""
        val = await self.get(key)
        if val is None:
            return None
        try:
            return json.loads(val)
        except Exception:
            return val

    async def set(
        self,
        key: str,
        value: Any,
        ttl_seconds: Optional[int] = None,
    ) -> bool:
        """
        Set key to value with optional TTL expiration in seconds.
        """
        if not isinstance(value, str):
            val_str = json.dumps(value)
        else:
            val_str = value

        now = datetime.now(timezone.utc)
        expires_at = now + timedelta(seconds=ttl_seconds) if ttl_seconds else None

        async with self.session_factory() as session:
            stmt = select(CacheEntry).where(CacheEntry.key == key)
            result = await session.execute(stmt)
            entry = result.scalar_one_or_none()

            if entry:
                entry.value = val_str
                entry.expires_at = expires_at
                entry.updated_at = now
            else:
                entry = CacheEntry(
                    key=key,
                    value=val_str,
                    expires_at=expires_at,
                    created_at=now,
                    updated_at=now,
                )
                session.add(entry)

            await session.commit()
            return True

    async def delete(self, key: str) -> bool:
        """Delete a key from the cache."""
        async with self.session_factory() as session:
            stmt = delete(CacheEntry).where(CacheEntry.key == key)
            result = await session.execute(stmt)
            await session.commit()
            return result.rowcount > 0

    async def incr(self, key: str, amount: int = 1, ttl_seconds: Optional[int] = 60) -> int:
        """
        Atomically increment a key's integer counter. Useful for rate limiting.
        """
        now = datetime.now(timezone.utc)
        expires_at = now + timedelta(seconds=ttl_seconds) if ttl_seconds else None

        async with self.session_factory() as session:
            stmt = select(CacheEntry).where(CacheEntry.key == key).with_for_update()
            result = await session.execute(stmt)
            entry = result.scalar_one_or_none()

            if not entry or (entry.expires_at and entry.expires_at <= now):
                # Initialize counter
                entry = CacheEntry(
                    key=key,
                    value=str(amount),
                    counter=amount,
                    expires_at=expires_at,
                    created_at=now,
                    updated_at=now,
                )
                session.add(entry)
                new_val = amount
            else:
                current_val = entry.counter or int(entry.value or 0)
                new_val = current_val + amount
                entry.counter = new_val
                entry.value = str(new_val)
                entry.updated_at = now

            await session.commit()
            return new_val

    async def cleanup_expired(self) -> int:
        """Remove all expired cache entries from the database."""
        async with self.session_factory() as session:
            now = datetime.now(timezone.utc)
            stmt = delete(CacheEntry).where(
                CacheEntry.expires_at.is_not(None),
                CacheEntry.expires_at <= now,
            )
            result = await session.execute(stmt)
            await session.commit()
            return result.rowcount


# Global cache client singleton instance
pg_cache = PostgresCache()
