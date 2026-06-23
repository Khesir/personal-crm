import os
from datetime import datetime, timezone

import chromadb

_client = None
_collection = None

_DEFAULT_PATH = os.path.join(
    os.environ.get("APPDATA", os.path.expanduser("~")), "Avyn", "agent", "chroma"
)


def init_vector(db_path: str | None = None) -> None:
    global _client, _collection
    if _collection is not None:
        return
    path = db_path or _DEFAULT_PATH
    os.makedirs(path, exist_ok=True)
    _client = chromadb.PersistentClient(path=path)
    _collection = _client.get_or_create_collection("agent_memory")


def store_response(session_id: str, response_text: str) -> None:
    if _collection is None:
        return
    doc_id = f"{session_id}-{datetime.now(timezone.utc).isoformat()}"
    _collection.add(
        documents=[response_text],
        metadatas=[{"session_id": session_id, "created_at": datetime.now(timezone.utc).isoformat()}],
        ids=[doc_id],
    )


def retrieve_context(query: str, k: int = 3) -> str:
    if _collection is None or _collection.count() == 0:
        return ""
    results = _collection.query(query_texts=[query], n_results=min(k, _collection.count()))
    docs = results.get("documents", [[]])[0]
    if not docs:
        return ""
    return "\n---\n".join(docs)
