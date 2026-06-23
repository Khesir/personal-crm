from typing import Callable
from providers.base import ToolSchema

_tools: dict[str, tuple[ToolSchema, Callable]] = {}


def register(schema: ToolSchema, handler: Callable) -> None:
    _tools[schema.name] = (schema, handler)


def get_schemas() -> list[ToolSchema]:
    return [schema for schema, _ in _tools.values()]


def dispatch(tool_name: str, tool_input: dict) -> str:
    if tool_name not in _tools:
        return f"Unknown tool: {tool_name}"
    _, handler = _tools[tool_name]
    try:
        return handler(tool_input)
    except Exception as e:
        return f"Tool error: {e}"
