import sys
import os

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from main import app
from fastapi.testclient import TestClient

client = TestClient(app)

def test_notification_health():
    response = client.get("/health")
    assert response.status_code == 200

def test_send_notification_invalid_payload():
    response = client.post("/notify", json={})
    assert response.status_code == 422
