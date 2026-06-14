/// Caps how many tool-call round-trips a single `sendMessage()` agent loop
/// may execute before stopping and appending a safety-limit notice message.
const kMaxAgentLoopSteps = 25;

/// Caps how many tool-call round-trips a single Deep Research turn may
/// execute before stopping and returning a best-effort partial answer.
/// Distinct from [kMaxAgentLoopSteps] — Deep Research turns only call
/// `web_search`/`fetch_page`, so a smaller ceiling is enough to cover several
/// angles of research without running away.
const kMaxDeepResearchSteps = 15;

/// Appended to the system prompt for Deep Research conversations (issue
/// 022), instructing the model to investigate from multiple angles before
/// answering and to cite its sources.
const kDeepResearchSystemPromptAddition =
    'You are in Deep Research mode. Before giving a final answer, use '
    'web_search and fetch_page to investigate the topic from several '
    'different angles and cross-check sources. When you give your final '
    'answer, cite the source URLs you used.';

/// How long a `run_command` tool call may run before it's killed and
/// resolves to an error result.
const kRunCommandTimeout = Duration(seconds: 60);
