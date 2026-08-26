"""
Project PARAKH — Full Compliance Engine Evaluation Tests
"""

import pytest

from app.ai.nlp_extractor import ExtractedEntity
from app.rules.engine import ComplianceEngine


def test_compliance_engine_all_pass():
    engine = ComplianceEngine()
    entities = [
        ExtractedEntity("MRP", "₹ 99.00", 0.9),
        ExtractedEntity("NET_QUANTITY", "250 ml", 0.9),
        ExtractedEntity("MFG_DATE", "05/2026", 0.9),
        ExtractedEntity("CONSUMER_CARE_PHONE", "+91-9876543210", 0.9),
        ExtractedEntity("CONSUMER_CARE_EMAIL", "help@brand.com", 0.9),
        ExtractedEntity("MANUFACTURER_NAME", "Tata Consumer Products", 0.9),
        ExtractedEntity("MANUFACTURER_ADDRESS", "12 Industrial Area, Mumbai", 0.9),
    ]
    gs1_data = {
        "status": "FOUND",
        "registered_manufacturer": "Tata Consumer Products Ltd",
        "barcode": "8901234567890",
    }
    result = engine.evaluate(entities, gs1_data)
    assert result["overall_status"] == "COMPLIANT"
    assert result["requires_human_review"] is False


def test_compliance_engine_violation_on_missing_mrp():
    engine = ComplianceEngine()
    entities = [
        ExtractedEntity("NET_QUANTITY", "250 ml", 0.9),
        ExtractedEntity("MFG_DATE", "05/2026", 0.9),
    ]
    result = engine.evaluate(entities)
    assert result["overall_status"] == "VIOLATION"


def test_compliance_engine_insufficient_data():
    engine = ComplianceEngine()
    result = engine.evaluate([])
    assert result["overall_status"] in ("INSUFFICIENT_DATA", "VIOLATION")
