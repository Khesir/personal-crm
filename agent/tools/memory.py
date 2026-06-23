import os
import json
from .registry import register
from providers.base import ToolSchema

_brain_path: str | None = None
_VALID_FILES = {"identity", "soul", "memory"}


def set_brain_path(path: str | None) -> None:
    global _brain_path
    _brain_path = path


def _memory_read(input: dict) -> str:
    files = input.get("files", [])
    result = {}
    for name in files:
        if name not in _VALID_FILES:
            result[name] = None
            continue
        if _brain_path is None:
            result[name] = None
            continue
        fpath = os.path.join(_brain_path, f"{name}.md")
        if os.path.exists(fpath):
            with open(fpath, "r", encoding="utf-8") as f:
                result[name] = f.read()
        else:
            result[name] = None
    return json.dumps(result)


def _memory_write(input: dict) -> str:
    if _brain_path is None:
        return "memory_write error: no brain_path set"
    file_name = input.get("file", "")
    if file_name not in _VALID_FILES:
        return f"memory_write error: invalid file name '{file_name}'"
    content = input.get("content", "")
    fpath = os.path.join(_brain_path, f"{file_name}.md")
    try:
        os.makedirs(os.path.dirname(fpath), exist_ok=True) if os.path.dirname(fpath) else None
        with open(fpath, "w", encoding="utf-8") as f:
            f.write(content)
        return json.dumps({"success": True})
    except Exception as e:
        return f"memory_write error: {e}"


register(ToolSchema(
    name="memory_read",
    description="Read Brain files (identity, soul, memory). Returns {filename: content} map. Missing files return null.",
    parameters={"type": "object", "properties": {"files": {"type": "array", "items": {"type": "string"}}}, "required": ["files"]},
), _memory_read)

register(ToolSchema(
    name="memory_write",
    description="Overwrite a Brain file (identity, soul, or memory) with new content.",
    parameters={"type": "object", "properties": {"file": {"type": "string"}, "content": {"type": "string"}}, "required": ["file", "content"]},
), _memory_write)
