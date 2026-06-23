import os
import subprocess
import json
from .registry import register
from providers.base import ToolSchema

_local_path: str | None = None
_MAX_FILE_CHARS = 50_000


def set_local_path(path: str | None) -> None:
    global _local_path
    _local_path = path


def _resolve_path(rel: str) -> str | None:
    if _local_path is None:
        return None
    base = os.path.realpath(_local_path)
    target = os.path.realpath(os.path.join(base, rel))
    if not target.startswith(base + os.sep) and target != base:
        return None
    return target


def _shell(input: dict) -> str:
    if _local_path is None:
        return "shell error: no working project set"
    command = input.get("command", "")
    try:
        result = subprocess.run(
            command,
            shell=True,
            cwd=_local_path,
            capture_output=True,
            text=True,
            timeout=30,
        )
        return json.dumps({"stdout": result.stdout, "stderr": result.stderr, "exit_code": result.returncode})
    except subprocess.TimeoutExpired:
        return json.dumps({"stdout": "", "stderr": "Command timed out after 30s", "exit_code": -1})
    except Exception as e:
        return f"shell error: {e}"


def _file_read(input: dict) -> str:
    path = _resolve_path(input.get("path", ""))
    if path is None:
        return "file_read error: no working project set or path traversal rejected"
    try:
        with open(path, "r", encoding="utf-8", errors="replace") as f:
            content = f.read()
        if len(content) > _MAX_FILE_CHARS:
            return content[:_MAX_FILE_CHARS] + f"\n[truncated — {len(content)} chars total]"
        return content
    except FileNotFoundError:
        return f"file_read error: file not found: {input.get('path')}"
    except Exception as e:
        return f"file_read error: {e}"


def _file_write(input: dict) -> str:
    path = _resolve_path(input.get("path", ""))
    if path is None:
        return "file_write error: no working project set or path traversal rejected"
    try:
        os.makedirs(os.path.dirname(path), exist_ok=True) if os.path.dirname(path) else None
        with open(path, "w", encoding="utf-8") as f:
            f.write(input.get("content", ""))
        return json.dumps({"success": True})
    except Exception as e:
        return f"file_write error: {e}"


register(ToolSchema(
    name="shell",
    description="Run a shell command in the working project directory. Returns stdout, stderr, exit_code.",
    parameters={"type": "object", "properties": {"command": {"type": "string"}}, "required": ["command"]},
), _shell)

register(ToolSchema(
    name="file_read",
    description="Read a file relative to the working project directory. Rejects path traversal.",
    parameters={"type": "object", "properties": {"path": {"type": "string"}}, "required": ["path"]},
), _file_read)

register(ToolSchema(
    name="file_write",
    description="Write content to a file relative to the working project directory. Creates parent dirs.",
    parameters={"type": "object", "properties": {"path": {"type": "string"}, "content": {"type": "string"}}, "required": ["path", "content"]},
), _file_write)
