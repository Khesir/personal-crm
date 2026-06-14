import 'chat_message.dart';

class ChatConversation {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ChatMessage> messages;
  final String? workingProjectId;
  final List<String> trustedReferenceProjectIds;
  final bool shellAccessEnabled;
  final bool isDeepResearch;

  const ChatConversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.messages = const [],
    this.workingProjectId,
    this.trustedReferenceProjectIds = const [],
    this.shellAccessEnabled = false,
    this.isDeepResearch = false,
  });

  ChatConversation copyWith({
    String? title,
    DateTime? updatedAt,
    List<ChatMessage>? messages,
    String? workingProjectId,
    List<String>? trustedReferenceProjectIds,
  }) {
    return ChatConversation(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
      workingProjectId: workingProjectId ?? this.workingProjectId,
      trustedReferenceProjectIds:
          trustedReferenceProjectIds ?? this.trustedReferenceProjectIds,
      shellAccessEnabled: shellAccessEnabled,
      isDeepResearch: isDeepResearch,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'messages': messages.map((m) => m.toJson()).toList(),
        'workingProjectId': workingProjectId,
        'trustedReferenceProjectIds': trustedReferenceProjectIds,
        'shellAccessEnabled': shellAccessEnabled,
        'isDeepResearch': isDeepResearch,
      };

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      messages: (json['messages'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>()
          .map(ChatMessage.fromJson)
          .toList(),
      workingProjectId: json['workingProjectId'] as String?,
      trustedReferenceProjectIds:
          (json['trustedReferenceProjectIds'] as List<dynamic>? ?? [])
              .cast<String>(),
      shellAccessEnabled: json['shellAccessEnabled'] as bool? ?? false,
      isDeepResearch: json['isDeepResearch'] as bool? ?? false,
    );
  }
}
