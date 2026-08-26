"""
Project PARAKH — File Validation Utility

Implements §36:
Validates MIME type (magic bytes), file size, image integrity, minimum resolution,
and checks for suspicious payloads. Rejects invalid uploads.
"""

from __future__ import annotations

import io
import logging
from typing import Tuple

from PIL import Image

from app.config import get_settings
from app.core.exceptions import FileValidationError

logger = logging.getLogger("parakh.security.file_validator")


class FileValidator:
    """Validator for uploaded inspection images and files."""

    ALLOWED_MIME_TYPES = {"image/jpeg", "image/png", "image/webp"}
    MAGIC_SIGNATURES = {
        b"\xff\xd8\xff": "image/jpeg",
        b"\x89PNG\r\n\x1a\n": "image/png",
        b"RIFF": "image/webp",
    }

    @classmethod
    def validate_image_upload(cls, file_bytes: bytes, filename: str = "") -> Tuple[bool, str]:
        settings = get_settings()

        # 1. Check file size
        if len(file_bytes) == 0:
            raise FileValidationError("Uploaded file is empty (0 bytes)")
        if len(file_bytes) > settings.max_upload_size_bytes:
            raise FileValidationError(
                f"File size ({len(file_bytes) / (1024*1024):.1f} MB) exceeds maximum allowed {settings.max_upload_size_mb} MB"
            )

        # 2. Magic byte / MIME type validation
        detected_mime = None
        for magic, mime in cls.MAGIC_SIGNATURES.items():
            if file_bytes.startswith(magic):
                detected_mime = mime
                break

        if detected_mime is None or detected_mime not in cls.ALLOWED_MIME_TYPES:
            raise FileValidationError(
                f"Invalid file format or header. Allowed formats: JPEG, PNG, WEBP. Detected: {detected_mime or 'unknown'}"
            )

        # 3. Image integrity verification using Pillow
        try:
            with Image.open(io.BytesIO(file_bytes)) as img:
                img.verify()  # Verifies file integrity without decoding whole image
        except Exception as exc:
            logger.warning("Image verification failed: %s", exc)
            raise FileValidationError("Image file is corrupted or cannot be decoded safely")

        # 4. Dimension / Resolution check
        try:
            with Image.open(io.BytesIO(file_bytes)) as img:
                width, height = img.size
                if width < settings.min_image_resolution or height < settings.min_image_resolution:
                    raise FileValidationError(
                        f"Image resolution ({width}x{height}) is below the required minimum of {settings.min_image_resolution}x{settings.min_image_resolution}"
                    )
        except FileValidationError:
            raise
        except Exception as exc:
            raise FileValidationError(f"Could not read image dimensions: {str(exc)}")

        # 5. Check for embedded script tags / basic polyglot check
        # Scan first 2KB for executable or script tags
        head_sample = file_bytes[:2048].lower()
        suspicious_markers = [b"<script", b"<?php", b"<% ", b"eval(", b"base64_decode"]
        for marker in suspicious_markers:
            if marker in head_sample:
                logger.warning("Suspicious marker %s found in image file header", marker)
                raise FileValidationError("File contains disallowed executable patterns")

        return True, detected_mime
