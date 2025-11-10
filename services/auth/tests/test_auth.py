"""Tests for auth service."""

import pytest
from httpx import AsyncClient, ASGITransport
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from app.main import app
from app.database import Base, get_db
from app.config import get_settings

# Test database URL
TEST_DATABASE_URL = "sqlite+aiosqlite:///:memory:"

# Create test engine and session
test_engine = create_async_engine(
    TEST_DATABASE_URL,
    echo=False,
)

TestSessionLocal = async_sessionmaker(
    test_engine,
    class_=AsyncSession,
    expire_on_commit=False,
)


async def override_get_db():
    """Override database dependency for tests."""
    async with TestSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()


@pytest.fixture(scope="function")
async def test_db():
    """Create test database."""
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)


@pytest.fixture(scope="function")
async def client(test_db):
    """Create test client."""
    app.dependency_overrides[get_db] = override_get_db
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac
    app.dependency_overrides.clear()


@pytest.mark.asyncio
async def test_health_check(client):
    """Test health endpoint."""
    response = await client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"
    assert data["service"] == "auth"


@pytest.mark.asyncio
async def test_healthz_check(client):
    """Test healthz endpoint."""
    response = await client.get("/healthz")
    assert response.status_code == 200


@pytest.mark.asyncio
async def test_ready_check(client):
    """Test ready endpoint."""
    response = await client.get("/ready")
    assert response.status_code == 200


@pytest.mark.asyncio
async def test_metrics_endpoint(client):
    """Test metrics endpoint."""
    response = await client.get("/metrics")
    assert response.status_code == 200
    assert "auth_requests_total" in response.text


@pytest.mark.asyncio
async def test_register_user_success(client):
    """Test successful user registration."""
    response = await client.post(
        "/auth/register",
        json={"username": "testuser", "password": "testpass123"}
    )
    assert response.status_code == 201
    data = response.json()
    assert data["message"] == "User registered successfully"


@pytest.mark.asyncio
async def test_register_user_duplicate(client):
    """Test duplicate user registration."""
    # First registration
    await client.post(
        "/auth/register",
        json={"username": "testuser", "password": "testpass123"}
    )
    # Duplicate registration
    response = await client.post(
        "/auth/register",
        json={"username": "testuser", "password": "testpass123"}
    )
    assert response.status_code == 400
    assert "already exists" in response.json()["detail"]


@pytest.mark.asyncio
async def test_register_invalid_payload(client):
    """Test registration with invalid payload."""
    response = await client.post("/auth/register", json={})
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_login_success(client):
    """Test successful login."""
    # Register user first
    await client.post(
        "/auth/register",
        json={"username": "testuser", "password": "testpass123"}
    )
    # Login
    response = await client.post(
        "/auth/login",
        json={"username": "testuser", "password": "testpass123"}
    )
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert data["token_type"] == "bearer"


@pytest.mark.asyncio
async def test_login_invalid_credentials(client):
    """Test login with invalid credentials."""
    response = await client.post(
        "/auth/login",
        json={"username": "nonexistent", "password": "wrongpass"}
    )
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_login_invalid_payload(client):
    """Test login with invalid payload."""
    response = await client.post("/auth/login", json={})
    assert response.status_code == 422
