"""Health check and metrics endpoints."""

from datetime import datetime
from fastapi import APIRouter, Response
from app.schemas import HealthResponse
from app.config import get_settings
from app import __version__

router = APIRouter(tags=["Health"])
settings = get_settings()

# Simple metrics storage (in production, use Prometheus client library)
request_count = 0
start_time = datetime.utcnow()


@router.get(
    "/health",
    response_model=HealthResponse,
    summary="Health check",
)
async def health() -> HealthResponse:
    """Check service health status."""
    return HealthResponse(
        status="ok",
        service=settings.service_name,
        version=__version__,
        timestamp=datetime.utcnow(),
    )


@router.get(
    "/healthz",
    response_model=HealthResponse,
    summary="Kubernetes health check",
)
async def healthz() -> HealthResponse:
    """Kubernetes-style health check endpoint."""
    return await health()


@router.get(
    "/ready",
    response_model=HealthResponse,
    summary="Readiness check",
)
async def ready() -> HealthResponse:
    """Check if service is ready to accept traffic."""
    # Add database connectivity check in production
    return HealthResponse(
        status="ready",
        service=settings.service_name,
        version=__version__,
        timestamp=datetime.utcnow(),
    )


@router.get(
    "/metrics",
    summary="Prometheus metrics",
    response_class=Response,
)
async def metrics() -> Response:
    """Expose Prometheus-compatible metrics."""
    global request_count
    request_count += 1
    
    uptime = (datetime.utcnow() - start_time).total_seconds()
    
    metrics_output = f"""# HELP auth_requests_total Total number of requests
# TYPE auth_requests_total counter
auth_requests_total {request_count}

# HELP auth_uptime_seconds Service uptime in seconds
# TYPE auth_uptime_seconds gauge
auth_uptime_seconds {uptime}

# HELP auth_info Service information
# TYPE auth_info gauge
auth_info{{version="{__version__}",service="{settings.service_name}"}} 1
"""
    
    return Response(content=metrics_output, media_type="text/plain")

