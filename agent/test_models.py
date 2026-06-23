from unittest.mock import AsyncMock, MagicMock, patch

import httpx
import pytest
from starlette.testclient import TestClient

import main as main_module
from main import app
from tools.ollama_discovery import list_ollama_models

client = TestClient(app, raise_server_exceptions=False)


def _mock_get_response(json_body: dict):
    mock_response = MagicMock()
    mock_response.raise_for_status = MagicMock()
    mock_response.json = MagicMock(return_value=json_body)
    return mock_response


def _mock_client(get_response=None, get_side_effect=None):
    mock_client = AsyncMock()
    mock_client.__aenter__ = AsyncMock(return_value=mock_client)
    mock_client.__aexit__ = AsyncMock(return_value=False)
    if get_side_effect is not None:
        mock_client.get = AsyncMock(side_effect=get_side_effect)
    else:
        mock_client.get = AsyncMock(return_value=get_response)
    return mock_client


@pytest.mark.asyncio
async def test_list_ollama_models_parses_tags_response():
    body = {
        "models": [
            {"name": "llama3.2:latest", "details": {"parameter_size": "3.2B"}},
            {"name": "qwen2.5:3b", "details": {"parameter_size": "3.1B"}},
        ]
    }
    with patch(
        "tools.ollama_discovery.httpx.AsyncClient",
        return_value=_mock_client(get_response=_mock_get_response(body)),
    ):
        models = await list_ollama_models()

    assert models == [
        {"name": "llama3.2:latest", "parameter_size": "3.2B"},
        {"name": "qwen2.5:3b", "parameter_size": "3.1B"},
    ]


@pytest.mark.asyncio
async def test_list_ollama_models_returns_empty_on_connection_error():
    with patch(
        "tools.ollama_discovery.httpx.AsyncClient",
        return_value=_mock_client(get_side_effect=httpx.ConnectError("refused")),
    ):
        models = await list_ollama_models()

    assert models == []


def test_get_models_endpoint_ollama_provider():
    fixed_models = [{"name": "llama3.2", "parameter_size": "3.2B"}]
    with (
        patch.object(main_module, "load_config", return_value={"provider": "ollama", "model": "llama3.2"}),
        patch.object(main_module, "list_ollama_models", AsyncMock(return_value=fixed_models)),
    ):
        response = client.get("/models")

    assert response.status_code == 200
    assert response.json() == {"provider": "ollama", "models": fixed_models}


def test_get_models_endpoint_non_ollama_provider():
    discovery_mock = AsyncMock(return_value=[{"name": "should-not-be-called", "parameter_size": ""}])
    with (
        patch.object(
            main_module,
            "load_config",
            return_value={"provider": "anthropic", "model": "claude-3-5-sonnet-20241022"},
        ),
        patch.object(main_module, "list_ollama_models", discovery_mock),
    ):
        response = client.get("/models")

    assert response.status_code == 200
    assert response.json() == {
        "provider": "anthropic",
        "models": [{"name": "claude-3-5-sonnet-20241022", "parameter_size": ""}],
    }
    discovery_mock.assert_not_called()
