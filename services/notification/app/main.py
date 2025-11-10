"""Main FastAPI application for notification service."""

from contextlib import asynccontextmanager
from typing import AsyncGenerator
import logging
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.config import get_settings
from app.routers import notifications, health
from app import __version__

settings = get_settings()

# Configure logging
logging.basicConfig(
    level=logging.INFO if not settings.debug else logging.DEBUG,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator:
    """Lifecycle manager for startup and shutdown events."""
    # Startup
    print(f"🚀 Starting {settings.service_name} service v{__version__}")
    print(f"📊 Environment: {settings.environment}")
    print("✅ Notification service ready")
    
    yield
    
    # Shutdown
    print("🛑 Shutting down service...")
    print("✅ Cleanup complete")


# Create FastAPI app
app = FastAPI(
    title="Notification Service",
    description="Production-grade notification microservice",
    version=__version__,
    lifespan=lifespan,
    docs_url="/docs" if settings.debug else None,
    redoc_url="/redoc" if settings.debug else None,
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(health.router)
app.include_router(notifications.router)


@app.get("/", tags=["Root"])
async def root():
    """Root endpoint."""
    return {
        "service": settings.service_name,
        "version": __version__,
        "status": "running",
    }

