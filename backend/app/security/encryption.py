"""
Project PARAKH — AES-256 Encryption Helpers

Supports AES-GCM-256 authenticated encryption at rest per §34.
"""

from __future__ import annotations

import base64
import os
from typing import Optional

from cryptography.hazmat.primitives.ciphers.aead import AESGCM

from app.config import get_settings


class EncryptionService:
    """AES-GCM-256 authenticated encryption service."""

    @classmethod
    def get_key(cls) -> bytes:
        settings = get_settings()
        if settings.encryption_key:
            try:
                key = base64.b64decode(settings.encryption_key)
                if len(key) == 32:
                    return key
            except Exception:
                pass
        # Fallback 32-byte key derived from jwt secret
        import hashlib
        return hashlib.sha256(settings.jwt_secret_key.encode()).digest()

    @classmethod
    def encrypt(cls, plaintext: bytes, associated_data: Optional[bytes] = None) -> bytes:
        """
        Encrypt data using AES-256-GCM.
        Returns nonce (12 bytes) + ciphertext + authentication tag (16 bytes).
        """
        key = cls.get_key()
        aesgcm = AESGCM(key)
        nonce = os.urandom(12)
        ciphertext = aesgcm.encrypt(nonce, plaintext, associated_data)
        return nonce + ciphertext

    @classmethod
    def decrypt(cls, encrypted_data: bytes, associated_data: Optional[bytes] = None) -> bytes:
        """Decrypt AES-256-GCM encrypted payload."""
        if len(encrypted_data) < 28:
            raise ValueError("Invalid encrypted data length")
        key = cls.get_key()
        aesgcm = AESGCM(key)
        nonce = encrypted_data[:12]
        ciphertext = encrypted_data[12:]
        return aesgcm.decrypt(nonce, ciphertext, associated_data)
