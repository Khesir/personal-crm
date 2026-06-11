import '../../domain/model/chat_conversation.dart';

class ChatStateData {
  final List<ChatConversation> conversations;
  final String? activeConversationId;
  final List<String> availableModels;
  final String? activeModel;
  final bool isStreaming;

  const ChatStateData({
    this.conversations = const [],
    this.activeConversationId,
    this.availableModels = const [],
    this.activeModel,
    this.isStreaming = false,
  });

  ChatConversation? get activeConversation {
    if (activeConversationId == null) return null;
    for (final conversation in conversations) {
      if (conversation.id == activeConversationId) return conversation;
    }
    return null;
  }

  ChatStateData copyWith({
    List<ChatConversation>? conversations,
    String? activeConversationId,
    bool clearActiveConversationId = false,
    List<String>? availableModels,
    String? activeModel,
    bool? isStreaming,
  }) {
    return ChatStateData(
      conversations: conversations ?? this.conversations,
      activeConversationId: clearActiveConversationId
          ? null
          : (activeConversationId ?? this.activeConversationId),
      availableModels: availableModels ?? this.availableModels,
      activeModel: activeModel ?? this.activeModel,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }
}
