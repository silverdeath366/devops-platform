"""Tests for notification service."""

import pytest
from httpx import AsyncClient, ASGITransport
from app.main import app


@pytest.fixture(scope="function")
async def client():
    """Create test client."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac


@pytest.mark.asyncio
async def test_health_check(client):
    """Test health endpoint."""
    response = await client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"


@pytest.mark.asyncio
async def test_metrics_endpoint(client):
    """Test metrics endpoint."""
    response = await client.get("/metrics")
    assert response.status_code == 200
    assert "notification_requests_total" in response.text


@pytest.mark.asyncio
async def test_send_notification(client):
    """Test sending a notification."""
    response = await client.post(
        "/notifications/notify",
        json={
            "user_id": 1,
            "message": "Test notification",
            "notification_type": "email"
        }
    )
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "sent"
    assert data["user_id"] == 1


@pytest.mark.asyncio
async def test_send_notification_invalid_payload(client):
    """Test sending notification with invalid payload."""
    response = await client.post("/notifications/notify", json={})
    assert response.status_code == 422
