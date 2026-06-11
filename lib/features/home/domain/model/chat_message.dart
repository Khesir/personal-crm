enum ChatRole {
  user,
  assistant,
  system;

  String get value => switch (this) {
        ChatRole.user => 'user',
        ChatRole.assistant => 'assistant',
        ChatRole.system => 'system',
      };

  static ChatRole fromValue(String value) => switch (value) {
        'assistant' => ChatRole.assistant,
        'system' => ChatRole.system,
        _ => ChatRole.user,
      };
}

class ChatMessage {
  final ChatRole role;
  final String content;
  final bool streaming;

  const ChatMessage({
    required this.role,
    required this.content,
    this.streaming = false,
  });

  ChatMessage copyWith({
    ChatRole? role,
    String? content,
    bool? streaming,
  }) {
    return ChatMessage(
      role: role ?? this.role,
      content: content ?? this.content,
      streaming: streaming ?? this.streaming,
    );
  }

  Map<String, dynamic> toJson() => {
        'role': role.value,
        'content': content,
        'streaming': streaming,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        role: ChatRole.fromValue(json['role'] as String),
        content: json['content'] as String? ?? '',
        streaming: json['streaming'] as bool? ?? false,
      );
}
