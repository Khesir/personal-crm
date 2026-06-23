import json
from typing import AsyncIterator

import httpx

from providers.base import STREAM_TIMEOUT, ChatMessage, LLMProvider, StreamChunk, ToolSchema

_URL = "https://api.anthropic.com/v1/messages"
_ANTHROPIC_VERSION = "2023-06-01"


class AnthropicProvider(LLMProvider):
    def __init__(self, model: str, api_key: str):
        self._model = model
        self._api_key = api_key

    async def stream_chat(
        self,
        messages: list[ChatMessage],
        tools: list[ToolSchema] | None = None,
    ) -> AsyncIterator[StreamChunk]:
        system_parts = [m.content for m in messages if m.role == "system"]
        non_system = [m for m in messages if m.role != "system"]

        body: dict = {
            "model": self._model,
            "max_tokens": 4096,
            "stream": True,
            "messages": [{"role": m.role, "content": m.content} for m in non_system],
        }
        if system_parts:
            body["system"] = "\n".join(system_parts)
        if tools:
            body["tools"] = [
                {
                    "name": t.name,
                    "description": t.description,
                    "input_schema": t.parameters,
                }
                for t in tools
            ]

        headers = {
            "x-api-key": self._api_key,
            "anthropic-version": _ANTHROPIC_VERSION,
            "content-type": "application/json",
        }

        current_tool: dict | None = None

        async with httpx.AsyncClient(timeout=STREAM_TIMEOUT) as client:
            async with client.stream("POST", _URL, json=body, headers=headers) as response:
                async for line in response.aiter_lines():
                    if not line.startswith("data: "):
                        continue
                    data = json.loads(line[6:])
                    event_type = data.get("type")

                    if event_type == "content_block_start":
                        block = data.get("content_block", {})
                        if block.get("type") == "tool_use":
                            current_tool = {
                                "id": block.get("id", ""),
                                "name": block.get("name", ""),
                                "input": "",
                            }

                    elif event_type == "content_block_delta":
                        delta = data.get("delta", {})
                        if delta.get("type") == "text_delta":
                            yield StreamChunk(type="text", text=delta.get("text", ""))
                        elif delta.get("type") == "input_json_delta" and current_tool is not None:
                            current_tool["input"] += delta.get("partial_json", "")

                    elif event_type == "content_block_stop":
                        if current_tool is not None:
                            yield StreamChunk(
                                type="tool_call",
                                tool_name=current_tool["name"],
                                tool_input=json.loads(current_tool["input"] or "{}"),
                                tool_call_id=current_tool["id"],
                            )
                            current_tool = None

                    elif event_type == "message_stop":
                        yield StreamChunk(type="done")
                        return
