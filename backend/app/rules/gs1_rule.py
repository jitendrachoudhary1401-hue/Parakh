"""
Project PARAKH — Barcode & Product Registry Rule (Re-export)
"""

from app.rules.openfoodfacts_rule import OpenFoodFactsRule, GS1Rule

__all__ = ["OpenFoodFactsRule", "GS1Rule"]
