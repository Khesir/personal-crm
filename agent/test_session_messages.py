import os
import tempfile
from unittest.mock import patch

import pytest
from starlette.testclient import TestClient

from db import create_session, init_db, load_history, save_messages, session_exists
import main as main_module
from main import app


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


def test_get_session_messages_returns_history(db_file):
    session_id = create_session("Hello", db_path=db_file)
    save_messages(session_id, "Hello", "Hi there", db_path=db_file)

    def patched_load_history(sid):
        return load_history(sid, db_path=db_file)

    def patched_session_exists(sid):
        return session_exists(sid, db_path=db_file)

    client = TestClient(app)
    with (
        patch.object(main_module, "load_history", patched_load_history),
        patch.object(main_module, "session_exists", patched_session_exists),
    ):
        response = client.get(f"/sessions/{session_id}/messages")

    assert response.status_code == 200
    body = response.json()
    assert body["messages"] == [
        {"role": "user", "content": "Hello"},
        {"role": "assistant", "content": "Hi there"},
    ]


def test_get_session_messages_404_for_unknown_session(db_file):
    def patched_session_exists(sid):
        return session_exists(sid, db_path=db_file)

    client = TestClient(app)
    with patch.object(main_module, "session_exists", patched_session_exists):
        response = client.get("/sessions/does-not-exist/messages")

    assert response.status_code == 404
