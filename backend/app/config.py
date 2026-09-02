"""
Project PARAKH — Application Configuration

All settings are loaded from environment variables via pydantic-settings.
No secrets are hardcoded. Self-hosted and sovereign software only (MinIO / Local).
"""

from __future__ import annotations

from functools import lru_cache
from typing import List, Optional

from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Central configuration loaded from environment variables."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # --- Application ---
    app_name: str = "PARAKH"
    app_env: str = "development"
    debug: bool = False
    log_level: str = "INFO"

    # --- Server ---
    host: str = "0.0.0.0"
    port: int = 8000
    workers: int = 4

    # --- PostgreSQL ---
    database_url: str = "postgresql+asyncpg://parakh_user:Mario%40123@127.0.0.1:5432/parakh_db"
    database_url_sync: str = "postgresql://parakh_user:Mario%40123@127.0.0.1:5432/parakh_db"
    db_pool_size: int = 20
    db_max_overflow: int = 10

    # --- MongoDB ---
    mongodb_url: str = "mongodb://localhost:27017"
    mongodb_database: str = "parakh_db"

    # --- PostgreSQL Cache & Queue ---
    use_postgres_cache: bool = True
    use_postgres_queue: bool = True
    cache_ttl_default: int = 3600

    # --- API Key Authentication ---
    api_key: str = "parakh_sec_api_key_2026"

    # --- JWT / Authentication ---
    jwt_secret_key: str = "CHANGE_ME_TO_A_STRONG_RANDOM_SECRET"
    jwt_algorithm: str = "HS256"
    jwt_access_token_expire_minutes: int = 30
    jwt_refresh_token_expire_days: int = 7

    # --- Google Cloud Vision (OCR) ---
    google_cloud_vision_key: Optional[str] = None
    google_application_credentials: Optional[str] = None
    google_cloud_vision_credentials_json: Optional[str] = None

    # --- Open Food Facts API ---
    openfoodfacts_api_url: str = "https://world.openfoodfacts.org/api/v2"
    openfoodfacts_user_agent: str = "ParakhApp/1.0 (compliance-scanner)"

    # Backwards compatibility settings
    gs1_api_url: str = "https://world.openfoodfacts.org/api/v2"
    gs1_api_key: Optional[str] = None

    # --- Object Storage (Self-Hosted MinIO / Local) ---
    storage_provider: str = "minio"  # "minio" or "local"

    # MinIO Configuration
    minio_endpoint_url: str = "http://localhost:9000"
    minio_bucket: str = "parakh-storage"
    minio_access_key: str = "minioadmin"
    minio_secret_key: str = "minioadmin"
    minio_region: str = "us-east-1"
    minio_presigned_url_expiry_seconds: int = 3600

    # Local Filesystem Storage Configuration (if storage_provider=local)
    local_storage_path: str = "./storage_data"

    # --- Hyperledger Fabric (Blockchain) ---
    blockchain_enabled: bool = False
    blockchain_endpoint: str = "grpc://localhost:7051"
    blockchain_network: str = "parakh-network"
    blockchain_channel: str = "evidence-channel"
    blockchain_chaincode: str = "parakh-evidence"
    blockchain_msp_id: str = "Org1MSP"
    blockchain_cert_path: Optional[str] = None
    blockchain_key_path: Optional[str] = None

    # --- WhatsApp Business API ---
    whatsapp_enabled: bool = False
    whatsapp_api_url: str = "https://graph.facebook.com/v18.0"
    whatsapp_access_token: Optional[str] = None
    whatsapp_phone_number_id: Optional[str] = None
    whatsapp_verify_token: Optional[str] = None

    # --- CORS ---
    allowed_frontend_origins: str = "http://localhost:3000,http://localhost:5173"

    # --- Rate Limiting ---
    rate_limit_login: str = "5/minute"
    rate_limit_upload: str = "20/minute"
    rate_limit_analysis: str = "10/minute"
    rate_limit_evidence: str = "10/minute"
    rate_limit_citizen_report: str = "5/minute"
    rate_limit_default: str = "60/minute"

    # --- File Upload ---
    max_upload_size_mb: int = 25
    allowed_image_types: str = "image/jpeg,image/png,image/webp"
    min_image_resolution: int = 640

    # --- AI / ML ---
    ner_model_name: str = "dslim/bert-base-NER"
    vit_model_name: str = "google/vit-base-patch16-224"
    ner_confidence_threshold: float = 0.5
    anomaly_detection_enabled: bool = True

    # --- Encryption ---
    encryption_key: Optional[str] = None

    # --- Audit ---
    audit_log_enabled: bool = True

    # --- Computed Properties ---

    @property
    def cors_origins(self) -> List[str]:
        return [
            origin.strip()
            for origin in self.allowed_frontend_origins.split(",")
            if origin.strip()
        ]

    @property
    def allowed_image_types_list(self) -> List[str]:
        return [
            mime.strip()
            for mime in self.allowed_image_types.split(",")
            if mime.strip()
        ]

    @property
    def max_upload_size_bytes(self) -> int:
        return self.max_upload_size_mb * 1024 * 1024

    @property
    def is_production(self) -> bool:
        return self.app_env == "production"

    @field_validator("jwt_secret_key")
    @classmethod
    def validate_jwt_secret(cls, v: str) -> str:
        if v == "CHANGE_ME_TO_A_STRONG_RANDOM_SECRET":
            import warnings
            warnings.warn(
                "JWT_SECRET_KEY is using the default value. "
                "Generate a strong random secret for production.",
                stacklevel=2,
            )
        return v


@lru_cache()
def get_settings() -> Settings:
    return Settings()
