import 'package:crm/core/state/state.dart';
import '../../presentation/state/chat_state.dart';
import '../model/chat_conversation.dart';
import '../model/chat_message.dart';
import '../repository/chat_conversations_repository.dart';
import '../repository/ollama_repository.dart';

class ChatController extends StreamState<ChatStateData> {
  final OllamaRepository ollamaRepository;
  final ChatConversationsRepository conversationsRepository;

  ChatController(this.ollamaRepository, this.conversationsRepository)
      : super(const ChatStateData());

  Future<void> load() async {
    final conversations = await conversationsRepository.getConversations();
    List<String> models = const [];
    try {
      models = await ollamaRepository.listModels();
    } catch (_) {
      models = const [];
    }
    emit(state.copyWith(
      conversations: conversations,
      availableModels: models,
      activeModel: models.isNotEmpty ? models.first : state.activeModel,
    ));
  }

  void newConversation() {
    final now = DateTime.now();
    final conversation = ChatConversation(
      id: now.microsecondsSinceEpoch.toString(),
      title: 'New chat',
      createdAt: now,
      updatedAt: now,
      messages: const [],
    );
    emit(state.copyWith(
      conversations: [conversation, ...state.conversations],
      activeConversationId: conversation.id,
    ));
    _persist();
  }

  void selectConversation(String id) {
    emit(state.copyWith(activeConversationId: id));
  }

  void selectModel(String model) {
    emit(state.copyWith(activeModel: model));
  }

  Future<void> sendMessage(String content) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return;
    final model = state.activeModel;
    if (model == null) return;

    var conversation = state.activeConversation;
    if (conversation == null) {
      final now = DateTime.now();
      conversation = ChatConversation(
        id: now.microsecondsSinceEpoch.toString(),
        title: _titleFromMessage(trimmed),
        createdAt: now,
        updatedAt: now,
        messages: const [],
      );
      emit(state.copyWith(
        conversations: [conversation, ...state.conversations],
        activeConversationId: conversation.id,
      ));
    }

    final userMessage = ChatMessage(role: ChatRole.user, content: trimmed);
    final assistantMessage = const ChatMessage(
      role: ChatRole.assistant,
      content: '',
      streaming: true,
    );

    final isFirstMessage = conversation.messages.isEmpty;
    final updatedMessages = [...conversation.messages, userMessage, assistantMessage];
    _updateConversation(
      conversation.id,
      messages: updatedMessages,
      title: isFirstMessage ? _titleFromMessage(trimmed) : null,
    );

    emit(state.copyWith(isStreaming: true));

    final history = [...conversation.messages, userMessage];

    try {
      await for (final chunk in ollamaRepository.streamChat(model: model, messages: history)) {
        _appendToLastMessage(conversation.id, chunk);
      }
    } finally {
      _finishStreaming(conversation.id);
      emit(state.copyWith(isStreaming: false));
      _persist();
    }
  }

  void _appendToLastMessage(String conversationId, String chunk) {
    final conversation = _findConversation(conversationId);
    if (conversation == null) return;
    final messages = [...conversation.messages];
    final last = messages.last;
    messages[messages.length - 1] = last.copyWith(content: last.content + chunk);
    _updateConversation(conversationId, messages: messages);
  }

  void _finishStreaming(String conversationId) {
    final conversation = _findConversation(conversationId);
    if (conversation == null) return;
    final messages = [...conversation.messages];
    if (messages.isEmpty) return;
    final last = messages.last;
    if (last.role == ChatRole.assistant) {
      messages[messages.length - 1] = last.copyWith(streaming: false);
    }
    _updateConversation(conversationId, messages: messages);
  }

  ChatConversation? _findConversation(String id) {
    for (final conversation in state.conversations) {
      if (conversation.id == id) return conversation;
    }
    return null;
  }

  void _updateConversation(
    String id, {
    List<ChatMessage>? messages,
    String? title,
  }) {
    final now = DateTime.now();
    final conversations = [
      for (final conversation in state.conversations)
        if (conversation.id == id)
          conversation.copyWith(
            messages: messages,
            title: title,
            updatedAt: now,
          )
        else
          conversation,
    ];
    emit(state.copyWith(conversations: conversations));
  }

  Future<void> _persist() async {
    await conversationsRepository.saveConversations(state.conversations);
  }

  String _titleFromMessage(String content) {
    final singleLine = content.replaceAll('\n', ' ').trim();
    if (singleLine.length <= 40) return singleLine;
    return '${singleLine.substring(0, 40)}...';
  }
}
