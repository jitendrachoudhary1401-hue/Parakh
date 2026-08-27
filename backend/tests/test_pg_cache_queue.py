"""
Project PARAKH — PostgreSQL Cache & Queue Unit Tests
"""

import asyncio
from datetime import datetime, timedelta, timezone
import pytest

from app.core.pg_cache import PostgresCache
from app.core.pg_queue import PostgresQueue


@pytest.mark.asyncio
async def test_postgres_cache_crud(test_db_session):
    # Session factory adapter for test session
    class TestSessionFactory:
        def __call__(self):
            return test_db_session

    cache = PostgresCache(session_factory=TestSessionFactory())

    # Test set & get string
    assert await cache.set("test_key", "hello_world", ttl_seconds=60)
    assert await cache.get("test_key") == "hello_world"

    # Test set & get JSON
    dict_val = {"status": "ok", "count": 42}
    assert await cache.set("test_json", dict_val)
    assert await cache.get_json("test_json") == dict_val

    # Test incr (atomic counter)
    assert await cache.incr("test_counter", amount=1, ttl_seconds=60) == 1
    assert await cache.incr("test_counter", amount=5, ttl_seconds=60) == 6

    # Test delete
    assert await cache.delete("test_key") is True
    assert await cache.get("test_key") is None


@pytest.mark.asyncio
async def test_postgres_cache_expiration(test_db_session):
    class TestSessionFactory:
        def __call__(self):
            return test_db_session

    cache = PostgresCache(session_factory=TestSessionFactory())

    # Set key with negative TTL (already expired)
    await cache.set("expired_key", "value", ttl_seconds=-10)

    # get should detect expiration and return None
    assert await cache.get("expired_key") is None


@pytest.mark.asyncio
async def test_postgres_queue_lifecycle(test_db_session):
    class TestSessionFactory:
        def __call__(self):
            return test_db_session

    queue = PostgresQueue(session_factory=TestSessionFactory())

    # Enqueue a task
    task_id = await queue.enqueue(
        task_type="ocr_extraction",
        payload={"image_id": "12345"},
        priority=10,
    )
    assert task_id is not None

    # Check status
    status = await queue.get_task_status(task_id)
    assert status["status"] == "pending"
    assert status["task_type"] == "ocr_extraction"
    assert status["priority"] == 10

    # Dequeue task
    task = await queue.dequeue(task_types=["ocr_extraction"])
    assert task is not None
    assert task.task_id == task_id
    assert task.status == "processing"

    # Mark completed
    result_data = {"text": "FSSAI LIC 10012022000123"}
    assert await queue.mark_completed(task_id, result=result_data) is True

    final_status = await queue.get_task_status(task_id)
    assert final_status["status"] == "completed"
    assert final_status["result"] == result_data


@pytest.mark.asyncio
async def test_postgres_queue_failure_and_retry(test_db_session):
    class TestSessionFactory:
        def __call__(self):
            return test_db_session

    queue = PostgresQueue(session_factory=TestSessionFactory())

    task_id = await queue.enqueue(
        task_type="blockchain_anchor",
        payload={"notice_id": "notice-99"},
        max_attempts=2,
    )

    # First attempt fails -> schedules retry (status stays pending)
    await queue.dequeue(task_types=["blockchain_anchor"], ignore_schedule=True)
    assert await queue.mark_failed(task_id, "Network timeout") is True
    st1 = await queue.get_task_status(task_id)
    assert st1["status"] == "pending"
    assert st1["attempts"] == 1

    # Second attempt fails -> max attempts reached (status becomes failed)
    await queue.dequeue(task_types=["blockchain_anchor"], ignore_schedule=True)
    assert await queue.mark_failed(task_id, "Node unavailable") is True
    st2 = await queue.get_task_status(task_id)
    assert st2["status"] == "failed"
    assert st2["attempts"] == 2
    assert st2["error_message"] == "Node unavailable"
