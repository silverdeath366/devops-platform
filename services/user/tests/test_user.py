import os
import pytest
from fastapi.testclient import TestClient
from services.user.main import app, metadata, engine
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

client = TestClient(app)

# Reset the DB before each test run
@pytest.fixture(autouse=True, scope="function")
def reset_db():
    metadata.drop_all(engine)
    metadata.create_all(engine)
    yield
    metadata.drop_all(engine)

def test_user_health():
    response = client.get("/health")
    assert response.status_code == 200

def test_get_nonexistent_user():
    response = client.get("/users/999")
    assert response.status_code == 404

def test_create_user_success():
    response = client.post("/users", json={
        "name": "Bob",
        "username": "bob1",
        "email": "bob1@example.com",
        "password": "bobpass"
    })
    assert response.status_code == 200
    data = response.json()
    assert data["name"] == "Bob"
    assert data["email"] == "bob1@example.com"
    assert "id" in data

def test_get_existing_user():
    create_resp = client.post("/users", json={
        "name": "Charlie",
        "username": "charlie1",
        "email": "charlie1@example.com",
        "password": "charliepass"
    })
    assert create_resp.status_code == 200
    user_id = create_resp.json()["id"]

    fetch_resp = client.get(f"/users/{user_id}")
    assert fetch_resp.status_code == 200
    data = fetch_resp.json()
    assert data["username"] == "charlie1"
    assert data["email"] == "charlie1@example.com"
