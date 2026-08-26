"""
Project PARAKH — Audit Trail Router

Implements §9 & §37:
Retrieve authorized immutable audit logs for administrative oversight.
"""

from __future__ import annotations

from datetime import datetime
from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_admin
from app.core.responses import paginated_response
from app.db.postgres import get_db
from app.repositories.audit_repo import AuditLogRepository
from app.schemas.audit import AuditLogResponse

router = APIRouter(prefix="/audit", tags=["Audit & Security"])


@router.get("/logs", dependencies=[Depends(get_current_admin)])
async def list_audit_logs(
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=100),
    user_id: Optional[UUID] = None,
    action: Optional[str] = None,
    resource_type: Optional[str] = None,
    date_from: Optional[datetime] = None,
    date_to: Optional[datetime] = None,
    db: AsyncSession = Depends(get_db),
):
    """Admin-only: query immutable audit log records with filters."""
    repo = AuditLogRepository(db)
    offset = (page - 1) * page_size
    logs, total = await repo.list_logs(
        offset=offset,
        limit=page_size,
        user_id=user_id,
        action=action,
        resource_type=resource_type,
        date_from=date_from,
        date_to=date_to,
    )
    data = [AuditLogResponse.model_validate(l).model_dump() for l in logs]
    return paginated_response(data=data, total=total, page=page, page_size=page_size)
