import sys
import os

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from main import app
from fastapi.testclient import TestClient

client = TestClient(app, base_url="http://testserver")

def test_auth_health():
    response = client.get("/health")
    assert response.status_code == 200

def test_login_invalid_payload():
    response = client.post("/login", json={})
    assert response.status_code == 422  
