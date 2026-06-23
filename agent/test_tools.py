import pytest
from unittest.mock import patch, MagicMock
import httpx

from tools.registry import dispatch
import tools.web


def test_web_search_success():
    with patch("tools.web.httpx.get") as mock_get:
        mock_get.return_value.json.return_value = {"results": [{"title": "T", "url": "U", "content": "S"}]}
        mock_get.return_value.raise_for_status = lambda: None
        result = dispatch("web_search", {"query": "test"})
        assert "title" in result


def test_web_search_error():
    with patch("tools.web.httpx.get") as mock_get:
        mock_get.side_effect = httpx.ConnectError("refused")
        result = dispatch("web_search", {"query": "test"})
        assert result.startswith("web_search error:")


def test_web_fetch_success():
    with patch("tools.web.httpx.get") as mock_get:
        mock_get.return_value.text = "<html><body>Hello</body></html>"
        mock_get.return_value.raise_for_status = lambda: None
        result = dispatch("web_fetch", {"url": "http://example.com"})
        assert "Hello" in result


def test_web_fetch_error():
    with patch("tools.web.httpx.get") as mock_get:
        mock_get.side_effect = httpx.ConnectError("refused")
        result = dispatch("web_fetch", {"url": "http://example.com"})
        assert result.startswith("web_fetch error:")


def test_tool_dispatch_unknown():
    result = dispatch("unknown_tool", {})
    assert result == "Unknown tool: unknown_tool"
