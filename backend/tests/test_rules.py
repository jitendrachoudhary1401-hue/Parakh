"""
Project PARAKH — Individual Compliance Rules Tests

Per §46: MRP missing, Net quantity missing, Date missing, Consumer care missing, Manufacturer mismatch.
"""

import pytest

from app.ai.nlp_extractor import ExtractedEntity
from app.rules.consumer_care_rule import ConsumerCareRule
from app.rules.date_rule import DateRule
from app.rules.gs1_rule import GS1Rule
from app.rules.manufacturer_rule import ManufacturerRule
from app.rules.mrp_rule import MRPRule
from app.rules.net_quantity_rule import NetQuantityRule


def test_mrp_rule_pass():
    rule = MRPRule()
    entities = {"MRP": ExtractedEntity(entity_type="MRP", value="₹ 150.00", confidence=0.95)}
    result = rule.evaluate(entities)
    assert result.status == "PASS"


def test_mrp_rule_missing_fail():
    rule = MRPRule()
    result = rule.evaluate({})
    assert result.status == "FAIL"


def test_net_quantity_rule_pass():
    rule = NetQuantityRule()
    entities = {"NET_QUANTITY": ExtractedEntity(entity_type="NET_QUANTITY", value="500 g", confidence=0.9)}
    result = rule.evaluate(entities)
    assert result.status == "PASS"


def test_net_quantity_rule_missing_fail():
    rule = NetQuantityRule()
    result = rule.evaluate({})
    assert result.status == "FAIL"


def test_date_rule_pass():
    rule = DateRule()
    entities = {
        "MFG_DATE": ExtractedEntity(entity_type="MFG_DATE", value="10/2026", confidence=0.88),
        "EXPIRY_DATE": ExtractedEntity(entity_type="EXPIRY_DATE", value="10/2027", confidence=0.88),
    }
    result = rule.evaluate(entities)
    assert result.status == "PASS"


def test_date_rule_missing_fail():
    rule = DateRule()
    result = rule.evaluate({})
    assert result.status == "FAIL"


def test_consumer_care_rule_pass():
    rule = ConsumerCareRule()
    entities = {
        "CONSUMER_CARE_PHONE": ExtractedEntity(entity_type="CONSUMER_CARE_PHONE", value="+91-1800-111-222", confidence=0.9),
        "CONSUMER_CARE_EMAIL": ExtractedEntity(entity_type="CONSUMER_CARE_EMAIL", value="care@brand.in", confidence=0.9),
    }
    result = rule.evaluate(entities)
    assert result.status == "PASS"


def test_consumer_care_partial_review():
    rule = ConsumerCareRule()
    entities = {
        "CONSUMER_CARE_PHONE": ExtractedEntity(entity_type="CONSUMER_CARE_PHONE", value="+91-1800-111-222", confidence=0.9),
    }
    result = rule.evaluate(entities)
    assert result.status == "REVIEW"


def test_gs1_rule_match_pass():
    rule = GS1Rule()
    entities = {"MANUFACTURER_NAME": ExtractedEntity(entity_type="MANUFACTURER_NAME", value="Britannia Industries Ltd", confidence=0.9)}
    gs1_data = {"status": "FOUND", "registered_manufacturer": "Britannia Industries Limited", "barcode": "8901063012345"}
    result = rule.evaluate(entities, gs1_data)
    assert result.status == "PASS"


def test_gs1_rule_mismatch_fail():
    rule = GS1Rule()
    entities = {"MANUFACTURER_NAME": ExtractedEntity(entity_type="MANUFACTURER_NAME", value="Fake Consumer Goods Ltd", confidence=0.9)}
    gs1_data = {"status": "FOUND", "registered_manufacturer": "Nestle India Limited", "barcode": "8901063012345"}
    result = rule.evaluate(entities, gs1_data)
    assert result.status == "FAIL"
