from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from typing import AsyncIterator

import httpx

# Generous timeout to tolerate local model cold-loads (Ollama can take well
# over httpx's 5s default to load a model into memory before it streams).
STREAM_TIMEOUT = httpx.Timeout(120.0, connect=10.0)


@dataclass
class ChatMessage:
    role: str
    content: str
    tool_call_id: str | None = None


@dataclass
class ToolSchema:
    name: str
    description: str
    parameters: dict


@dataclass
class StreamChunk:
    type: str
    text: str | None = None
    tool_name: str | None = None
    tool_input: dict | None = None
    tool_call_id: str | None = None


class LLMProvider(ABC):
    @abstractmethod
    async def stream_chat(
        self,
        messages: list[ChatMessage],
        tools: list[ToolSchema] | None = None,
    ) -> AsyncIterator[StreamChunk]: ...
