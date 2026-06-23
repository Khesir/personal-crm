import asyncio
import os
import signal
import threading
import argparse
import uuid
import json

import uvicorn
from fastapi import FastAPI
from fastapi.responses import StreamingResponse
from pydantic import BaseModel

from config import build_provider, load_config, save_config
from providers.base import ChatMessage
from brain import read_brain_files
from db import (
    init_db,
    create_session,
    load_history,
    save_messages,
    list_sessions,
    delete_session,
    session_exists,
)
import tools.web
import tools.memory
import tools.filesystem
import tools.research
from tools.memory import set_brain_path
from tools.filesystem import set_local_path
from tools.research import set_provider as set_research_provider
from tools.registry import get_schemas, dispatch
from vector import init_vector, store_response, retrieve_context
from tools.ollama_discovery import list_ollama_models

app = FastAPI()

PID_DIR = os.path.join(os.environ.get("APPDATA", os.path.expanduser("~")), "Avyn", "agent")
PID_FILE = os.path.join(PID_DIR, "agent.pid")

_active_provider = None

_shutdown_event = threading.Event()


@app.on_event("startup")
async def on_startup():
    global _active_provider
    os.makedirs(PID_DIR, exist_ok=True)
    with open(PID_FILE, "w") as f:
        f.write(str(os.getpid()))
    _active_provider = build_provider(load_config())
    set_research_provider(_active_provider)
    tools.research.set_loop(asyncio.get_event_loop())
    init_db()
    init_vector()
    print(f"[Avyn Agent] Started. PID={os.getpid()} port listening.")


@app.on_event("shutdown")
def on_shutdown():
    if os.path.exists(PID_FILE):
        os.remove(PID_FILE)
    print("[Avyn Agent] Shutdown complete.")


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/config")
def get_config():
    config = load_config()
    return {"provider": config["provider"], "model": config["model"]}


@app.get("/models")
async def get_models():
    config = load_config()
    provider = config.get("provider", "ollama")
    if provider == "ollama":
        models = await list_ollama_models()
        return {"provider": "ollama", "models": models}
    return {
        "provider": provider,
        "models": [{"name": config.get("model", ""), "parameter_size": ""}],
    }


@app.post("/config")
def post_config(body: dict):
    global _active_provider
    save_config(body)
    _active_provider = build_provider(body)
    set_research_provider(_active_provider)
    return {"status": "ok"}


class ChatRequest(BaseModel):
    session_id: str | None = None
    message: str
    local_path: str | None = None
    brain_path: str | None = None
    brain_files: list[str] = []


@app.post("/chat")
async def chat(request: ChatRequest):
    if request.session_id:
        session_id = request.session_id
        history = load_history(session_id)
    else:
        session_id = create_session(title=request.message)
        history = []

    async def event_stream():
        full_text = []
        try:
            set_brain_path(request.brain_path)
            set_local_path(request.local_path)
            brain_content = read_brain_files(request.brain_path, request.brain_files)
            loop_messages = [ChatMessage(role=m["role"], content=m["content"]) for m in history]
            context = retrieve_context(request.message)
            if context:
                loop_messages.append(ChatMessage(role="system", content=f"Relevant past context:\n{context}"))
            if brain_content:
                loop_messages.append(ChatMessage(role="system", content=brain_content))
            loop_messages.append(ChatMessage(role="user", content=request.message))

            while True:
                pending_tool_calls = []
                async for chunk in _active_provider.stream_chat(loop_messages, tools=get_schemas()):
                    if chunk.type == "text" and chunk.text:
                        full_text.append(chunk.text)
                        yield f"data: {json.dumps({'type': 'text', 'text': chunk.text})}\n\n"
                    elif chunk.type == "tool_call":
                        pending_tool_calls.append(chunk)
                        yield f"data: {json.dumps({'type': 'tool_call', 'tool': chunk.tool_name, 'input': chunk.tool_input})}\n\n"
                    elif chunk.type == "done":
                        if not pending_tool_calls:
                            save_messages(session_id, request.message, "".join(full_text))
                            store_response(session_id, "".join(full_text))
                            yield f"data: {json.dumps({'type': 'done', 'session_id': session_id, 'summary': '', 'success': True})}\n\n"
                            return

                if not pending_tool_calls:
                    break

                loop_messages.append(ChatMessage(role="assistant", content=""))

                for tc in pending_tool_calls:
                    result = dispatch(tc.tool_name, tc.tool_input or {})
                    yield f"data: {json.dumps({'type': 'tool_result', 'tool': tc.tool_name, 'output': result})}\n\n"
                    loop_messages.append(ChatMessage(role="tool", content=result, tool_call_id=tc.tool_call_id))
        except Exception as e:
            yield f"data: {json.dumps({'type': 'error', 'message': str(e)})}\n\n"

    return StreamingResponse(event_stream(), media_type="text/event-stream")


@app.get("/sessions")
def get_sessions():
    return list_sessions()


@app.delete("/sessions/{session_id}")
def remove_session(session_id: str):
    from fastapi import HTTPException
    deleted = delete_session(session_id)
    if not deleted:
        raise HTTPException(status_code=404, detail="Session not found")
    return {"status": "deleted"}


@app.get("/sessions/{session_id}/messages")
def get_session_messages(session_id: str):
    from fastapi import HTTPException
    if not session_exists(session_id):
        raise HTTPException(status_code=404, detail="Session not found")
    return {"messages": load_history(session_id)}


@app.post("/shutdown")
def shutdown():
    threading.Thread(target=_trigger_shutdown, daemon=True).start()
    return {"status": "shutting_down"}


def _trigger_shutdown():
    _shutdown_event.set()
    os.kill(os.getpid(), signal.SIGTERM)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=int(os.environ.get("AVYN_AGENT_PORT", 8765)))
    args = parser.parse_args()

    uvicorn.run(app, host="0.0.0.0", port=args.port)
