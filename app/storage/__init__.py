"""
Project PARAKH — Storage Backend Factory & Package

Replaces proprietary cloud storage (AWS/Azure) with open, self-hosted alternatives:
- MinIO: High-performance, S3-compatible, sovereign cloud/K8s storage
- Local: Encrypted filesystem storage for isolated edge/on-prem nodes
"""

from functools import lru_cache

from app.config import get_settings
from app.storage.base import BaseStorage
from app.storage.local_storage import LocalStorage
from app.storage.minio_storage import MinIOStorage


@lru_cache()
def get_storage_backend() -> BaseStorage:
    """Get the configured storage backend singleton."""
    settings = get_settings()
    if settings.storage_provider == "local":
        return LocalStorage()
    return MinIOStorage()


__all__ = ["BaseStorage", "MinIOStorage", "LocalStorage", "get_storage_backend"]
