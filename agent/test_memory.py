import json
import os
import pytest
from tools.registry import dispatch
import tools.memory
from tools.memory import set_brain_path


@pytest.fixture(autouse=True)
def brain_dir(tmp_path):
    set_brain_path(str(tmp_path))
    yield tmp_path
    set_brain_path(None)


def test_memory_read_existing(brain_dir):
    (brain_dir / "identity.md").write_text("I am Avyn.", encoding="utf-8")
    result = json.loads(dispatch("memory_read", {"files": ["identity"]}))
    assert result["identity"] == "I am Avyn."


def test_memory_read_missing(brain_dir):
    result = json.loads(dispatch("memory_read", {"files": ["memory"]}))
    assert result["memory"] is None


def test_memory_read_null_path():
    set_brain_path(None)
    result = json.loads(dispatch("memory_read", {"files": ["identity"]}))
    assert result["identity"] is None


def test_memory_write_success(brain_dir):
    dispatch("memory_write", {"file": "soul", "content": "I value honesty."})
    assert (brain_dir / "soul.md").read_text(encoding="utf-8") == "I value honesty."


def test_memory_write_null_path():
    set_brain_path(None)
    result = dispatch("memory_write", {"file": "soul", "content": "x"})
    assert "error" in result


def test_memory_write_reflects_in_read(brain_dir):
    dispatch("memory_write", {"file": "soul", "content": "honesty above all"})
    result = json.loads(dispatch("memory_read", {"files": ["soul"]}))
    assert result["soul"] == "honesty above all"
