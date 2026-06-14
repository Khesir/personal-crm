import 'tool_call.dart';

enum ChatRole {
  user,
  assistant,
  system,
  tool;

  String get value => switch (this) {
        ChatRole.user => 'user',
        ChatRole.assistant => 'assistant',
        ChatRole.system => 'system',
        ChatRole.tool => 'tool',
      };

  static ChatRole fromValue(String value) => switch (value) {
        'assistant' => ChatRole.assistant,
        'system' => ChatRole.system,
        'tool' => ChatRole.tool,
        _ => ChatRole.user,
      };
}

class ChatMessage {
  final ChatRole role;
  final String content;
  final bool streaming;
  final List<ToolCall> toolCalls;
  final String? toolCallId;
  final String? toolName;

  const ChatMessage({
    required this.role,
    required this.content,
    this.streaming = false,
    this.toolCalls = const [],
    this.toolCallId,
    this.toolName,
  });

  ChatMessage copyWith({
    ChatRole? role,
    String? content,
    bool? streaming,
    List<ToolCall>? toolCalls,
    String? toolCallId,
    String? toolName,
  }) {
    return ChatMessage(
      role: role ?? this.role,
      content: content ?? this.content,
      streaming: streaming ?? this.streaming,
      toolCalls: toolCalls ?? this.toolCalls,
      toolCallId: toolCallId ?? this.toolCallId,
      toolName: toolName ?? this.toolName,
    );
  }

  Map<String, dynamic> toJson() => {
        'role': role.value,
        'content': content,
        'streaming': streaming,
        'toolCalls': toolCalls.map((t) => t.toJson()).toList(),
        'toolCallId': toolCallId,
        'toolName': toolName,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        role: ChatRole.fromValue(json['role'] as String),
        content: json['content'] as String? ?? '',
        streaming: json['streaming'] as bool? ?? false,
        toolCalls: (json['toolCalls'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>()
            .map(ToolCall.fromJson)
            .toList(),
        toolCallId: json['toolCallId'] as String?,
        toolName: json['toolName'] as String?,
      );
}
