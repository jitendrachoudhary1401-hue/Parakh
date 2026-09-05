"""
Project PARAKH — Advanced Legal Metrology Compliance System
Problem Statement ID: 26034
Ministry of Consumer Affairs, Food & Public Distribution (DoCA)

FastAPI Application Entry Point & API Gateway per §7.
"""

from __future__ import annotations

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from slowapi.errors import RateLimitExceeded
from slowapi.middleware import SlowAPIMiddleware

from app.api.v1.health import router as health_router
from app.api.v1.router import api_v1_router
from app.config import get_settings
from app.core.exceptions import register_exception_handlers
from app.core.middleware import setup_middleware
from app.core.rate_limiter import limiter
from app.db.mongodb import MongoDB
from app.db.postgres import close_db

# Configure application logger
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger("parakh.app")


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application startup and graceful shutdown lifecycle."""
    settings = get_settings()
    logger.info("Initializing %s backend (Env: %s)", settings.app_name, settings.app_env)

    # Initialize MongoDB connection
    MongoDB.connect()
    logger.info("MongoDB client connected to %s", settings.mongodb_database)

    # Initialize PostgreSQL DB tables & seed data
    from app.db.postgres import init_db
    await init_db()
    logger.info("PostgreSQL tables initialized and seeded successfully.")

    yield

    # Teardown
    logger.info("Shutting down %s backend...", settings.app_name)
    MongoDB.close()
    await close_db()
    logger.info("Database connection pools closed successfully.")


def create_app() -> FastAPI:
    """Build and configure the main FastAPI application."""
    settings = get_settings()

    app = FastAPI(
        title="Project PARAKH API",
        description=(
            "Advanced AI-Powered Legal Metrology Compliance System (Problem Statement ID: 26034).\n\n"
            "Exposes secure RESTful APIs for mobile enforcement, administrative oversight, "
            "AI vision processing, compliance validation, and Hyperledger Fabric evidence integrity."
        ),
        version="1.0.0",
        docs_url="/docs" if not settings.is_production else None,
        redoc_url="/redoc" if not settings.is_production else None,
        openapi_url="/openapi.json" if not settings.is_production else None,
        lifespan=lifespan,
    )

    # Attach SlowAPI rate limiter state
    app.state.limiter = limiter
    app.add_middleware(SlowAPIMiddleware)

    # Configure middleware (CORS, secure headers, request logging)
    setup_middleware(app)

    # Register standardized exception handlers
    register_exception_handlers(app)

    # Root health probes
    app.include_router(health_router)

    # Mount master versioned API
    app.include_router(api_v1_router)

    logger.info("PARAKH backend application initialized successfully")
    return app


app = create_app()

if __name__ == "__main__":
    import uvicorn
    settings = get_settings()
    uvicorn.run(
        "app.main:app",
        host=settings.host,
        port=settings.port,
        reload=settings.debug,
        workers=settings.workers if not settings.debug else 1,
    )
