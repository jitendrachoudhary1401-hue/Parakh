"""
Project PARAKH — PostgreSQL Task Queue Manager

Replaces Redis task queues (Celery/RQ/ARQ) with PostgreSQL-backed Task Queue.
Uses SELECT FOR UPDATE SKIP LOCKED for high-concurrency, safe multi-worker task execution.
"""

from __future__ import annotations

import uuid
from datetime import datetime, timedelta, timezone
from typing import Any, List, Optional

from sqlalchemy import delete, select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.postgres import async_session_factory
from app.models.task_queue import TaskQueue


def _ensure_tz(dt: Optional[datetime]) -> Optional[datetime]:
    if dt is None:
        return None
    if dt.tzinfo is None:
        return dt.replace(tzinfo=timezone.utc)
    return dt


class PostgresQueue:
    """Async Background Job Queue manager backed by PostgreSQL."""

    def __init__(self, session_factory=async_session_factory):
        self.session_factory = session_factory

    async def enqueue(
        self,
        task_type: str,
        payload: dict[str, Any],
        priority: int = 0,
        scheduled_at: Optional[datetime] = None,
        max_attempts: int = 3,
    ) -> uuid.UUID:
        """
        Enqueue a new task into PostgreSQL task queue.
        """
        now = datetime.now(timezone.utc)
        task = TaskQueue(
            task_id=uuid.uuid4(),
            task_type=task_type,
            payload=payload,
            status="pending",
            priority=priority,
            max_attempts=max_attempts,
            scheduled_at=_ensure_tz(scheduled_at) or now,
            created_at=now,
        )
        async with self.session_factory() as session:
            session.add(task)
            await session.commit()
            return task.task_id

    async def dequeue(
        self,
        task_types: Optional[List[str]] = None,
        ignore_schedule: bool = False,
    ) -> Optional[TaskQueue]:
        """
        Safely fetch and claim the highest priority pending task.
        Uses FOR UPDATE SKIP LOCKED to prevent race conditions across multiple worker processes.
        """
        now = datetime.now(timezone.utc)
        async with self.session_factory() as session:
            stmt = (
                select(TaskQueue)
                .where(TaskQueue.status == "pending")
                .order_by(TaskQueue.priority.desc(), TaskQueue.created_at.asc())
                .with_for_update(skip_locked=True)
                .limit(1)
            )

            if not ignore_schedule:
                stmt = stmt.where(TaskQueue.scheduled_at <= now)

            if task_types:
                stmt = stmt.where(TaskQueue.task_type.in_(task_types))

            result = await session.execute(stmt)
            task = result.scalar_one_or_none()

            if task:
                task.status = "processing"
                task.attempts += 1
                task.started_at = now
                await session.commit()
                await session.refresh(task)

            return task

    async def mark_completed(
        self,
        task_id: uuid.UUID,
        result: Optional[dict[str, Any]] = None,
    ) -> bool:
        """Mark task as successfully completed."""
        now = datetime.now(timezone.utc)
        async with self.session_factory() as session:
            stmt = select(TaskQueue).where(TaskQueue.task_id == task_id)
            res = await session.execute(stmt)
            task = res.scalar_one_or_none()

            if task:
                task.status = "completed"
                task.result = result
                task.completed_at = now
                await session.commit()
                return True
            return False

    async def mark_failed(
        self,
        task_id: uuid.UUID,
        error_message: str,
        retry_delay_seconds: int = 10,
    ) -> bool:
        """
        Mark task as failed. If max attempts reached, sets status to 'failed',
        otherwise schedules retry ('pending').
        """
        now = datetime.now(timezone.utc)
        async with self.session_factory() as session:
            stmt = select(TaskQueue).where(TaskQueue.task_id == task_id)
            res = await session.execute(stmt)
            task = res.scalar_one_or_none()

            if task:
                task.error_message = error_message
                if task.attempts >= task.max_attempts:
                    task.status = "failed"
                else:
                    task.status = "pending"
                    task.scheduled_at = now + timedelta(seconds=retry_delay_seconds * task.attempts)

                await session.commit()
                return True
            return False

    async def get_task_status(self, task_id: uuid.UUID) -> Optional[dict[str, Any]]:
        """Get status details of a task by ID."""
        async with self.session_factory() as session:
            stmt = select(TaskQueue).where(TaskQueue.task_id == task_id)
            res = await session.execute(stmt)
            task = res.scalar_one_or_none()

            if not task:
                return None

            return {
                "task_id": str(task.task_id),
                "task_type": task.task_type,
                "status": task.status,
                "priority": task.priority,
                "attempts": task.attempts,
                "max_attempts": task.max_attempts,
                "error_message": task.error_message,
                "result": task.result,
                "scheduled_at": task.scheduled_at.isoformat() if task.scheduled_at else None,
                "started_at": task.started_at.isoformat() if task.started_at else None,
                "completed_at": task.completed_at.isoformat() if task.completed_at else None,
                "created_at": task.created_at.isoformat() if task.created_at else None,
            }


# Global queue client singleton instance
pg_queue = PostgresQueue()
