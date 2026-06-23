import httpx
from html.parser import HTMLParser
from .registry import register
from providers.base import ToolSchema

_MAX_FETCH_CHARS = 8000


class _HTMLStripper(HTMLParser):
    def __init__(self):
        super().__init__()
        self._parts: list[str] = []

    def handle_data(self, data):
        self._parts.append(data)

    def get_text(self) -> str:
        return ' '.join(self._parts)


def _strip_html(html: str) -> str:
    stripper = _HTMLStripper()
    stripper.feed(html)
    return stripper.get_text()


def _web_search(input: dict) -> str:
    query = input.get("query", "")
    max_results = input.get("max_results", 5)
    from config import load_config
    searxng_url = load_config().get("searxng_url", "http://localhost:8080")
    try:
        response = httpx.get(
            f"{searxng_url}/search",
            params={"q": query, "format": "json"},
            timeout=10.0,
        )
        response.raise_for_status()
        data = response.json()
        results = data.get("results", [])[:max_results]
        return str([{"title": r.get("title", ""), "url": r.get("url", ""), "snippet": r.get("content", "")} for r in results])
    except Exception as e:
        return f"web_search error: {e}"


def _web_fetch(input: dict) -> str:
    url = input.get("url", "")
    try:
        response = httpx.get(url, timeout=15.0, follow_redirects=True)
        response.raise_for_status()
        text = _strip_html(response.text)
        return text[:_MAX_FETCH_CHARS] + ("..." if len(text) > _MAX_FETCH_CHARS else "")
    except Exception as e:
        return f"web_fetch error: {e}"


register(ToolSchema(
    name="web_search",
    description="Search the web via SearXNG. Returns a list of {title, url, snippet} results.",
    parameters={"type": "object", "properties": {"query": {"type": "string"}, "max_results": {"type": "integer", "default": 5}}, "required": ["query"]},
), _web_search)

register(ToolSchema(
    name="web_fetch",
    description="Fetch a URL and return its text content (HTML stripped, truncated to 8000 chars).",
    parameters={"type": "object", "properties": {"url": {"type": "string"}}, "required": ["url"]},
), _web_fetch)
