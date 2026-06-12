import '../../domain/model/chat_conversation.dart';
import '../../domain/model/cookbook_entry.dart';

class ChatStateData {
  final List<ChatConversation> conversations;
  final String? activeConversationId;
  final List<CookbookEntry> cookbook;
  final CookbookEntry? activeEntry;
  final bool isStreaming;

  const ChatStateData({
    this.conversations = const [],
    this.activeConversationId,
    this.cookbook = const [],
    this.activeEntry,
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
    List<CookbookEntry>? cookbook,
    CookbookEntry? activeEntry,
    bool clearActiveEntry = false,
    bool? isStreaming,
  }) {
    return ChatStateData(
      conversations: conversations ?? this.conversations,
      activeConversationId: clearActiveConversationId
          ? null
          : (activeConversationId ?? this.activeConversationId),
      cookbook: cookbook ?? this.cookbook,
      activeEntry: clearActiveEntry ? null : (activeEntry ?? this.activeEntry),
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }
}
