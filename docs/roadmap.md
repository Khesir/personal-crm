# Avyn — Roadmap

## Agent surfaces

### v1 — Flutter dock pane
The primary agent surface. Flutter talks to the local Python agent server at `localhost:PORT`, renders streamed events in the dock's Agent pane.

### v2 — Discord adapter
Thin adapter that forwards Discord messages to the same Python agent loop and posts responses back to the channel. No loop logic lives in the adapter.

### v2 — Telegram adapter
Same pattern as Discord — thin adapter, same loop, different transport.
