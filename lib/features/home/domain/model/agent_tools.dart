import 'tool_definition.dart';

/// The fixed v1 set of file tools available to agent-mode conversations.
const kReadFileTool = ToolDefinition(
  name: 'read_file',
  description: 'Read the contents of a file.',
  parameters: {
    'type': 'object',
    'properties': {
      'path': {
        'type': 'string',
        'description': 'Path to the file, relative to the working project root or absolute.',
      },
    },
    'required': ['path'],
  },
);

const kListDirTool = ToolDefinition(
  name: 'list_dir',
  description: 'List the files and folders in a directory.',
  parameters: {
    'type': 'object',
    'properties': {
      'path': {
        'type': 'string',
        'description': 'Path to the directory, relative to the working project root or absolute.',
      },
    },
    'required': ['path'],
  },
);

const kGrepTool = ToolDefinition(
  name: 'grep',
  description: 'Search file contents recursively for a pattern.',
  parameters: {
    'type': 'object',
    'properties': {
      'pattern': {
        'type': 'string',
        'description': 'Text or regular expression to search for.',
      },
      'path': {
        'type': 'string',
        'description': 'Directory to search under. Defaults to the working project root.',
      },
    },
    'required': ['pattern'],
  },
);

const kWriteFileTool = ToolDefinition(
  name: 'write_file',
  description: 'Create a new file with the given content. Fails if the file already exists.',
  parameters: {
    'type': 'object',
    'properties': {
      'path': {
        'type': 'string',
        'description': 'Path to the new file, relative to the working project root or absolute.',
      },
      'content': {
        'type': 'string',
        'description': 'Full content of the new file.',
      },
    },
    'required': ['path', 'content'],
  },
);

const kEditFileTool = ToolDefinition(
  name: 'edit_file',
  description: 'Replace an exact, unique block of text in an existing file with new text.',
  parameters: {
    'type': 'object',
    'properties': {
      'path': {
        'type': 'string',
        'description': 'Path to the existing file, relative to the working project root or absolute.',
      },
      'old_text': {
        'type': 'string',
        'description': 'Exact text to find. Must match exactly once in the file.',
      },
      'new_text': {
        'type': 'string',
        'description': 'Text to replace old_text with.',
      },
    },
    'required': ['path', 'old_text', 'new_text'],
  },
);

const kWebSearchTool = ToolDefinition(
  name: 'web_search',
  description: 'Search the web for up-to-date information.',
  parameters: {
    'type': 'object',
    'properties': {
      'query': {
        'type': 'string',
        'description': 'The search query.',
      },
      'count': {
        'type': 'integer',
        'description': 'Maximum number of results to return. Defaults to 5.',
      },
    },
    'required': ['query'],
  },
);

/// Fetches a URL and returns its readable text content. Not part of
/// [kAgentTools] v1 — added to the Deep Research tool set in issue 022.
const kFetchPageTool = ToolDefinition(
  name: 'fetch_page',
  description: 'Fetch a web page and return its readable text content.',
  parameters: {
    'type': 'object',
    'properties': {
      'url': {
        'type': 'string',
        'description': 'The URL of the page to fetch.',
      },
    },
    'required': ['url'],
  },
);

/// Runs a single shell command line inside the conversation's working
/// project directory. Not part of [kAgentTools] v1 — gating it behind a
/// per-conversation "Shell access" toggle is a separate concern (issue 017).
const kRunCommandTool = ToolDefinition(
  name: 'run_command',
  description: 'Run a shell command in the working project directory.',
  parameters: {
    'type': 'object',
    'properties': {
      'command': {
        'type': 'string',
        'description': 'The shell command line to run.',
      },
    },
    'required': ['command'],
  },
);

/// All v1 agent tools, in the order they should be presented to a model.
const kAgentTools = <ToolDefinition>[
  kReadFileTool,
  kListDirTool,
  kGrepTool,
  kWriteFileTool,
  kEditFileTool,
  kWebSearchTool,
];

/// Tool set offered to Deep Research conversations (issue 022) — web search
/// and page fetching only, reusing [AgentLoopRunner]'s tool-call loop with no
/// file/shell tools.
const kDeepResearchTools = <ToolDefinition>[
  kWebSearchTool,
  kFetchPageTool,
];
