"""
Project PARAKH — Nodal Verifier & Commissioner Forwarding Workflow Tests
"""

import uuid
import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.inspection import Inspection
from app.models.user import User


@pytest.mark.asyncio
async def test_nodal_verifier_accept_workflow(
    client: AsyncClient,
    test_db_session: AsyncSession,
    sample_inspector: User,
    inspector_token: str,
    admin_token: str,
):
    # 1. Create an inspection in database
    inspection = Inspection(
        inspection_id=uuid.uuid4(),
        inspector_id=sample_inspector.user_id,
        product_barcode="8901234567890",
        latitude=28.6139,
        longitude=77.2090,
        location_name="Initial Shop",
        status="pending",
        notes="Field scan complete",
    )
    test_db_session.add(inspection)
    await test_db_session.commit()
    await test_db_session.refresh(inspection)

    insp_id = str(inspection.inspection_id)

    # 2. Inspector transmits report to Nodal Verifier
    headers_insp = {"Authorization": f"Bearer {inspector_token}"}
    submit_payload = {
        "shop_name": "Sharma Supermarket",
        "shop_owner_name": "Ramesh Sharma",
        "shop_address": "Shop 4, Connaught Place, New Delhi",
        "notes": "Missing Consumer Care Phone on packaging",
        "violation_rules": [
            {
                "rule_id": "LM-004",
                "rule_number": "6(1)(e)",
                "rule_title": "Consumer Care Details Mandate",
            }
        ],
        "evidence_images": ["https://storage.parakh.gov.in/evidence/pkg1.jpg"],
    }

    res_submit = await client.post(
        f"/api/v1/inspections/{insp_id}/submit-nodal",
        json=submit_payload,
        headers=headers_insp,
    )
    assert res_submit.status_code == 200
    data_submit = res_submit.json()["data"]
    assert data_submit["status"] == "unverified"
    assert data_submit["blockchain_hash"] is not None

    # 3. Nodal Verifier queries pending inspections queue
    headers_nodal = {"Authorization": f"Bearer {admin_token}"}
    res_pending = await client.get(
        "/api/v1/inspections/pending-nodal",
        headers=headers_nodal,
    )
    assert res_pending.status_code == 200
    pending_list = res_pending.json()["data"]
    matching = [item for item in pending_list if item["inspection_id"] == insp_id]
    assert len(matching) == 1
    assert matching[0]["status"] == "unverified"

    # 4. Nodal Verifier ACCEPTS and forwards to Commissioner for digital signature
    decision_payload = {
        "decision": "ACCEPT",
        "verifier_comment": "Statutory non-compliance confirmed under Rule 6(1)(e). Forwarded to Commissioner.",
        "verifier_name": "Nodal Officer S. K. Sharma",
    }
    res_decision = await client.post(
        f"/api/v1/inspections/{insp_id}/nodal-decision",
        json=decision_payload,
        headers=headers_nodal,
    )
    assert res_decision.status_code == 200
    data_decision = res_decision.json()["data"]
    assert data_decision["status"] == "verified_accepted"
    nodal_meta = data_decision["metadata_json"]["nodal_verification"]
    assert nodal_meta["decision"] == "ACCEPTED"
    assert nodal_meta["commissioner_status"] == "FORWARDED_FOR_DIGITAL_SIGNATURE"
    assert "Forwarded to Commissioner" in nodal_meta["verifier_comment"]


@pytest.mark.asyncio
async def test_nodal_verifier_reject_workflow(
    client: AsyncClient,
    test_db_session: AsyncSession,
    sample_inspector: User,
    inspector_token: str,
    admin_token: str,
):
    # 1. Create an inspection
    inspection = Inspection(
        inspection_id=uuid.uuid4(),
        inspector_id=sample_inspector.user_id,
        product_barcode="8909999999999",
        status="pending",
    )
    test_db_session.add(inspection)
    await test_db_session.commit()
    await test_db_session.refresh(inspection)

    insp_id = str(inspection.inspection_id)

    # 2. Inspector submits
    headers_insp = {"Authorization": f"Bearer {inspector_token}"}
    await client.post(
        f"/api/v1/inspections/{insp_id}/submit-nodal",
        json={"notes": "Potential label defect"},
        headers=headers_insp,
    )

    # 3. Nodal Verifier DENIES and REJECTS
    headers_nodal = {"Authorization": f"Bearer {admin_token}"}
    decision_payload = {
        "decision": "REJECT",
        "verifier_comment": "Font size is within Schedule I tolerance limits. Case dismissed.",
        "verifier_name": "Nodal Officer S. K. Sharma",
    }
    res_decision = await client.post(
        f"/api/v1/inspections/{insp_id}/nodal-decision",
        json=decision_payload,
        headers=headers_nodal,
    )
    assert res_decision.status_code == 200
    data_decision = res_decision.json()["data"]
    assert data_decision["status"] == "verified_rejected"
    nodal_meta = data_decision["metadata_json"]["nodal_verification"]
    assert nodal_meta["decision"] == "REJECTED"
    assert nodal_meta["commissioner_status"] == "NOT_FORWARDED"
