"""
Project PARAKH — GS1 India API Client

Integrates with GS1 India Datakart/API per §18.
Never fabricates external API responses.
Returns SERVICE_UNAVAILABLE or UNAVAILABLE on failure.
"""

from __future__ import annotations

import logging
from dataclasses import dataclass
from typing import Any, Dict, Optional

import httpx

from app.config import get_settings

logger = logging.getLogger("parakh.integrations.gs1")


@dataclass
class GS1LookupResult:
    barcode: str
    status: str  # "MATCH", "MISMATCH", "UNAVAILABLE", "SERVICE_UNAVAILABLE"
    registered_manufacturer: Optional[str] = None
    manufacturer_address: Optional[str] = None
    product_name: Optional[str] = None
    product_category: Optional[str] = None
    brand: Optional[str] = None
    raw_response: Optional[Dict[str, Any]] = None
    error_message: Optional[str] = None


class GS1Client:
    """Client for GS1 India Barcode Registry API."""

    def __init__(self):
        self.settings = get_settings()
        self.api_url = self.settings.gs1_api_url
        self.api_key = self.settings.gs1_api_key

    async def lookup_barcode(self, barcode: str) -> GS1LookupResult:
        """
        Query GS1 India registry for product and manufacturer information.

        Never fabricates mock data. If API key or URL is unavailable, returns SERVICE_UNAVAILABLE.
        """
        clean_barcode = barcode.strip() if barcode else ""
        if not clean_barcode:
            return GS1LookupResult(
                barcode="",
                status="UNAVAILABLE",
                error_message="No barcode provided for lookup",
            )

        if not self.api_key:
            logger.warning("GS1_API_KEY is not configured")
            return GS1LookupResult(
                barcode=clean_barcode,
                status="SERVICE_UNAVAILABLE",
                error_message="GS1 India API key is not configured in environment",
            )

        try:
            headers = {
                "Authorization": f"Bearer {self.api_key}",
                "Accept": "application/json",
            }
            async with httpx.AsyncClient(timeout=10.0) as client:
                response = await client.get(
                    f"{self.api_url}/products/{clean_barcode}",
                    headers=headers,
                )

                if response.status_code == 200:
                    data = response.json()
                    mfg = data.get("company_name") or data.get("manufacturer_name") or data.get("brand_owner")
                    return GS1LookupResult(
                        barcode=clean_barcode,
                        status="FOUND",
                        registered_manufacturer=mfg,
                        manufacturer_address=data.get("address"),
                        product_name=data.get("product_name"),
                        product_category=data.get("category"),
                        brand=data.get("brand"),
                        raw_response=data,
                    )
                elif response.status_code == 404:
                    return GS1LookupResult(
                        barcode=clean_barcode,
                        status="UNAVAILABLE",
                        error_message=f"Barcode {clean_barcode} is not registered in GS1 India database",
                    )
                else:
                    logger.error("GS1 API returned status %d: %s", response.status_code, response.text)
                    return GS1LookupResult(
                        barcode=clean_barcode,
                        status="SERVICE_UNAVAILABLE",
                        error_message=f"GS1 India API responded with HTTP {response.status_code}",
                    )

        except httpx.RequestError as exc:
            logger.error("Network error contacting GS1 API: %s", exc)
            return GS1LookupResult(
                barcode=clean_barcode,
                status="SERVICE_UNAVAILABLE",
                error_message=f"Could not connect to GS1 India API: {str(exc)}",
            )
        except Exception as exc:
            logger.exception("Unexpected error in GS1 lookup: %s", exc)
            return GS1LookupResult(
                barcode=clean_barcode,
                status="SERVICE_UNAVAILABLE",
                error_message=f"GS1 lookup failed: {str(exc)}",
            )
