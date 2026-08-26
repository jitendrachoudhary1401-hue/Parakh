"""
Project PARAKH — Storage Backend Interface
"""

from __future__ import annotations

from abc import ABC, abstractmethod
from typing import Optional


class BaseStorage(ABC):
    """Abstract object storage provider interface."""

    @abstractmethod
    async def upload_file(
        self,
        file_bytes: bytes,
        destination_path: str,
        content_type: str = "application/octet-stream",
    ) -> str:
        """
        Upload a file to object storage.
        
        Returns:
            Internal storage key/path.
        """
        pass

    @abstractmethod
    async def get_presigned_url(
        self,
        storage_path: str,
        expiry_seconds: Optional[int] = None,
    ) -> str:
        """Generate a time-limited presigned URL for secure authorized download."""
        pass

    @abstractmethod
    async def download_file(self, storage_path: str) -> bytes:
        """Download raw file bytes from object storage."""
        pass

    @abstractmethod
    async def delete_file(self, storage_path: str) -> bool:
        """Delete a file from object storage."""
        pass
