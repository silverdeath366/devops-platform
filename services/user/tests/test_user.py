import sys
import os

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from main import app
from fastapi.testclient import TestClient

client = TestClient(app)

def test_user_health():
    response = client.get("/health")
    assert response.status_code == 200

def test_get_nonexistent_user():
    response = client.get("/users/999999")  
    assert response.status_code in [404, 422]
