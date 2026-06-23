import json
from unittest.mock import AsyncMock, MagicMock, patch

import pytest
from starlette.testclient import TestClient

from main import app
from providers.base import ChatMessage, ToolSchema
from providers.ollama import OllamaProvider
from providers.openai_provider import OpenAIProvider
from providers.anthropic_provider import AnthropicProvider

client = TestClient(app, raise_server_exceptions=False)


def _make_aiter(lines: list[str]):
    async def _gen():
        for line in lines:
            yield line
    return _gen()


def _mock_stream_response(lines: list[str]):
    mock_response = AsyncMock()
    mock_response.__aenter__ = AsyncMock(return_value=mock_response)
    mock_response.__aexit__ = AsyncMock(return_value=False)
    mock_response.aiter_lines = MagicMock(return_value=_make_aiter(lines))
    return mock_response


def _mock_client(stream_response):
    mock_client = AsyncMock()
    mock_client.__aenter__ = AsyncMock(return_value=mock_client)
    mock_client.__aexit__ = AsyncMock(return_value=False)
    mock_client.stream = MagicMock(return_value=stream_response)
    return mock_client


@pytest.mark.asyncio
async def test_ollama_stream_text():
    lines = [
        json.dumps({"message": {"content": "Hello"}, "done": False}),
        json.dumps({"message": {"content": " world"}, "done": True}),
    ]
    with patch("providers.ollama.httpx.AsyncClient", return_value=_mock_client(_mock_stream_response(lines))):
        provider = OllamaProvider(model="llama3")
        chunks = []
        async for chunk in provider.stream_chat([ChatMessage(role="user", content="Hi")]):
            chunks.append(chunk)

    text_chunks = [c for c in chunks if c.type == "text"]
    done_chunks = [c for c in chunks if c.type == "done"]
    assert len(text_chunks) == 2
    assert text_chunks[0].text == "Hello"
    assert text_chunks[1].text == " world"
    assert len(done_chunks) == 1


@pytest.mark.asyncio
async def test_ollama_stream_tool_call():
    lines = [
        json.dumps({
            "message": {
                "content": "",
                "tool_calls": [{"id": "tc1", "function": {"name": "get_time", "arguments": {}}}],
            },
            "done": True,
        }),
    ]
    with patch("providers.ollama.httpx.AsyncClient", return_value=_mock_client(_mock_stream_response(lines))):
        provider = OllamaProvider(model="llama3")
        chunks = []
        async for chunk in provider.stream_chat([ChatMessage(role="user", content="What time?")]):
            chunks.append(chunk)

    tool_chunks = [c for c in chunks if c.type == "tool_call"]
    assert len(tool_chunks) == 1
    assert tool_chunks[0].tool_name == "get_time"
    assert tool_chunks[0].tool_call_id == "tc1"


@pytest.mark.asyncio
async def test_openai_stream_text():
    lines = [
        "data: " + json.dumps({"choices": [{"delta": {"content": "Hi"}, "finish_reason": None}]}),
        "data: " + json.dumps({"choices": [{"delta": {}, "finish_reason": None}]}),
        "data: [DONE]",
    ]
    with patch("providers.openai_provider.httpx.AsyncClient", return_value=_mock_client(_mock_stream_response(lines))):
        provider = OpenAIProvider(model="gpt-4o", api_key="test-key")
        chunks = []
        async for chunk in provider.stream_chat([ChatMessage(role="user", content="Hello")]):
            chunks.append(chunk)

    text_chunks = [c for c in chunks if c.type == "text"]
    done_chunks = [c for c in chunks if c.type == "done"]
    assert len(text_chunks) == 1
    assert text_chunks[0].text == "Hi"
    assert len(done_chunks) == 1


@pytest.mark.asyncio
async def test_anthropic_stream_text():
    lines = [
        "data: " + json.dumps({"type": "content_block_delta", "delta": {"type": "text_delta", "text": "Hello"}}),
        "data: " + json.dumps({"type": "message_stop"}),
    ]
    with patch("providers.anthropic_provider.httpx.AsyncClient", return_value=_mock_client(_mock_stream_response(lines))):
        provider = AnthropicProvider(model="claude-3-5-sonnet-20241022", api_key="test-key")
        chunks = []
        async for chunk in provider.stream_chat([ChatMessage(role="user", content="Hello")]):
            chunks.append(chunk)

    text_chunks = [c for c in chunks if c.type == "text"]
    done_chunks = [c for c in chunks if c.type == "done"]
    assert len(text_chunks) == 1
    assert text_chunks[0].text == "Hello"
    assert len(done_chunks) == 1


def test_config_switch():
    response = client.post("/config", json={"provider": "openai", "model": "gpt-4o", "api_key": "key123"})
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}

    response = client.get("/config")
    assert response.status_code == 200
    data = response.json()
    assert data["provider"] == "openai"
    assert data["model"] == "gpt-4o"
    assert "api_key" not in data
