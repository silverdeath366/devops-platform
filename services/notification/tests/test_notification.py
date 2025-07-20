from fastapi.testclient import TestClient
from services.notification.main import app

client = TestClient(app)

def test_notification_health():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}

def test_send_notification_invalid_payload():
    response = client.post("/notify", json={})
    assert response.status_code == 422

def test_send_notification_success():
    payload = {
        "user_id": 123,
        "message": "Hello from test"
    }
    response = client.post("/notify", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "sent"
    assert data["user_id"] == payload["user_id"]
