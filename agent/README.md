# Avyn Agent Server

FastAPI server powering Avyn's agentic loop. Runs locally, embedded in the Flutter app.

## Setup

```powershell
cd agent
pip install -r requirements.txt
```

## Run

```powershell
python main.py
python main.py --port 9000
$env:AVYN_AGENT_PORT = "9000"; python main.py
```

Default port: **8765**

## Endpoints

- `GET /health` — returns `{"status": "ok"}`
- `POST /shutdown` — shuts the server down cleanly
- `POST /chat` — SSE streaming agentic loop
- `GET /sessions` — list past sessions
- `DELETE /sessions/{id}` — delete a session
- `GET /config` / `POST /config` — read/update provider config

## Tests

```powershell
python -m pytest -v
```

## Building the .exe

Requires Python + PyInstaller on the build machine. Output is `dist/avyn-agent.exe` (~200–400 MB).

```powershell
.\build.ps1          # build
.\build.ps1 -Clean   # wipe dist/ first, then build
```

The `.exe` is self-contained — no Python required on the target machine. Copy it next to the Flutter executable before shipping.

### Manual acceptance gate

On a clean Windows machine **without** Python installed:

1. Copy `dist/avyn-agent.exe` to the machine
2. Run it: `.\avyn-agent.exe`
3. Verify `GET http://localhost:8765/health` returns `{"status":"ok"}`
4. Verify `%APPDATA%\Avyn\agent\agent.pid` exists
5. Send `POST /chat` with a configured LLM and confirm a streamed response

## Configuration

Stored at `%APPDATA%\Avyn\agent\config.json`. Managed via `POST /config`.

| Field | Default | Description |
|-------|---------|-------------|
| `provider` | `ollama` | `ollama` \| `openai` \| `anthropic` |
| `model` | `llama3` | Model name for the chosen provider |
| `api_key` | — | Required for OpenAI / Anthropic |
| `searxng_url` | `http://localhost:8080` | SearXNG endpoint for web_search |
| `port` | `8765` | Listening port |
