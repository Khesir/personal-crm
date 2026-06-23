import json
import os
import tempfile
import time
from unittest.mock import MagicMock, patch

import pytest
from starlette.testclient import TestClient

from db import (
    create_session,
    delete_session,
    init_db,
    list_sessions,
    load_history,
    save_messages,
    session_exists,
)
import main as main_module
from main import app
from providers.base import StreamChunk


@pytest.fixture
def db_file():
    with tempfile.NamedTemporaryFile(suffix=".db", delete=False) as f:
        path = f.name
    init_db(db_path=path)
    yield path
    try:
        os.unlink(path)
    except PermissionError:
        pass


def test_create_session(db_file):
    session_id = create_session("Hello world", db_path=db_file)
    sessions = list_sessions(db_path=db_file)
    assert len(sessions) == 1
    assert sessions[0]["id"] == session_id
    assert sessions[0]["title"] == "Hello world"


def test_load_history_empty(db_file):
    session_id = create_session("Hi", db_path=db_file)
    history = load_history(session_id, db_path=db_file)
    assert history == []


def test_save_and_load_messages(db_file):
    session_id = create_session("Hello", db_path=db_file)
    save_messages(session_id, "Hello", "Hi there", db_path=db_file)
    history = load_history(session_id, db_path=db_file)
    assert len(history) == 2
    assert history[0] == {"role": "user", "content": "Hello"}
    assert history[1] == {"role": "assistant", "content": "Hi there"}


def test_list_sessions_ordered(db_file):
    id1 = create_session("First", db_path=db_file)
    time.sleep(0.01)
    id2 = create_session("Second", db_path=db_file)
    time.sleep(0.01)
    save_messages(id1, "First", "Response", db_path=db_file)
    sessions = list_sessions(db_path=db_file)
    assert sessions[0]["id"] == id1


def test_delete_session(db_file):
    session_id = create_session("To delete", db_path=db_file)
    result = delete_session(session_id, db_path=db_file)
    assert result is True
    sessions = list_sessions(db_path=db_file)
    assert all(s["id"] != session_id for s in sessions)


def test_session_exists_true_after_create(db_file):
    session_id = create_session("Hello", db_path=db_file)
    assert session_exists(session_id, db_path=db_file) is True


def test_session_exists_false_for_unknown_id(db_file):
    assert session_exists("nonexistent-id", db_path=db_file) is False


def test_title_truncated(db_file):
    long_message = "A" * 80
    session_id = create_session(long_message, db_path=db_file)
    sessions = list_sessions(db_path=db_file)
    assert len(sessions[0]["title"]) == 60


def parse_sse(body: str) -> list[dict]:
    events = []
    for block in body.split("\n\n"):
        for line in block.splitlines():
            if line.startswith("data: "):
                events.append(json.loads(line[6:]))
    return events


async def fake_stream_text(*args, **kwargs):
    yield StreamChunk(type="text", text="hello")
    yield StreamChunk(type="done")


def test_chat_creates_session(db_file):
    mock_provider = MagicMock()
    mock_provider.stream_chat = fake_stream_text

    def patched_create_session(title):
        return create_session(title, db_path=db_file)

    def patched_load_history(session_id):
        return load_history(session_id, db_path=db_file)

    def patched_save_messages(session_id, user_content, assistant_content):
        return save_messages(session_id, user_content, assistant_content, db_path=db_file)

    client = TestClient(app)
    with (
        patch.object(main_module, "_active_provider", mock_provider),
        patch.object(main_module, "create_session", patched_create_session),
        patch.object(main_module, "load_history", patched_load_history),
        patch.object(main_module, "save_messages", patched_save_messages),
    ):
        response = client.post("/chat", json={"message": "hello"})

    events = parse_sse(response.text)
    done = next(e for e in events if e["type"] == "done")
    assert done["session_id"] is not None


# TODO: test history resume
