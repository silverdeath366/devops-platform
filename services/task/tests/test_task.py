"""Tests for task service."""

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


@pytest.mark.asyncio
async def test_metrics_endpoint(client):
    """Test metrics endpoint."""
    response = await client.get("/metrics")
    assert response.status_code == 200
    assert "task_requests_total" in response.text


@pytest.mark.asyncio
async def test_create_task(client):
    """Test creating a new task."""
    response = await client.post(
        "/tasks",
        json={
            "title": "Test Task",
            "description": "Test description",
            "user_id": 1
        }
    )
    assert response.status_code == 201
    data = response.json()
    assert data["title"] == "Test Task"
    assert data["completed"] is False


@pytest.mark.asyncio
async def test_list_tasks(client):
    """Test listing tasks."""
    await client.post(
        "/tasks",
        json={"title": "Task 1", "description": "Desc 1", "user_id": 1}
    )
    response = await client.get("/tasks")
    assert response.status_code == 200
    assert len(response.json()) == 1


@pytest.mark.asyncio
async def test_get_task_by_id(client):
    """Test getting task by ID."""
    create_response = await client.post(
        "/tasks",
        json={"title": "Test Task", "description": "Test", "user_id": 1}
    )
    task_id = create_response.json()["id"]
    
    response = await client.get(f"/tasks/{task_id}")
    assert response.status_code == 200


@pytest.mark.asyncio
async def test_update_task(client):
    """Test updating a task."""
    create_response = await client.post(
        "/tasks",
        json={"title": "Test Task", "description": "Test", "user_id": 1}
    )
    task_id = create_response.json()["id"]
    
    response = await client.patch(
        f"/tasks/{task_id}",
        json={"completed": True}
    )
    assert response.status_code == 200
    assert response.json()["completed"] is True


@pytest.mark.asyncio
async def test_delete_task(client):
    """Test deleting a task."""
    create_response = await client.post(
        "/tasks",
        json={"title": "Test Task", "description": "Test", "user_id": 1}
    )
    task_id = create_response.json()["id"]
    
    response = await client.delete(f"/tasks/{task_id}")
    assert response.status_code == 200
    
    # Verify task is deleted
    get_response = await client.get(f"/tasks/{task_id}")
    assert get_response.status_code == 404
