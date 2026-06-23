import httpx

OLLAMA_TAGS_URL = "http://localhost:11434/api/tags"
_DISCOVERY_TIMEOUT = 2.0


async def list_ollama_models() -> list[dict]:
    try:
        async with httpx.AsyncClient(timeout=_DISCOVERY_TIMEOUT) as client:
            response = await client.get(OLLAMA_TAGS_URL)
            response.raise_for_status()
            data = response.json()
    except (httpx.HTTPError, ValueError):
        return []

    return [
        {
            "name": m.get("name", ""),
            "parameter_size": (m.get("details") or {}).get("parameter_size", ""),
        }
        for m in data.get("models", [])
    ]
