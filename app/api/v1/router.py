"""
Project PARAKH — API v1 Master Router

Aggregates all /api/v1 versioned endpoints per §7.
"""

from fastapi import APIRouter

from app.api.v1.analytics import router as analytics_router
from app.api.v1.analysis import router as analysis_router
from app.api.v1.audit import router as audit_router
from app.api.v1.auth import router as auth_router
from app.api.v1.citizen import router as citizen_router
from app.api.v1.compliance import router as compliance_router
from app.api.v1.evidence import router as evidence_router
from app.api.v1.health import router as health_router
from app.api.v1.heatmaps import router as heatmaps_router
from app.api.v1.inspections import router as inspections_router
from app.api.v1.legal_notices import router as legal_notices_router
from app.api.v1.scan import router as scan_router
from app.api.v1.sync import router as sync_router
from app.api.v1.users import router as users_router

api_v1_router = APIRouter(prefix="/api/v1")

# Mount sub-routers
api_v1_router.include_router(health_router)
api_v1_router.include_router(auth_router)
api_v1_router.include_router(users_router)
api_v1_router.include_router(scan_router)
api_v1_router.include_router(analysis_router)
api_v1_router.include_router(inspections_router)
api_v1_router.include_router(compliance_router)
api_v1_router.include_router(evidence_router)
api_v1_router.include_router(citizen_router)
api_v1_router.include_router(analytics_router)
api_v1_router.include_router(heatmaps_router)
api_v1_router.include_router(legal_notices_router)
api_v1_router.include_router(audit_router)
api_v1_router.include_router(sync_router)

__all__ = ["api_v1_router"]
