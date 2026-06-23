import json
from typing import AsyncIterator

import httpx

from providers.base import STREAM_TIMEOUT, ChatMessage, LLMProvider, StreamChunk, ToolSchema


class OllamaProvider(LLMProvider):
    def __init__(self, model: str, host: str = "localhost", port: int = 11434):
        self._model = model
        self._url = f"http://{host}:{port}/api/chat"

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

        async with httpx.AsyncClient(timeout=STREAM_TIMEOUT) as client:
            async with client.stream("POST", self._url, json=body) as response:
                async for line in response.aiter_lines():
                    if not line:
                        continue
                    data = json.loads(line)
                    msg = data.get("message", {})

                    if msg.get("content"):
                        yield StreamChunk(type="text", text=msg["content"])

                    for tc in msg.get("tool_calls") or []:
                        fn = tc.get("function", {})
                        yield StreamChunk(
                            type="tool_call",
                            tool_name=fn.get("name"),
                            tool_input=fn.get("arguments"),
                            tool_call_id=str(tc.get("id", "")),
                        )

                    if data.get("done"):
                        yield StreamChunk(type="done")
                        return
