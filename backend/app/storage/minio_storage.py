"""
Project PARAKH — MinIO / Open-Standard S3 Object Storage Provider

High-performance, Kubernetes-ready, self-hosted object storage (§14).
Runs seamlessly on sovereign clouds (NIC MeghRaj) and on-premise infrastructure.
"""

from __future__ import annotations

import io
import logging
from typing import Optional

from app.config import get_settings
from app.storage.base import BaseStorage

logger = logging.getLogger("parakh.storage.minio")


class MinIOStorage(BaseStorage):
    """MinIO / Open S3-compatible Object Storage provider."""

    def __init__(self):
        self.settings = get_settings()
        self.bucket_name = self.settings.minio_bucket
        self._client = None

    def _get_client(self):
        if self._client is None:
            import boto3
            from botocore.config import Config

            session = boto3.session.Session()
            client_kwargs = {
                "service_name": "s3",
                "endpoint_url": self.settings.minio_endpoint_url,
                "aws_access_key_id": self.settings.minio_access_key,
                "aws_secret_access_key": self.settings.minio_secret_key,
                "region_name": self.settings.minio_region,
                "config": Config(s3={"addressing_style": "path"}, signature_version="s3v4"),
            }
            self._client = session.client(**client_kwargs)

            # Ensure bucket exists
            try:
                self._client.head_bucket(Bucket=self.bucket_name)
            except Exception:
                try:
                    self._client.create_bucket(Bucket=self.bucket_name)
                    logger.info("Created MinIO bucket: %s", self.bucket_name)
                except Exception as b_exc:
                    logger.warning("Could not auto-create bucket %s: %s", self.bucket_name, b_exc)

        return self._client

    async def upload_file(
        self,
        file_bytes: bytes,
        destination_path: str,
        content_type: str = "application/octet-stream",
    ) -> str:
        try:
            client = self._get_client()
            client.upload_fileobj(
                io.BytesIO(file_bytes),
                self.bucket_name,
                destination_path,
                ExtraArgs={"ContentType": content_type},
            )
            return destination_path
        except Exception as exc:
            logger.error("Failed to upload file to MinIO (%s): %s", destination_path, exc)
            raise

    async def get_presigned_url(
        self,
        storage_path: str,
        expiry_seconds: Optional[int] = None,
    ) -> str:
        expiry = expiry_seconds or self.settings.minio_presigned_url_expiry_seconds
        try:
            client = self._get_client()
            url = client.generate_presigned_url(
                ClientMethod="get_object",
                Params={"Bucket": self.bucket_name, "Key": storage_path},
                ExpiresIn=expiry,
            )
            return url
        except Exception as exc:
            logger.error("Failed to generate presigned URL for %s: %s", storage_path, exc)
            return f"/api/v1/storage/download?path={storage_path}"

    async def download_file(self, storage_path: str) -> bytes:
        try:
            client = self._get_client()
            fileobj = io.BytesIO()
            client.download_fileobj(self.bucket_name, storage_path, fileobj)
            return fileobj.getvalue()
        except Exception as exc:
            logger.error("Failed to download file from MinIO (%s): %s", storage_path, exc)
            raise

    async def delete_file(self, storage_path: str) -> bool:
        try:
            client = self._get_client()
            client.delete_object(Bucket=self.bucket_name, Key=storage_path)
            return True
        except Exception as exc:
            logger.error("Failed to delete file from MinIO (%s): %s", storage_path, exc)
            return False
