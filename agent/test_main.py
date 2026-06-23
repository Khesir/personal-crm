from starlette.testclient import TestClient
from main import app

client = TestClient(app, raise_server_exceptions=False)


def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_shutdown():
    response = client.post("/shutdown")
    assert response.status_code == 200
    assert response.json() == {"status": "shutting_down"}
