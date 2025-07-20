import sys
import os

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from main import app
from fastapi.testclient import TestClient

client = TestClient(app)

def test_task_health():
    response = client.get("/health")
    assert response.status_code == 200

def test_create_task_invalid():
    response = client.post("/tasks", json={})
    assert response.status_code == 422
