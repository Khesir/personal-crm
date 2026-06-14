import 'tool_definition.dart';

/// Name of the no-op tool used to probe whether a model that reports the
/// `"tools"` capability via Ollama's `/api/show` actually emits structured
/// `tool_calls`, rather than describing a call as plain text (see issue 014).
const kToolCallProbeName = '__capability_probe__';

/// The probe tool definition sent as the only available tool on the probe
/// request.
const kToolCallProbeTool = ToolDefinition(
  name: kToolCallProbeName,
  description: 'Call this function to confirm tool-calling support. Takes no arguments.',
  parameters: {'type': 'object', 'properties': {}},
);

/// The probe request's user message, instructing the model to call
/// [kToolCallProbeTool] rather than reply with text.
const kToolCallProbePrompt = 'Call the $kToolCallProbeName function now. Do not respond with text.';

/// Caps the probe request's generated tokens via Ollama's `num_predict`
/// option, so a model that doesn't support tool-calling and rambles text
/// instead doesn't slow down `refresh()`.
const kToolCallProbeMaxTokens = 32;
