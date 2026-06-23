import json
from typing import AsyncIterator

import httpx

from providers.base import STREAM_TIMEOUT, ChatMessage, LLMProvider, StreamChunk, ToolSchema

_URL = "https://api.openai.com/v1/chat/completions"


class OpenAIProvider(LLMProvider):
    def __init__(self, model: str, api_key: str):
        self._model = model
        self._api_key = api_key

    async def stream_chat(
        self,
        messages: list[ChatMessage],
        tools: list[ToolSchema] | None = None,
    ) -> AsyncIterator[StreamChunk]:
        body = {
            "model": self._model,
            "messages": [{"role": m.role, "content": m.content} for m in messages],
            "stream": True,
        }
        if tools:
            body["tools"] = [
                {
                    "type": "function",
                    "function": {
                        "name": t.name,
                        "description": t.description,
                        "parameters": t.parameters,
                    },
                }
                for t in tools
            ]

        headers = {"Authorization": f"Bearer {self._api_key}"}
        pending_tool_calls: dict[int, dict] = {}

        async with httpx.AsyncClient(timeout=STREAM_TIMEOUT) as client:
            async with client.stream("POST", _URL, json=body, headers=headers) as response:
                async for line in response.aiter_lines():
                    if not line.startswith("data: "):
                        continue
                    payload = line[6:]
                    if payload.strip() == "[DONE]":
                        yield StreamChunk(type="done")
                        return
                    data = json.loads(payload)
                    delta = data.get("choices", [{}])[0].get("delta", {})

                    if delta.get("content"):
                        yield StreamChunk(type="text", text=delta["content"])

                    for tc in delta.get("tool_calls") or []:
                        idx = tc["index"]
                        if idx not in pending_tool_calls:
                            pending_tool_calls[idx] = {
                                "id": tc.get("id", ""),
                                "name": tc.get("function", {}).get("name", ""),
                                "arguments": "",
                            }
                        pending_tool_calls[idx]["arguments"] += tc.get("function", {}).get("arguments", "")

                    finish = data.get("choices", [{}])[0].get("finish_reason")
                    if finish == "tool_calls":
                        for tc in pending_tool_calls.values():
                            yield StreamChunk(
                                type="tool_call",
                                tool_name=tc["name"],
                                tool_input=json.loads(tc["arguments"] or "{}"),
                                tool_call_id=tc["id"],
                            )
                        pending_tool_calls.clear()
