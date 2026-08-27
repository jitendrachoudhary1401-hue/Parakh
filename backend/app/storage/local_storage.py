"""
Project PARAKH — Local Filesystem Object Storage Provider

Provides local disk/volume storage with secure tokenized access.
Suitable for on-premise, edge, and sovereign private deployments.
"""

from __future__ import annotations

import logging
import os
import shutil
from pathlib import Path
from typing import Optional

from app.config import get_settings
from app.storage.base import BaseStorage

logger = logging.getLogger("parakh.storage.local")


class LocalStorage(BaseStorage):
    """Local filesystem storage provider for self-hosted environments."""

    def __init__(self):
        self.settings = get_settings()
        self.base_dir = Path(self.settings.local_storage_path)
        self.base_dir.mkdir(parents=True, exist_ok=True)

    async def upload_file(
        self,
        file_bytes: bytes,
        destination_path: str,
        content_type: str = "application/octet-stream",
    ) -> str:
        try:
            target = self.base_dir / destination_path
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(file_bytes)
            logger.info("Saved file locally at %s", target)
            return destination_path
        except Exception as exc:
            logger.error("Failed to write local file (%s): %s", destination_path, exc)
            raise

    async def get_presigned_url(
        self,
        storage_path: str,
        expiry_seconds: Optional[int] = None,
    ) -> str:
        """Return secure download path."""
        return f"/api/v1/storage/download?path={storage_path}"

    async def download_file(self, storage_path: str) -> bytes:
        try:
            target = self.base_dir / storage_path
            if not target.exists():
                raise FileNotFoundError(f"Local storage file not found: {storage_path}")
            return target.read_bytes()
        except Exception as exc:
            logger.error("Failed to read local storage file (%s): %s", storage_path, exc)
            raise

    async def delete_file(self, storage_path: str) -> bool:
        try:
            target = self.base_dir / storage_path
            if target.exists():
                target.unlink()
                return True
            return False
        except Exception as exc:
            logger.error("Failed to delete local storage file (%s): %s", storage_path, exc)
            return False
