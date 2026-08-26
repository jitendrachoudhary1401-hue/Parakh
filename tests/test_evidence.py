"""
Project PARAKH — Evidence Integrity & Hashing Tests

Per §46: SHA-256 generation, evidence integrity verification, blockchain status.
"""

from datetime import datetime, timezone
import pytest

from app.blockchain.evidence_chain import EvidenceChainService


def test_sha256_payload_hash_deterministic():
    """Test that payload hashing produces consistent SHA-256 hex strings."""
    ts = datetime(2026, 8, 26, 12, 0, 0, tzinfo=timezone.utc)
    hash1 = EvidenceChainService.calculate_payload_hash(
        image_storage_path="inspections/raw.jpg",
        gps_latitude=28.6139,
        gps_longitude=77.2090,
        capture_timestamp=ts,
        ocr_text_snapshot="MRP Rs 50",
        inspector_id="insp-123",
        violation_data={"missing": ["EXPIRY"]},
    )
    hash2 = EvidenceChainService.calculate_payload_hash(
        image_storage_path="inspections/raw.jpg",
        gps_latitude=28.6139,
        gps_longitude=77.2090,
        capture_timestamp=ts,
        ocr_text_snapshot="MRP Rs 50",
        inspector_id="insp-123",
        violation_data={"missing": ["EXPIRY"]},
    )
    assert len(hash1) == 64
    assert hash1 == hash2


def test_sha256_detects_tampered_payload():
    """Any modification in evidentiary parameters alters the hash."""
    ts = datetime(2026, 8, 26, 12, 0, 0, tzinfo=timezone.utc)
    original_hash = EvidenceChainService.calculate_payload_hash(
        image_storage_path="inspections/raw.jpg",
        gps_latitude=28.6139,
        gps_longitude=77.2090,
        capture_timestamp=ts,
        ocr_text_snapshot="MRP Rs 50",
        inspector_id="insp-123",
        violation_data={"missing": ["EXPIRY"]},
    )
    tampered_hash = EvidenceChainService.calculate_payload_hash(
        image_storage_path="inspections/raw.jpg",
        gps_latitude=28.6139,
        gps_longitude=77.2090,
        capture_timestamp=ts,
        ocr_text_snapshot="MRP Rs 150",  # Doctored price
        inspector_id="insp-123",
        violation_data={"missing": ["EXPIRY"]},
    )
    assert original_hash != tampered_hash
