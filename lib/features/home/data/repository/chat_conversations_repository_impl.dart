import '../../domain/model/chat_conversation.dart';
import '../../domain/repository/chat_conversations_repository.dart';
import '../datasource/chat_local_datasource.dart';

class ChatConversationsRepositoryImpl implements ChatConversationsRepository {
  final ChatLocalDatasource datasource;

  ChatConversationsRepositoryImpl(this.datasource);

  @override
  Future<List<ChatConversation>> getConversations() async {
    return datasource.read().map(ChatConversation.fromJson).toList();
  }

  @override
  Future<void> saveConversations(List<ChatConversation> conversations) async {
    await datasource.write(conversations.map((c) => c.toJson()).toList());
  }
}
