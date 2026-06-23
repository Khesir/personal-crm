import ast
import asyncio
import json
import os
import uuid

from .registry import register
from .web import _web_search, _web_fetch
from providers.base import ChatMessage, LLMProvider, ToolSchema

_RESEARCH_DIR = os.path.join(os.environ.get("APPDATA", os.path.expanduser("~")), "Avyn", "agent", "research")

_jobs: dict[str, dict] = {}
_provider: LLMProvider | None = None
_loop: asyncio.AbstractEventLoop | None = None


def set_provider(provider: LLMProvider) -> None:
    global _provider
    _provider = provider


def set_loop(loop: asyncio.AbstractEventLoop) -> None:
    global _loop
    _loop = loop


async def _llm_text(messages: list[ChatMessage]) -> str:
    parts = []
    async for chunk in _provider.stream_chat(messages):
        if chunk.type == "text" and chunk.text:
            parts.append(chunk.text)
    return "".join(parts)


async def _run_pipeline(research_id: str, query: str) -> None:
    job = _jobs[research_id]
    try:
        decompose_prompt = (
            f"Break this research query into 3 to 5 focused sub-questions. "
            f"Return ONLY a JSON array of strings, no explanation.\n\nQuery: {query}"
        )
        raw = await _llm_text([ChatMessage(role="user", content=decompose_prompt)])
        raw = raw.strip()
        start = raw.find("[")
        end = raw.rfind("]") + 1
        sub_questions: list[str] = json.loads(raw[start:end]) if start != -1 else [query]

        fetched_blocks: list[str] = []
        for sub_q in sub_questions[:5]:
            search_result = _web_search({"query": sub_q, "max_results": 3})
            if search_result.startswith("web_search error:"):
                fetched_blocks.append(f"Sub-question: {sub_q}\nSearch failed: {search_result}")
                continue

            try:
                results = ast.literal_eval(search_result)
            except Exception:
                fetched_blocks.append(f"Sub-question: {sub_q}\nCould not parse results.")
                continue

            if not results:
                fetched_blocks.append(f"Sub-question: {sub_q}\nNo results found.")
                continue

            top_url = results[0].get("url", "")
            if not top_url:
                fetched_blocks.append(f"Sub-question: {sub_q}\nNo URL in top result.")
                continue

            content = _web_fetch({"url": top_url})
            fetched_blocks.append(f"Sub-question: {sub_q}\nSource: {top_url}\nContent:\n{content}")

        combined = "\n\n---\n\n".join(fetched_blocks)
        synthesize_prompt = (
            f"You are a research assistant. Synthesize the following web research into a structured report "
            f"with a summary, key findings, and citations.\n\n"
            f"Original query: {query}\n\n"
            f"Research material:\n{combined}"
        )
        report_text = await _llm_text([ChatMessage(role="user", content=synthesize_prompt)])

        report = {
            "research_id": research_id,
            "query": query,
            "sub_questions": sub_questions,
            "report": report_text,
        }

        os.makedirs(_RESEARCH_DIR, exist_ok=True)
        report_path = os.path.join(_RESEARCH_DIR, f"{research_id}.json")
        with open(report_path, "w", encoding="utf-8") as f:
            json.dump(report, f, indent=2)

        job["status"] = "done"
        job["result"] = report
    except Exception as e:
        job["status"] = "error"
        job["error"] = str(e)


def _trigger_research(input: dict) -> str:
    query = input.get("query", "")
    research_id = str(uuid.uuid4())
    _jobs[research_id] = {"status": "running", "result": None, "error": None}
    loop = _loop
    if loop is not None:
        asyncio.run_coroutine_threadsafe(_run_pipeline(research_id, query), loop)
    else:
        asyncio.ensure_future(_run_pipeline(research_id, query))
    return json.dumps({"research_id": research_id})


def _manage_research(input: dict) -> str:
    research_id = input.get("research_id", "")
    action = input.get("action", "status")

    if research_id not in _jobs:
        report_path = os.path.join(_RESEARCH_DIR, f"{research_id}.json")
        if os.path.exists(report_path):
            with open(report_path, "r", encoding="utf-8") as f:
                return json.dumps({"status": "done", "result": json.load(f)})
        return json.dumps({"status": "error", "error": "Unknown research_id"})

    job = _jobs[research_id]

    if action == "status":
        return json.dumps({"status": job["status"]})

    if action == "read":
        if job["status"] == "done":
            return json.dumps({"status": "done", "result": job["result"]})
        if job["status"] == "error":
            return json.dumps({"status": "error", "error": job["error"]})
        return json.dumps({"status": "running"})

    return json.dumps({"error": f"Unknown action: {action}"})


register(ToolSchema(
    name="trigger_research",
    description="Start a deep research pipeline for a query. Returns a research_id immediately. Use manage_research to check status or read the report.",
    parameters={"type": "object", "properties": {"query": {"type": "string"}}, "required": ["query"]},
), _trigger_research)

register(ToolSchema(
    name="manage_research",
    description="Check status or read the result of a background research pipeline.",
    parameters={
        "type": "object",
        "properties": {
            "research_id": {"type": "string"},
            "action": {"type": "string", "enum": ["status", "read"]},
        },
        "required": ["research_id", "action"],
    },
), _manage_research)
