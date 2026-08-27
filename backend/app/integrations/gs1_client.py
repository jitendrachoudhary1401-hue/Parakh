"""
Project PARAKH — Barcode & Product Registry Client (Open Food Facts Integration)

Delegates barcode lookups to the Open Food Facts API v2 for global & Indian product metadata.
Maintains backwards compatibility for GS1 legacy references.
"""

from __future__ import annotations

from app.integrations.openfoodfacts_client import (
    OpenFoodFactsClient,
    OpenFoodFactsLookupResult,
)

# Backwards compatibility aliases
GS1LookupResult = OpenFoodFactsLookupResult


class GS1Client(OpenFoodFactsClient):
    """
    GS1Client wrapper delegating product barcode lookups to Open Food Facts API.
    """

    def __init__(self):
        super().__init__()
        self.api_key = None

    def resolve_prefix(self, barcode: str):
        """Helper method for legacy country prefix lookup."""
        return None
