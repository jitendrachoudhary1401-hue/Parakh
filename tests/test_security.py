"""
Project PARAKH — Security & File Validation Tests

Per §46: Unauthorized access, file validation checks, malicious upload rejection.
"""

import pytest

from app.core.exceptions import FileValidationError
from app.security.file_validator import FileValidator


def test_file_validator_rejects_empty():
    with pytest.raises(FileValidationError):
        FileValidator.validate_image_upload(b"")


def test_file_validator_rejects_disallowed_mime():
    pdf_bytes = b"%PDF-1.4 header text data"
    with pytest.raises(FileValidationError):
        FileValidator.validate_image_upload(pdf_bytes)


def test_file_validator_rejects_embedded_scripts():
    fake_img = b"\xff\xd8\xff<script>alert('xss')</script>" + b"\x00" * 2000
    with pytest.raises(FileValidationError):
        FileValidator.validate_image_upload(fake_img)
