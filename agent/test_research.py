import asyncio
import json
from unittest.mock import MagicMock, AsyncMock, patch

import pytest
import pytest_asyncio

import tools.research as research_module
from tools.research import _trigger_research, _manage_research, _run_pipeline, set_provider
from providers.base import StreamChunk


def _make_provider(decompose_json: str, synthesis_text: str):
    call_count = 0

    async def stream_chat(messages, tools=None):
        nonlocal call_count
        call_count += 1
        text = decompose_json if call_count == 1 else synthesis_text
        yield StreamChunk(type="text", text=text)
        yield StreamChunk(type="done")

    provider = MagicMock()
    provider.stream_chat = stream_chat
    return provider


@pytest.fixture(autouse=True)
def clean_jobs():
    research_module._jobs.clear()
    yield
    research_module._jobs.clear()


def test_trigger_research_returns_id():
    provider = _make_provider('["What is X?", "How does X work?"]', "Report text.")
    set_provider(provider)

    with patch("tools.research.asyncio.ensure_future") as mock_ef:
        result = _trigger_research({"query": "Tell me about X"})

    data = json.loads(result)
    assert "research_id" in data
    rid = data["research_id"]
    assert len(rid) == 36
    mock_ef.assert_called_once()


def test_manage_research_running():
    provider = _make_provider('["sub 1"]', "report")
    set_provider(provider)

    with patch("tools.research.asyncio.ensure_future"):
        result = _trigger_research({"query": "test query"})

    rid = json.loads(result)["research_id"]
    status = json.loads(_manage_research({"research_id": rid, "action": "status"}))
    assert status["status"] == "running"


@pytest.mark.asyncio
async def test_manage_research_done():
    provider = _make_provider('["sub-question 1", "sub-question 2"]', "Synthesized report content.")
    set_provider(provider)

    research_id = "test-done-id"
    research_module._jobs[research_id] = {"status": "running", "result": None, "error": None}

    with patch("tools.research._web_search", return_value='[{"title": "T", "url": "http://example.com", "snippet": "S"}]'), \
         patch("tools.research._web_fetch", return_value="Fetched page content."), \
         patch("tools.research.os.makedirs"), \
         patch("builtins.open", MagicMock()), \
         patch("tools.research.json.dump"):
        await _run_pipeline(research_id, "What is the capital of France?")

    assert research_module._jobs[research_id]["status"] == "done"
    result_data = json.loads(_manage_research({"research_id": research_id, "action": "read"}))
    assert result_data["status"] == "done"
    assert "result" in result_data
    assert result_data["result"]["report"] == "Synthesized report content."


@pytest.mark.asyncio
async def test_graceful_searxng_failure():
    provider = _make_provider('["sub 1", "sub 2"]', "Report despite failures.")
    set_provider(provider)

    research_id = "test-degraded-id"
    research_module._jobs[research_id] = {"status": "running", "result": None, "error": None}

    with patch("tools.research._web_search", return_value="web_search error: Connection refused"), \
         patch("tools.research._web_fetch", return_value="fetch content"), \
         patch("tools.research.os.makedirs"), \
         patch("builtins.open", MagicMock()), \
         patch("tools.research.json.dump"):
        await _run_pipeline(research_id, "query that fails search")

    assert research_module._jobs[research_id]["status"] == "done"
    report = research_module._jobs[research_id]["result"]["report"]
    assert len(report) > 0
