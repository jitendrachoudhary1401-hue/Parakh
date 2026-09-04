"""
Project PARAKH — SQLAlchemy ORM Models

Re-exports all models so Alembic and the application can discover them
from a single import.
"""

from app.models.user import User
from app.models.inspection import Inspection
from app.models.legal_document import LegalDocument
from app.models.openfoodfacts_product import OpenFoodFactsProduct, GS1Product
from app.models.citizen_report import CitizenReport
from app.models.evidence import Evidence
from app.models.legal_notice import LegalNotice
from app.models.report import Report
from app.models.audit_log import AuditLog
from app.models.cache_entry import CacheEntry
from app.models.task_queue import TaskQueue

__all__ = [
    "User",
    "Inspection",
    "LegalDocument",
    "OpenFoodFactsProduct",
    "GS1Product",
    "CitizenReport",
    "Evidence",
    "LegalNotice",
    "Report",
    "AuditLog",
    "CacheEntry",
    "TaskQueue",
]
