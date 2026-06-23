import json
import os
import subprocess
import pytest
import tools.filesystem as fs_module
from tools.filesystem import set_local_path
from tools.registry import dispatch
import tools.filesystem


@pytest.fixture
def project_dir(tmp_path):
    set_local_path(str(tmp_path))
    yield tmp_path
    set_local_path(None)


def test_shell_runs_command(project_dir):
    result = dispatch("shell", {"command": "echo hello"})
    data = json.loads(result)
    assert "hello" in data["stdout"]


def test_shell_no_project():
    set_local_path(None)
    result = dispatch("shell", {"command": "echo hi"})
    assert "no working project" in result


def test_shell_timeout(project_dir, monkeypatch):
    from unittest.mock import patch
    with patch("tools.filesystem.subprocess.run", side_effect=subprocess.TimeoutExpired("cmd", 30)):
        result = dispatch("shell", {"command": "sleep 60"})
    assert "timed out" in result


def test_file_read_success(project_dir):
    (project_dir / "test.txt").write_text("hello world", encoding="utf-8")
    result = dispatch("file_read", {"path": "test.txt"})
    assert result == "hello world"


def test_file_read_traversal(project_dir):
    result = dispatch("file_read", {"path": "../../../etc/passwd"})
    assert "traversal rejected" in result


def test_file_write_success(project_dir):
    result = dispatch("file_write", {"path": "out.txt", "content": "hello"})
    assert json.loads(result)["success"] is True
    assert (project_dir / "out.txt").read_text(encoding="utf-8") == "hello"


def test_file_write_traversal(project_dir):
    result = dispatch("file_write", {"path": "../../evil.txt", "content": "x"})
    assert "traversal rejected" in result


def test_file_read_no_project():
    set_local_path(None)
    result = dispatch("file_read", {"path": "x"})
    assert "no working project" in result or "traversal rejected" in result
