"""
Project PARAKH — Scan / Upload Schemas
"""

from __future__ import annotations

from typing import Optional
from uuid import UUID

from pydantic import BaseModel, Field


class UploadResponse(BaseModel):
    """Response after successful image upload."""
    inspection_id: UUID
    image_storage_path: str
    upload_status: str = "success"
    message: str = "Image uploaded successfully"


class UploadMetadata(BaseModel):
    """Optional metadata sent alongside the image upload."""
    product_barcode: Optional[str] = None
    latitude: Optional[float] = Field(None, ge=-90, le=90)
    longitude: Optional[float] = Field(None, ge=-180, le=180)
    location_name: Optional[str] = None
    notes: Optional[str] = None
    # For offline sync
    client_timestamp: Optional[str] = None
    client_inspection_id: Optional[str] = None
