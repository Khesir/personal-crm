class AgentModelInfo {
  final String name;
  final String parameterSize;

  const AgentModelInfo({required this.name, required this.parameterSize});
}

class AgentModelsResult {
  final String provider;
  final List<AgentModelInfo> models;

  const AgentModelsResult({required this.provider, required this.models});
}
