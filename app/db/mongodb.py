"""
Project PARAKH — MongoDB Connection

Async Motor client for MongoDB (stores AI extraction logs and unstructured data).
"""

from __future__ import annotations

from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorDatabase

from app.config import get_settings


class MongoDB:
    """MongoDB connection manager."""

    client: AsyncIOMotorClient | None = None
    database: AsyncIOMotorDatabase | None = None

    @classmethod
    def connect(cls) -> None:
        """Initialise the Motor async client."""
        settings = get_settings()
        cls.client = AsyncIOMotorClient(settings.mongodb_url)
        cls.database = cls.client[settings.mongodb_database]

    @classmethod
    def close(cls) -> None:
        """Close the Motor client."""
        if cls.client is not None:
            cls.client.close()
            cls.client = None
            cls.database = None

    @classmethod
    def get_database(cls) -> AsyncIOMotorDatabase:
        """Return the database instance, connecting if necessary."""
        if cls.database is None:
            cls.connect()
        return cls.database

    # --- Collection Accessors ---

    @classmethod
    def ai_extraction_logs(cls):
        """
        ai_extraction_logs collection.

        Stores per-inspection:
        - inspection_id
        - raw_ocr_text
        - parsed_entities (with bounding boxes, confidence)
        - rule_engine_results
        - processing_metadata
        """
        return cls.get_database()["ai_extraction_logs"]

    @classmethod
    def anomaly_reports(cls):
        """
        anomaly_reports collection.

        Stores ViT-based anomaly detection results.
        """
        return cls.get_database()["anomaly_reports"]

    @classmethod
    def predictive_cache(cls):
        """
        predictive_cache collection.

        Caches computed predictive analytics results.
        """
        return cls.get_database()["predictive_cache"]


async def get_mongodb() -> AsyncIOMotorDatabase:
    """FastAPI dependency that provides the MongoDB database instance."""
    return MongoDB.get_database()
