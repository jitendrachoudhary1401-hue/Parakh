"""
Project PARAKH — Open Food Facts API Client

Integrates with Open Food Facts API v2 (world.openfoodfacts.org / in.openfoodfacts.org)
for global & Indian product barcode lookup, manufacturer, brand, and ingredient metadata.
"""

from __future__ import annotations

import logging
import re
from dataclasses import dataclass
from typing import Any, Dict, Optional

import httpx

from app.config import get_settings

logger = logging.getLogger("parakh.integrations.openfoodfacts")


@dataclass
class OpenFoodFactsLookupResult:
    barcode: str
    status: str  # "FOUND", "UNAVAILABLE", "SERVICE_UNAVAILABLE"
    registered_manufacturer: Optional[str] = None
    manufacturer_address: Optional[str] = None
    product_name: Optional[str] = None
    product_category: Optional[str] = None
    brand: Optional[str] = None
    quantity: Optional[str] = None
    ingredients_text: Optional[str] = None
    image_url: Optional[str] = None
    country_of_origin: Optional[str] = None
    raw_response: Optional[Dict[str, Any]] = None
    error_message: Optional[str] = None


class OpenFoodFactsClient:
    """Client for Open Food Facts API."""

    def __init__(self):
        self.settings = get_settings()
        self.api_url = getattr(
            self.settings,
            "openfoodfacts_api_url",
            "https://world.openfoodfacts.org/api/v2",
        ).rstrip("/")
        self.user_agent = getattr(
            self.settings,
            "openfoodfacts_user_agent",
            "ParakhApp/1.0 (compliance-scanner)",
        )

    async def lookup_barcode(self, barcode: str) -> OpenFoodFactsLookupResult:
        """
        Query Open Food Facts database for product, brand, and manufacturer information.

        Args:
            barcode: GTIN/EAN/UPC barcode string.

        Returns:
            OpenFoodFactsLookupResult with product metadata or status.
        """
        clean_barcode = barcode.strip() if barcode else ""
        if not clean_barcode:
            return OpenFoodFactsLookupResult(
                barcode="",
                status="UNAVAILABLE",
                error_message="No barcode provided for lookup",
            )

        digits_only = re.sub(r"\D", "", clean_barcode)
        if not digits_only:
            return OpenFoodFactsLookupResult(
                barcode=clean_barcode,
                status="UNAVAILABLE",
                error_message="Invalid barcode format",
            )

        headers = {
            "User-Agent": self.user_agent,
            "Accept": "application/json",
        }

        # Primary Open Food Facts v2 product endpoint
        url = f"{self.api_url}/product/{digits_only}.json"

        try:
            async with httpx.AsyncClient(timeout=3.0, follow_redirects=True) as client:
                logger.info("Querying Open Food Facts API for barcode: %s", digits_only)
                response = await client.get(url, headers=headers)

                if response.status_code == 200:
                    data = response.json()
                    status_code = data.get("status")

                    if status_code == 1 and "product" in data:
                        p = data["product"]

                        # Extract brand
                        brand = p.get("brands") or p.get("brand_owner")
                        if not brand and isinstance(p.get("brands_tags"), list) and p.get("brands_tags"):
                            brand = p["brands_tags"][0].replace("-", " ").title()

                        # Extract manufacturer
                        manufacturer = (
                            p.get("manufacturing_places")
                            or p.get("brand_owner")
                            or brand
                            or p.get("labels")
                        )

                        # Extract product name
                        product_name = (
                            p.get("product_name")
                            or p.get("product_name_en")
                            or p.get("generic_name")
                        )

                        # Extract category
                        category = p.get("categories")
                        if not category and isinstance(p.get("categories_tags"), list) and p.get("categories_tags"):
                            category = p["categories_tags"][0].replace("-", " ").title()

                        quantity = p.get("quantity")
                        ingredients = p.get("ingredients_text") or p.get("ingredients_text_en")
                        image_url = p.get("image_url") or p.get("image_front_url")

                        countries = p.get("countries")
                        if not countries and isinstance(p.get("countries_tags"), list) and p.get("countries_tags"):
                            countries = p["countries_tags"][0].replace("-", " ").title()

                        logger.info("Open Food Facts found product: %s by %s", product_name, manufacturer)

                        return OpenFoodFactsLookupResult(
                            barcode=clean_barcode,
                            status="FOUND",
                            registered_manufacturer=manufacturer,
                            manufacturer_address=p.get("manufacturing_places"),
                            product_name=product_name,
                            product_category=category,
                            brand=brand,
                            quantity=quantity,
                            ingredients_text=ingredients,
                            image_url=image_url,
                            country_of_origin=countries,
                            raw_response=data,
                        )
                    else:
                        logger.warning("Barcode %s not found in Open Food Facts DB", clean_barcode)
                        return OpenFoodFactsLookupResult(
                            barcode=clean_barcode,
                            status="UNAVAILABLE",
                            error_message=f"Barcode {clean_barcode} not found in Open Food Facts database",
                        )
                elif response.status_code == 404:
                    return OpenFoodFactsLookupResult(
                        barcode=clean_barcode,
                        status="UNAVAILABLE",
                        error_message=f"Barcode {clean_barcode} not found in Open Food Facts database",
                    )
                else:
                    logger.error("Open Food Facts API returned HTTP status %d: %s", response.status_code, response.text)
                    return OpenFoodFactsLookupResult(
                        barcode=clean_barcode,
                        status="SERVICE_UNAVAILABLE",
                        error_message=f"Open Food Facts API responded with HTTP {response.status_code}",
                    )

        except httpx.RequestError as exc:
            logger.error("Network error contacting Open Food Facts API: %s", exc)
            return OpenFoodFactsLookupResult(
                barcode=clean_barcode,
                status="SERVICE_UNAVAILABLE",
                error_message=f"Could not connect to Open Food Facts API: {str(exc)}",
            )
        except Exception as exc:
            logger.exception("Unexpected error in Open Food Facts lookup: %s", exc)
            return OpenFoodFactsLookupResult(
                barcode=clean_barcode,
                status="SERVICE_UNAVAILABLE",
                error_message=f"Open Food Facts lookup failed: {str(exc)}",
            )
