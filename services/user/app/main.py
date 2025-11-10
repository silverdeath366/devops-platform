"""Main FastAPI application for user service."""

from contextlib import asynccontextmanager
from typing import AsyncGenerator
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.config import get_settings
from app.database import init_db, close_db
from app.routers import users, health
from app import __version__

settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator:
    """Lifecycle manager for startup and shutdown events."""
    # Startup
    print(f"🚀 Starting {settings.service_name} service v{__version__}")
    print(f"📊 Environment: {settings.environment}")
    await init_db()
    print("✅ Database initialized")
    
    yield
    
    # Shutdown
    print("🛑 Shutting down service...")
    await close_db()
    print("✅ Database connections closed")


# Create FastAPI app
app = FastAPI(
    title="User Service",
    description="Production-grade user management microservice",
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
app.include_router(users.router)


@app.get("/", tags=["Root"])
async def root():
    """Root endpoint."""
    return {
        "service": settings.service_name,
        "version": __version__,
        "status": "running",
    }

