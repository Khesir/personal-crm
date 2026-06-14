/// Describes a tool the model may call, including a JSON Schema for its
/// arguments.
class ToolDefinition {
  final String name;
  final String description;
  final Map<String, dynamic> parameters;

  const ToolDefinition({
    required this.name,
    required this.description,
    this.parameters = const {},
  });
}
