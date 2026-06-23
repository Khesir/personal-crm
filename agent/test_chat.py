import json
from unittest.mock import MagicMock, patch

from starlette.testclient import TestClient

import main as main_module
from main import app
from providers.base import StreamChunk

client = TestClient(app)


def parse_sse(body: str) -> list[dict]:
    events = []
    for block in body.split("\n\n"):
        for line in block.splitlines():
            if line.startswith("data: "):
                events.append(json.loads(line[6:]))
    return events


async def fake_stream_text(*args, **kwargs):
    yield StreamChunk(type="text", text="hello ")
    yield StreamChunk(type="text", text="world")
    yield StreamChunk(type="done")


async def fake_stream_error(*args, **kwargs):
    raise RuntimeError("LLM unavailable")
    yield


_DB_PATCHES = dict(
    create_session=MagicMock(return_value="test-session-id"),
    load_history=MagicMock(return_value=[]),
    save_messages=MagicMock(),
)


def test_chat_streams_text():
    mock_provider = MagicMock()
    mock_provider.stream_chat = fake_stream_text

    with patch.object(main_module, "_active_provider", mock_provider), \
         patch("main.create_session", return_value="test-session-id"), \
         patch("main.load_history", return_value=[]), \
         patch("main.save_messages"):
        response = client.post("/chat", json={"message": "hi"})

    events = parse_sse(response.text)
    assert events[0] == {"type": "text", "text": "hello "}
    assert events[1] == {"type": "text", "text": "world"}
    assert events[2]["type"] == "done"
    assert events[2]["success"] is True


def test_chat_generates_session_id():
    mock_provider = MagicMock()
    mock_provider.stream_chat = fake_stream_text

    with patch.object(main_module, "_active_provider", mock_provider), \
         patch("main.create_session", return_value="test-session-id"), \
         patch("main.load_history", return_value=[]), \
         patch("main.save_messages"):
        response = client.post("/chat", json={"message": "hi", "session_id": None})

    events = parse_sse(response.text)
    done = next(e for e in events if e["type"] == "done")
    assert done["session_id"] is not None


def test_chat_error():
    mock_provider = MagicMock()
    mock_provider.stream_chat = fake_stream_error

    with patch.object(main_module, "_active_provider", mock_provider), \
         patch("main.create_session", return_value="test-session-id"), \
         patch("main.load_history", return_value=[]), \
         patch("main.save_messages"):
        response = client.post("/chat", json={"message": "hi"})

    events = parse_sse(response.text)
    assert events[0]["type"] == "error"
    assert events[0]["message"] == "LLM unavailable"
