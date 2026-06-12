enum ServiceCategory {
  localLlm,
  apiLlm,
  services;

  String get value => switch (this) {
        ServiceCategory.localLlm => 'localLlm',
        ServiceCategory.apiLlm => 'apiLlm',
        ServiceCategory.services => 'services',
      };

  static ServiceCategory fromValue(String value) => switch (value) {
        'apiLlm' => ServiceCategory.apiLlm,
        'services' => ServiceCategory.services,
        _ => ServiceCategory.localLlm,
      };
}

enum ServiceType {
  ollama,
  customLocal,
  claudeAnthropic,
  customApi,
  n8n,
  customUrl,
  groq,
  gemini,
  openRouter,
  openai,
  deepSeek,
  mistral,
  nvidia,
  openCodeZen;

  String get value => switch (this) {
        ServiceType.ollama => 'ollama',
        ServiceType.customLocal => 'customLocal',
        ServiceType.claudeAnthropic => 'claudeAnthropic',
        ServiceType.customApi => 'customApi',
        ServiceType.n8n => 'n8n',
        ServiceType.customUrl => 'customUrl',
        ServiceType.groq => 'groq',
        ServiceType.gemini => 'gemini',
        ServiceType.openRouter => 'open_router',
        ServiceType.openai => 'openai',
        ServiceType.deepSeek => 'deep_seek',
        ServiceType.mistral => 'mistral',
        ServiceType.nvidia => 'nvidia',
        ServiceType.openCodeZen => 'open_code_zen',
      };

  static ServiceType fromValue(String value) => switch (value) {
        'customLocal' => ServiceType.customLocal,
        'claudeAnthropic' => ServiceType.claudeAnthropic,
        'customApi' => ServiceType.customApi,
        'n8n' => ServiceType.n8n,
        'customUrl' => ServiceType.customUrl,
        'groq' => ServiceType.groq,
        'gemini' => ServiceType.gemini,
        'open_router' => ServiceType.openRouter,
        'openai' => ServiceType.openai,
        'deep_seek' => ServiceType.deepSeek,
        'mistral' => ServiceType.mistral,
        'nvidia' => ServiceType.nvidia,
        'open_code_zen' => ServiceType.openCodeZen,
        _ => ServiceType.ollama,
      };
}

class ServiceCard {
  final String id;
  final ServiceCategory category;
  final ServiceType type;
  final String name;
  final Map<String, String> fields;
  final bool enabled;
  final bool isDefault;
  final List<String> disabledModels;

  const ServiceCard({
    required this.id,
    required this.category,
    required this.type,
    required this.name,
    required this.fields,
    this.enabled = true,
    this.isDefault = false,
    this.disabledModels = const [],
  });

  ServiceCard copyWith({
    String? name,
    Map<String, String>? fields,
    bool? enabled,
    bool? isDefault,
    List<String>? disabledModels,
  }) {
    return ServiceCard(
      id: id,
      category: category,
      type: type,
      name: name ?? this.name,
      fields: fields ?? this.fields,
      enabled: enabled ?? this.enabled,
      isDefault: isDefault ?? this.isDefault,
      disabledModels: disabledModels ?? this.disabledModels,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category.value,
        'type': type.value,
        'name': name,
        'fields': fields,
        'enabled': enabled,
        'isDefault': isDefault,
        'disabledModels': disabledModels,
      };

  factory ServiceCard.fromJson(Map<String, dynamic> json) => ServiceCard(
        id: json['id'] as String,
        category: ServiceCategory.fromValue(json['category'] as String),
        type: ServiceType.fromValue(json['type'] as String),
        name: json['name'] as String,
        fields: (json['fields'] as Map<dynamic, dynamic>? ?? const {})
            .map((key, value) => MapEntry(key as String, value as String)),
        enabled: json['enabled'] as bool? ?? true,
        isDefault: json['isDefault'] as bool? ?? false,
        disabledModels: (json['disabledModels'] as List<dynamic>? ?? const [])
            .cast<String>(),
      );
}
