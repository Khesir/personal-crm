import json
import uuid
from unittest.mock import MagicMock, patch

import chromadb
import pytest
from starlette.testclient import TestClient

import vector
from providers.base import StreamChunk


@pytest.fixture(autouse=True)
def reset_vector():
    vector._client = None
    vector._collection = None
    yield
    vector._client = None
    vector._collection = None


def _make_in_memory_collection():
    client = chromadb.EphemeralClient()
    return client.get_or_create_collection(f"test_{uuid.uuid4().hex}")


def test_store_and_retrieve():
    col = _make_in_memory_collection()
    vector._collection = col

    vector.store_response("sess-1", "Python is a great programming language for data science.")
    result = vector.retrieve_context("Tell me about Python programming")

    assert "Python" in result


def test_retrieve_empty():
    col = _make_in_memory_collection()
    vector._collection = col

    result = vector.retrieve_context("anything")
    assert result == ""


def test_context_injected_in_chat():
    import main as main_module
    from main import app

    client = TestClient(app)

    async def fake_stream(*args, **kwargs):
        captured_messages.extend(args[0] if args else kwargs.get("messages", []))
        yield StreamChunk(type="text", text="answer")
        yield StreamChunk(type="done")

    captured_messages = []
    mock_provider = MagicMock()
    mock_provider.stream_chat = fake_stream

    with patch.object(main_module, "_active_provider", mock_provider), \
         patch("main.create_session", return_value="s1"), \
         patch("main.load_history", return_value=[]), \
         patch("main.save_messages"), \
         patch("main.store_response"), \
         patch("main.retrieve_context", return_value="Past: user asked about Python"):
        response = client.post("/chat", json={"message": "what did I ask before?"})

    assert response.status_code == 200
    system_contents = [m.content for m in captured_messages if m.role == "system"]
    assert any("Relevant past context" in c for c in system_contents)
    assert any("Past: user asked about Python" in c for c in system_contents)
