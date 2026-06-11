import '../model/chat_conversation.dart';

abstract class ChatConversationsRepository {
  Future<List<ChatConversation>> getConversations();

  Future<void> saveConversations(List<ChatConversation> conversations);
}
