"""
Project PARAKH — Health & Readiness Probes

Implements §49:
/health (liveness) and /ready (readiness). Identifies dependencies without exposing secrets.
"""

from datetime import datetime, timezone

from fastapi import APIRouter, Depends
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.mongodb import MongoDB
from app.db.postgres import get_db

router = APIRouter(tags=["Health"])


@router.get("/health")
async def liveness_probe():
    """Liveness probe indicating that the service process is up."""
    return {
        "status": "healthy",
        "service": "PARAKH Backend",
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }


@router.get("/ready")
async def readiness_probe(db: AsyncSession = Depends(get_db)):
    """Readiness probe testing core database connectivity, cache, and queue."""
    checks = {"postgres": False, "postgres_cache": False, "postgres_queue": False, "mongodb": False}

    # Check PostgreSQL Core DB, Cache, and Queue tables
    try:
        await db.execute(text("SELECT 1"))
        checks["postgres"] = True
        await db.execute(text("SELECT 1 FROM cache_entries LIMIT 1"))
        checks["postgres_cache"] = True
        await db.execute(text("SELECT 1 FROM task_queue LIMIT 1"))
        checks["postgres_queue"] = True
    except Exception:
        pass

    # Check MongoDB
    try:
        mongo_db = MongoDB.get_database()
        await mongo_db.command("ping")
        checks["mongodb"] = True
    except Exception:
        checks["mongodb"] = False

    all_ready = checks["postgres"] and checks["postgres_cache"] and checks["postgres_queue"]
    return {
        "ready": all_ready,
        "checks": checks,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }
