"""
Project PARAKH — Analysis Pipeline Service

Orchestrates the end-to-end compliance checking pipeline per §8/§15/§16/§17/§18/§19:
Image → OpenCV Unwarping → Cloud Vision OCR → HuggingFace NLP → GS1 Lookup → Rule Engine → MongoDB & PostgreSQL Persistence.
"""

from __future__ import annotations

import logging
import time
from datetime import datetime, timezone
from typing import Any, Dict, Optional
from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession

from app.ai.anomaly_detector import AnomalyDetector
from app.ai.image_processor import ImageProcessor
from app.ai.nlp_extractor import NLPExtractor
from app.ai.ocr_engine import OCREngine
from app.core.exceptions import NotFoundError, ServiceUnavailableError
from app.db.mongodb import MongoDB
from app.integrations.openfoodfacts_client import OpenFoodFactsClient
from app.models.openfoodfacts_product import OpenFoodFactsProduct
from app.models.inspection import Inspection
from app.repositories.openfoodfacts_repo import OpenFoodFactsRepository
from app.repositories.inspection_repo import InspectionRepository
from app.rules.engine import ComplianceEngine
from app.blockchain.evidence_chain import EvidenceChainService
from app.storage import get_storage_backend

logger = logging.getLogger("parakh.services.analysis")


class AnalysisService:
    def __init__(self, db: AsyncSession):
        self.db = db
        self.inspection_repo = InspectionRepository(db)
        self.product_repo = OpenFoodFactsRepository(db)
        self.storage = get_storage_backend()
        
        # AI components
        self.image_processor = ImageProcessor()
        self.ocr_engine = OCREngine()
        self.nlp_extractor = NLPExtractor()
        self.anomaly_detector = AnomalyDetector()
        self.rule_engine = ComplianceEngine()
        self.off_client = OpenFoodFactsClient()

    async def verify_compliance(
        self,
        inspection_id: UUID,
        product_barcode: Optional[str] = None,
    ) -> Dict[str, Any]:
        """Execute full compliance pipeline for an inspection."""
        start_time = time.time()
        inspection = await self.inspection_repo.get_by_id(inspection_id)
        if not inspection:
            raise NotFoundError("Inspection", str(inspection_id))

        if not inspection.image_storage_path:
            raise NotFoundError("Inspection image", "No image associated with inspection")

        # 1. Download image from storage
        raw_image_bytes = await self.storage.download_file(inspection.image_storage_path)

        # 2. OpenCV preprocessing & surface unwarping
        proc_result = self.image_processor.process(raw_image_bytes)
        
        processed_bytes = raw_image_bytes
        if proc_result.success and proc_result.processed_image is not None:
            processed_bytes = self.image_processor.image_to_bytes(proc_result.processed_image)
            # Store unwarped image
            unwarped_path = f"inspections/{inspection.inspector_id}/{inspection_id}/processed.png"
            await self.storage.upload_file(processed_bytes, unwarped_path, "image/png")
            inspection.processed_image_path = unwarped_path

        # 3. Google Cloud Vision OCR
        ocr_result = await self.ocr_engine.extract_text(processed_bytes)
        raw_ocr_text = ocr_result.raw_text if ocr_result.success else ""

        # 4. HuggingFace NLP Entity Extraction
        nlp_result = await self.nlp_extractor.extract_entities(raw_ocr_text)
        entities = nlp_result.entities if nlp_result.success else []

        # 5. Open Food Facts Barcode Lookup & Cross-referencing
        barcode = product_barcode or inspection.product_barcode
        product_info = None
        if barcode:
            lookup = await self.off_client.lookup_barcode(barcode)
            if lookup.status == "FOUND":
                product_info = {
                    "status": "FOUND",
                    "registered_manufacturer": lookup.registered_manufacturer,
                    "manufacturer_address": lookup.manufacturer_address,
                    "product_name": lookup.product_name,
                    "barcode": barcode,
                }
                # Cache Open Food Facts product in PostgreSQL
                off_entity = OpenFoodFactsProduct(
                    barcode=barcode,
                    registered_manufacturer=lookup.registered_manufacturer,
                    manufacturer_address=lookup.manufacturer_address,
                    product_name=lookup.product_name,
                    product_category=lookup.product_category,
                    brand=lookup.brand,
                    last_verified_at=datetime.now(timezone.utc),
                )
                await self.product_repo.upsert(off_entity)
            else:
                product_info = {
                    "status": lookup.status,
                    "registered_manufacturer": None,
                    "barcode": barcode,
                    "error": lookup.error_message,
                }

        # 6. Compliance Rule Engine Evaluation
        rule_eval = self.rule_engine.evaluate(
            entities=entities,
            gs1_data=product_info,
            ocr_text=raw_ocr_text,
        )

        # 7. Anomaly detection (ViT)
        anomalies = []
        if proc_result.success and proc_result.processed_image is not None:
            anomaly_res = await self.anomaly_detector.detect_anomalies(proc_result.processed_image)
            if anomaly_res.success:
                anomalies = [
                    {
                        "anomaly_type": f.anomaly_type,
                        "description": f.description,
                        "confidence": f.confidence,
                        "is_potential_anomaly": f.is_potential_anomaly,
                    }
                    for f in anomaly_res.findings
                ]

        elapsed_ms = (time.time() - start_time) * 1000

        # 8. Compute SHA-256 Evidence Hash (Image + GPS + Timestamp + OCR Text + Violations)
        evidence_hash = None
        if rule_eval["overall_status"].lower() == "violation":
            evidence_hash = EvidenceChainService.calculate_payload_hash(
                image_storage_path=inspection.image_storage_path,
                gps_latitude=inspection.latitude,
                gps_longitude=inspection.longitude,
                capture_timestamp=inspection.created_at or datetime.now(timezone.utc),
                ocr_text_snapshot=raw_ocr_text,
                inspector_id=str(inspection.inspector_id),
                violation_data=rule_eval["rule_results"],
            )
            inspection.blockchain_hash = evidence_hash

        # 9. Update PostgreSQL Inspection Record
        inspection.status = "completed"
        inspection.overall_result = rule_eval["overall_status"].lower()
        if barcode:
            inspection.product_barcode = barcode
        await self.inspection_repo.update(inspection)

        # 10. Store unstructured extraction dump in MongoDB ai_extraction_logs (§13)
        try:
            mongo_logs = MongoDB.ai_extraction_logs()
            await mongo_logs.insert_one({
                "inspection_id": str(inspection_id),
                "timestamp": datetime.now(timezone.utc).isoformat(),
                "raw_ocr_text": raw_ocr_text,
                "evidence_hash": evidence_hash,
                "parsed_entities": [
                    {
                        "entity": e.entity_type,
                        "value": e.value,
                        "confidence": e.confidence,
                        "source_text": e.source_text,
                    }
                    for e in entities
                ],
                "words_detected": [
                    {
                        "text": w.text,
                        "confidence": w.confidence,
                        "bbox": {
                            "x": w.bounding_box.x,
                            "y": w.bounding_box.y,
                            "width": w.bounding_box.width,
                            "height": w.bounding_box.height,
                        } if w.bounding_box else None,
                    }
                    for w in ocr_result.words
                ],
                "rule_engine_results": rule_eval["rule_results"],
                "anomalies": anomalies,
                "processing_time_ms": elapsed_ms,
            })
        except Exception as mongo_exc:
            logger.warning("Failed to write to MongoDB: %s", mongo_exc)

        # 11. Assemble structured API response
        return {
            "inspection_id": inspection_id,
            "overall_status": rule_eval["overall_status"],
            "evidence_hash": evidence_hash,
            "extracted_entities": [
                {
                    "entity": e.entity_type,
                    "value": e.value,
                    "confidence": e.confidence,
                }
                for e in entities
            ],
            "rule_results": rule_eval["rule_results"],
            "gs1_comparison": gs1_info,
            "anomalies": anomalies,
            "raw_ocr_text": raw_ocr_text,
            "processing_time_ms": elapsed_ms,
            "requires_human_review": rule_eval["requires_human_review"],
            "review_reasons": rule_eval["review_reasons"],
        }
