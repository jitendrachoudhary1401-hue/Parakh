"""
Project PARAKH — Compliance Results Router

Implements §9:
Retrieve compliance determination and granular rule results.
"""

from uuid import UUID

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.core.exceptions import NotFoundError
from app.core.responses import success_response
from app.db.mongodb import MongoDB
from app.db.postgres import get_db
from app.models.user import User
from app.repositories.inspection_repo import InspectionRepository

import json
from pathlib import Path

router = APIRouter(prefix="/compliance", tags=["Compliance"])

RULES_JSON_PATH = Path(__file__).resolve().parent.parent.parent / "rules" / "legal_metrology_rules.json"


@router.get("/rules")
async def get_legal_metrology_rules():
    """Retrieve all statutory Legal Metrology rules from legal_metrology_rules.json for inspector reference."""
    if not RULES_JSON_PATH.exists():
        return success_response(data={"rules": [], "total": 0})
    with open(RULES_JSON_PATH, "r", encoding="utf-8") as f:
        data = json.load(f)
    return success_response(data={
        "metadata": data.get("metadata", {}),
        "rules": data.get("rules", []),
        "total": len(data.get("rules", [])),
    })


@router.get("/{inspection_id}")
async def get_compliance_results(
    inspection_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Retrieve detailed compliance rule results and AI log breakdown for an inspection."""
    insp_repo = InspectionRepository(db)
    inspection = await insp_repo.get_by_id(inspection_id)
    if not inspection:
        raise NotFoundError("Inspection", str(inspection_id))

    # Fetch rich AI log from MongoDB
    mongo_log = await MongoDB.ai_extraction_logs().find_one({"inspection_id": str(inspection_id)})
    
    rule_results = mongo_log.get("rule_engine_results", []) if mongo_log else []
    entities = mongo_log.get("parsed_entities", []) if mongo_log else []

    return success_response(
        data={
            "inspection_id": inspection_id,
            "overall_status": (inspection.overall_result or "PENDING").upper(),
            "rule_results": rule_results,
            "extracted_entities": entities,
            "blockchain_hash": inspection.blockchain_hash,
            "has_ai_logs": mongo_log is not None,
        }
    )
