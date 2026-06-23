import os
import tempfile
from unittest.mock import MagicMock, patch

from starlette.testclient import TestClient

import main as main_module
from brain import read_brain_files
from main import app
from providers.base import StreamChunk

client = TestClient(app, raise_server_exceptions=False)


def test_brain_reads_files():
    with tempfile.TemporaryDirectory() as tmpdir:
        with open(os.path.join(tmpdir, "identity.md"), "w") as f:
            f.write("I am Avyn.")
        with open(os.path.join(tmpdir, "soul.md"), "w") as f:
            f.write("I value honesty.")
        result = read_brain_files(tmpdir, ["identity", "soul"])
        assert "I am Avyn." in result
        assert "I value honesty." in result


def test_brain_skips_missing():
    with tempfile.TemporaryDirectory() as tmpdir:
        with open(os.path.join(tmpdir, "identity.md"), "w") as f:
            f.write("I am Avyn.")
        result = read_brain_files(tmpdir, ["identity", "memory"])
        assert "I am Avyn." in result


def test_brain_null_path():
    result = read_brain_files(None, ["identity"])
    assert result == ""


def test_brain_in_chat_endpoint():
    with tempfile.TemporaryDirectory() as tmpdir:
        with open(os.path.join(tmpdir, "identity.md"), "w") as f:
            f.write("I am Avyn.")

        captured_messages = []

        async def fake_stream(messages, tools=None):
            captured_messages.extend(messages)
            yield StreamChunk(type="text", text="hi")
            yield StreamChunk(type="done")

        mock_provider = MagicMock()
        mock_provider.stream_chat = fake_stream

        with patch.object(main_module, "_active_provider", mock_provider), \
             patch("main.create_session", return_value="test-session-id"), \
             patch("main.load_history", return_value=[]), \
             patch("main.save_messages"):
            response = client.post("/chat", json={
                "message": "hello",
                "brain_path": tmpdir,
                "brain_files": ["identity"]
            })

        assert any(m.role == "system" and "I am Avyn" in m.content for m in captured_messages)
