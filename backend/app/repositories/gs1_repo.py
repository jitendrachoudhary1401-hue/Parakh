"""
Project PARAKH — Product Registry Repository (Re-export)
"""

from app.repositories.openfoodfacts_repo import OpenFoodFactsRepository, GS1Repository

__all__ = ["OpenFoodFactsRepository", "GS1Repository"]
