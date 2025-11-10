"""Tests for user service."""

import pytest
from httpx import AsyncClient, ASGITransport
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from app.main import app
from app.database import Base, get_db

# Test database URL
TEST_DATABASE_URL = "sqlite+aiosqlite:///:memory:"

# Create test engine and session
test_engine = create_async_engine(TEST_DATABASE_URL, echo=False)
TestSessionLocal = async_sessionmaker(test_engine, class_=AsyncSession, expire_on_commit=False)


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


@pytest.mark.asyncio
async def test_metrics_endpoint(client):
    """Test metrics endpoint."""
    response = await client.get("/metrics")
    assert response.status_code == 200
    assert "user_requests_total" in response.text


@pytest.mark.asyncio
async def test_create_user_success(client):
    """Test creating a new user."""
    response = await client.post(
        "/users",
        json={
            "name": "Test User",
            "username": "testuser",
            "email": "test@example.com",
            "password": "testpass123"
        }
    )
    assert response.status_code == 201
    data = response.json()
    assert data["username"] == "testuser"
    assert data["email"] == "test@example.com"
    assert "id" in data


@pytest.mark.asyncio
async def test_create_user_duplicate_username(client):
    """Test creating user with duplicate username."""
    await client.post(
        "/users",
        json={
            "name": "Test User",
            "username": "testuser",
            "email": "test@example.com",
            "password": "testpass123"
        }
    )
    response = await client.post(
        "/users",
        json={
            "name": "Test User 2",
            "username": "testuser",
            "email": "test2@example.com",
            "password": "testpass123"
        }
    )
    assert response.status_code == 400


@pytest.mark.asyncio
async def test_list_users(client):
    """Test listing users."""
    # Create a user first
    await client.post(
        "/users",
        json={
            "name": "Test User",
            "username": "testuser",
            "email": "test@example.com",
            "password": "testpass123"
        }
    )
    response = await client.get("/users")
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert len(data) == 1


@pytest.mark.asyncio
async def test_get_user_by_id(client):
    """Test getting user by ID."""
    create_response = await client.post(
        "/users",
        json={
            "name": "Test User",
            "username": "testuser",
            "email": "test@example.com",
            "password": "testpass123"
        }
    )
    user_id = create_response.json()["id"]
    
    response = await client.get(f"/users/{user_id}")
    assert response.status_code == 200
    data = response.json()
    assert data["id"] == user_id


@pytest.mark.asyncio
async def test_get_user_not_found(client):
    """Test getting non-existent user."""
    response = await client.get("/users/999")
    assert response.status_code == 404


@pytest.mark.asyncio
async def test_delete_user(client):
    """Test deleting a user."""
    create_response = await client.post(
        "/users",
        json={
            "name": "Test User",
            "username": "testuser",
            "email": "test@example.com",
            "password": "testpass123"
        }
    )
    user_id = create_response.json()["id"]
    
    response = await client.delete(f"/users/{user_id}")
    assert response.status_code == 200
    
    # Verify user is deleted
    get_response = await client.get(f"/users/{user_id}")
    assert get_response.status_code == 404
