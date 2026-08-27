"""
Project PARAKH — Audit Logging Service

Implements §37:
Immutable audit trail recording security and enforcement events.
"""

from __future__ import annotations

import logging
from typing import Any, Dict, Optional
from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession

from app.config import get_settings
from app.models.audit_log import AuditLog
from app.repositories.audit_repo import AuditLogRepository

logger = logging.getLogger("parakh.audit")


class AuditService:
    """Service to log security and system events to PostgreSQL audit table."""

    def __init__(self, db: AsyncSession):
        self.db = db
        self.repo = AuditLogRepository(db)
        self.enabled = get_settings().audit_log_enabled

    async def log_event(
        self,
        action: str,
        user_id: Optional[UUID] = None,
        user_email: Optional[str] = None,
        user_role: Optional[str] = None,
        resource_type: Optional[str] = None,
        resource_id: Optional[str] = None,
        details: Optional[Dict[str, Any]] = None,
        ip_address: Optional[str] = None,
        user_agent: Optional[str] = None,
        request_method: Optional[str] = None,
        request_path: Optional[str] = None,
        status: str = "success",
    ) -> Optional[AuditLog]:
        """Record an immutable audit log entry."""
        if not self.enabled:
            return None

        try:
            log_entry = AuditLog(
                user_id=user_id,
                user_email=user_email,
                user_role=user_role,
                action=action,
                resource_type=resource_type,
                resource_id=resource_id,
                details=details,
                ip_address=ip_address,
                user_agent=user_agent,
                request_method=request_method,
                request_path=request_path,
                status=status,
            )
            created = await self.repo.create(log_entry)
            logger.info("Audit logged: %s by %s on %s", action, user_email or "anonymous", resource_type or "system")
            return created
        except Exception as exc:
            logger.error("Failed to write audit log: %s", exc)
            return None
