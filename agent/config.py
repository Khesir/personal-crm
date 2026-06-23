import json
import os

from providers.base import LLMProvider
from providers.ollama import OllamaProvider
from providers.openai_provider import OpenAIProvider
from providers.anthropic_provider import AnthropicProvider

CONFIG_PATH = os.path.join(
    os.environ.get("APPDATA", os.path.expanduser("~")), "Avyn", "agent", "config.json"
)

DEFAULT_CONFIG: dict = {"provider": "ollama", "model": "llama3", "api_key": ""}


def load_config() -> dict:
    if os.path.exists(CONFIG_PATH):
        with open(CONFIG_PATH, "r") as f:
            return json.load(f)
    return dict(DEFAULT_CONFIG)


def save_config(config: dict) -> None:
    os.makedirs(os.path.dirname(CONFIG_PATH), exist_ok=True)
    with open(CONFIG_PATH, "w") as f:
        json.dump(config, f)


def build_provider(config: dict) -> LLMProvider:
    provider = config.get("provider", "ollama")
    model = config.get("model", "llama3")
    api_key = config.get("api_key", "")

    if provider == "ollama":
        return OllamaProvider(model=model)
    if provider == "openai":
        return OpenAIProvider(model=model, api_key=api_key)
    if provider == "anthropic":
        return AnthropicProvider(model=model, api_key=api_key)
    raise ValueError(f"Unknown provider: {provider}")
