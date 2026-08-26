"""
Project PARAKH — WhatsApp Business API Client

Integrates with Meta WhatsApp Business Cloud API per §32 for citizen reporting.
Returns service unavailable if credentials are not configured.
"""

from __future__ import annotations

import logging
from typing import Any, Dict, Optional

import httpx

from app.config import get_settings

logger = logging.getLogger("parakh.integrations.whatsapp")


class WhatsAppClient:
    """WhatsApp Business Cloud API client."""

    def __init__(self):
        self.settings = get_settings()
        self.enabled = self.settings.whatsapp_enabled
        self.api_url = self.settings.whatsapp_api_url
        self.access_token = self.settings.whatsapp_access_token
        self.phone_number_id = self.settings.whatsapp_phone_number_id
        self.verify_token = self.settings.whatsapp_verify_token

    def verify_webhook(self, mode: str, token: str, challenge: str) -> Optional[str]:
        """Verify webhook subscription challenge from WhatsApp/Meta."""
        if mode == "subscribe" and token == self.verify_token:
            return challenge
        return None

    async def send_message(self, recipient_phone: str, text: str) -> bool:
        """Send text status update message to citizen over WhatsApp."""
        if not self.enabled or not self.access_token or not self.phone_number_id:
            logger.info("WhatsApp messaging skipped: integration disabled or unconfigured")
            return False

        try:
            url = f"{self.api_url}/{self.phone_number_id}/messages"
            headers = {
                "Authorization": f"Bearer {self.access_token}",
                "Content-Type": "application/json",
            }
            payload = {
                "messaging_product": "whatsapp",
                "recipient_type": "individual",
                "to": recipient_phone,
                "type": "text",
                "text": {"preview_url": False, "body": text},
            }
            async with httpx.AsyncClient(timeout=10.0) as client:
                response = await client.post(url, json=payload, headers=headers)
                if response.status_code in (200, 201):
                    return True
                logger.error("WhatsApp API error %d: %s", response.status_code, response.text)
                return False
        except Exception as exc:
            logger.error("Failed to send WhatsApp message: %s", exc)
            return False

    async def download_media(self, media_id: str) -> Optional[bytes]:
        """Download uploaded product image from WhatsApp media endpoint."""
        if not self.enabled or not self.access_token:
            return None

        try:
            headers = {"Authorization": f"Bearer {self.access_token}"}
            async with httpx.AsyncClient(timeout=15.0) as client:
                # Step 1: Get media URL
                media_meta_resp = await client.get(f"{self.api_url}/{media_id}", headers=headers)
                if media_meta_resp.status_code != 200:
                    return None
                media_url = media_meta_resp.json().get("url")
                if not media_url:
                    return None

                # Step 2: Download raw binary
                media_data_resp = await client.get(media_url, headers=headers)
                if media_data_resp.status_code == 200:
                    return media_data_resp.content
                return None
        except Exception as exc:
            logger.error("Failed to download WhatsApp media (%s): %s", media_id, exc)
            return None
