import 'service_card.dart';

/// Human-readable label for every [ServiceType], used by the type picker,
/// form dialog title, and service card list.
const Map<ServiceType, String> kServiceTypeLabels = {
  ServiceType.ollama: 'Ollama',
  ServiceType.customLocal: 'Custom Local (OpenAI-compatible)',
  ServiceType.claudeAnthropic: 'Claude (Anthropic)',
  ServiceType.customApi: 'Custom API',
  ServiceType.n8n: 'n8n',
  ServiceType.customUrl: 'Custom URL',
  ServiceType.groq: 'Groq',
  ServiceType.gemini: 'Gemini',
  ServiceType.openRouter: 'OpenRouter',
  ServiceType.openai: 'OpenAI',
  ServiceType.deepSeek: 'DeepSeek',
  ServiceType.mistral: 'Mistral',
  ServiceType.nvidia: 'NVIDIA',
  ServiceType.openCodeZen: 'OpenCode Zen',
};

/// Preset API base URL used to pre-fill the `baseUrl` field when a new card
/// of this [ServiceType] is created. Types not listed here have no preset —
/// the field starts empty and is user-supplied.
const Map<ServiceType, String> kServiceTypeDefaultBaseUrls = {
  ServiceType.groq: 'https://api.groq.com/openai/v1',
  ServiceType.gemini: 'https://generativelanguage.googleapis.com/v1beta/openai',
  ServiceType.openRouter: 'https://openrouter.ai/api/v1',
  ServiceType.openai: 'https://api.openai.com/v1',
  ServiceType.deepSeek: 'https://api.deepseek.com/v1',
  ServiceType.mistral: 'https://api.mistral.ai/v1',
  ServiceType.nvidia: 'https://integrate.api.nvidia.com/v1',
  ServiceType.openCodeZen: 'https://opencode.ai/zen/v1',
};
