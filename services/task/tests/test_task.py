from fastapi.testclient import TestClient
from services.task.main import app

client = TestClient(app)

def test_task_health():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}

def test_create_task_invalid():
    response = client.post("/tasks", json={})
    assert response.status_code == 422

def test_create_task_success():
    payload = {
        "title": "Test Task",
        "description": "Make sure POST works",
        "user_id": 1
    }
    response = client.post("/tasks", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["title"] == payload["title"]
    assert data["user_id"] == payload["user_id"]
    assert data["completed"] is False
    assert "id" in data

def test_get_nonexistent_task():
    response = client.get("/tasks/9999")
    assert response.status_code == 404

def test_task_delete():
    payload = {
        "title": "Temporary",
        "description": "To be deleted",
        "user_id": 999
    }
    create = client.post("/tasks", json=payload)
    task_id = create.json()["id"]

    delete = client.delete(f"/tasks/{task_id}")
    assert delete.status_code == 200
    assert delete.json() == {"message": "Task deleted"}
