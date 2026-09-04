"""
Project PARAKH — Role-Based Access Control (RBAC)

Strict server-side RBAC per §11. Every protected endpoint enforces
authorization server-side — no reliance on frontend permissions.

Roles:
  - INSPECTOR: upload, scan, analyze, view authorized inspections/evidence
  - ADMIN: full dashboard, history, citizen triage, analytics, heatmaps,
           evidence, legal notices, administration
  - CITIZEN: submit reports, view own report status
"""

from __future__ import annotations

from enum import Enum
from typing import Any, Callable, List

from fastapi import Depends, HTTPException, status

from app.core.security import get_current_user_payload


class Role(str, Enum):
    """User roles strictly matching SIH 2026 specification."""
    FOOD_INSPECTOR = "food_inspector"
    NODAL_OFFICER = "nodal_officer"
    FOOD_SAFETY_COMMISSIONER = "food_safety_commissioner"

    # Backward compatibility aliases
    INSPECTOR = "food_inspector"
    ADMIN = "food_safety_commissioner"


# Permission mapping per role
ROLE_PERMISSIONS: dict[Role, set[str]] = {
    Role.FOOD_INSPECTOR: {
        "scan:upload",
        "scan:analyze",
        "inspection:create",
        "inspection:read_own",
        "inspection:read",
        "compliance:read",
        "evidence:create",
        "evidence:read",
        "sync:upload",
        "report:create",
        "report:edit",
        "report:submit",
        "report:read_own",
    },
    Role.NODAL_OFFICER: {
        "scan:upload",
        "scan:analyze",
        "inspection:read",
        "inspection:search",
        "compliance:read",
        "evidence:read",
        "evidence:verify",
        "report:read",
        "report:review",
        "report:approve",
        "report:reject",
        "legal_notice:create",
        "legal_notice:read",
        "analytics:read",
    },
    Role.FOOD_SAFETY_COMMISSIONER: {
        "scan:upload",
        "scan:analyze",
        "inspection:read",
        "inspection:search",
        "compliance:read",
        "evidence:read",
        "evidence:verify",
        "evidence:export",
        "report:read",
        "report:final_verify",
        "legal_notice:create",
        "legal_notice:read",
        "analytics:read",
        "heatmap:read",
        "user:read",
        "user:create",
        "user:update",
        "audit:read",
        "sync:upload",
    },
}


def has_permission(role: str, permission: str) -> bool:
    """Check if a role has a specific permission."""
    try:
        role_enum = Role(role)
    except ValueError:
        return False
    return permission in ROLE_PERMISSIONS.get(role_enum, set())


def require_roles(*allowed_roles: Role) -> Callable:
    """
    FastAPI dependency factory that enforces role-based access.

    Usage:
        @router.get("/admin-only", dependencies=[Depends(require_roles(Role.ADMIN))])
        async def admin_endpoint(): ...

    Or as a parameter dependency:
        async def endpoint(user=Depends(require_roles(Role.ADMIN, Role.INSPECTOR))):
            ...
    """
    async def _role_checker(
        payload: dict[str, Any] = Depends(get_current_user_payload),
    ) -> dict[str, Any]:
        user_role = payload.get("role", "")
        try:
            role_enum = Role(user_role)
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Unknown role: {user_role}",
            )

        if role_enum not in allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=(
                    f"Insufficient permissions. "
                    f"Required: {[r.value for r in allowed_roles]}. "
                    f"Current: {user_role}."
                ),
            )
        return payload

    return _role_checker


def require_permission(permission: str) -> Callable:
    """
    FastAPI dependency factory that enforces a specific permission.

    Usage:
        @router.post("/upload", dependencies=[Depends(require_permission("scan:upload"))])
    """
    async def _permission_checker(
        payload: dict[str, Any] = Depends(get_current_user_payload),
    ) -> dict[str, Any]:
        user_role = payload.get("role", "")
        if not has_permission(user_role, permission):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Missing required permission: {permission}",
            )
        return payload

    return _permission_checker
