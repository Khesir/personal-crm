import 'package:crm/core/state/state.dart';
import 'package:crm/features/brain/api.dart';
import 'package:crm/features/settings/domain/model/service_card.dart';
import 'package:crm/features/settings/domain/repository/service_cards_repository.dart';
import '../../presentation/state/chat_state.dart';
import '../model/chat_conversation.dart';
import '../model/chat_message.dart';
import '../model/cookbook_entry.dart';
import '../repository/chat_conversations_repository.dart';
import '../repository/chat_model_repository.dart';

class ChatController extends StreamState<ChatStateData> {
  final ServiceCardsRepository serviceCardsRepository;
  final ChatModelRepository Function(ServiceCard card) repositoryFor;
  final ChatConversationsRepository conversationsRepository;
  final BrainRepository brainRepository;

  List<ServiceCard> _cookbookCards = [];

  ChatController(
    this.serviceCardsRepository,
    this.repositoryFor,
    this.conversationsRepository,
    this.brainRepository,
  ) : super(const ChatStateData());

  Future<void> load() async {
    final conversations = await conversationsRepository.getConversations();
    await refresh();
    emit(state.copyWith(conversations: conversations));
  }

  /// Re-aggregates the cookbook from the current Local LLM and API LLM
  /// service cards (enabled cards' reachable models, minus each card's
  /// `disabledModels`), without reloading conversations.
  ///
  /// Called by [load] at startup, and again whenever Home becomes visible
  /// (see `createChatController` in `home/di.dart`) so that changes made in
  /// Settings (toggling a model, or enabling/disabling/adding/removing a
  /// Local LLM or API LLM card) are reflected without restarting the app.
  Future<void> refresh() async {
    final cards = await serviceCardsRepository.getCards();
    _cookbookCards = cards
        .where((c) =>
            (c.category == ServiceCategory.localLlm ||
                c.category == ServiceCategory.apiLlm) &&
            c.enabled)
        .toList();

    final cookbook = <CookbookEntry>[];
    for (final card in _cookbookCards) {
      try {
        final models = await repositoryFor(card).listModels();
        for (final model in models) {
          if (!card.disabledModels.contains(model)) {
            cookbook.add(CookbookEntry(
              cardId: card.id,
              cardName: card.name,
              cardType: card.type,
              model: model,
            ));
          }
        }
      } catch (_) {
        // A failing card contributes zero entries.
      }
    }

    final previous = state.activeEntry;
    final keepPrevious = previous != null && cookbook.contains(previous);

    emit(state.copyWith(
      cookbook: cookbook,
      activeEntry: keepPrevious
          ? previous
          : (cookbook.isNotEmpty ? cookbook.first : null),
      clearActiveEntry: !keepPrevious && cookbook.isEmpty,
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

  void selectEntry(CookbookEntry entry) {
    emit(state.copyWith(activeEntry: entry));
  }

  Future<void> sendMessage(String content) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return;
    final entry = state.activeEntry;
    if (entry == null) return;

    ServiceCard? card;
    for (final c in _cookbookCards) {
      if (c.id == entry.cardId) {
        card = c;
        break;
      }
    }
    if (card == null) return;

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

    final systemPrompt = await brainRepository.buildSystemPrompt();
    final requestMessages = systemPrompt != null
        ? [ChatMessage(role: ChatRole.system, content: systemPrompt), ...history]
        : history;

    final repo = repositoryFor(card);

    try {
      await for (final chunk in repo.streamChat(model: entry.model, messages: requestMessages)) {
        _appendToLastMessage(conversation.id, chunk);
      }
    } catch (e) {
      _setErrorMessage(conversation.id, e);
    } finally {
      _finishStreaming(conversation.id);
      emit(state.copyWith(isStreaming: false));
      _persist();
    }
  }

  /// Replaces the content of the last (assistant) message with a short,
  /// user-facing error notice. Called when [sendMessage]'s `streamChat()`
  /// loop throws (e.g. the underlying repository's stream emits an error
  /// from a failed HTTP request) — surfaces the failure in the conversation
  /// instead of leaving the message stuck on "generating..." or letting the
  /// exception propagate out of `sendMessage()` unhandled.
  ///
  /// If [error] is a [ChatRequestException], its message (extracted from the
  /// provider's own error response, e.g. "Your credit balance is too low")
  /// is included so the user knows what actually went wrong.
  void _setErrorMessage(String conversationId, Object error) {
    final conversation = _findConversation(conversationId);
    if (conversation == null) return;
    final messages = [...conversation.messages];
    if (messages.isEmpty) return;
    final last = messages.last;
    if (last.role == ChatRole.assistant) {
      final detail = error is ChatRequestException ? ' (${error.message})' : '';
      messages[messages.length - 1] = last.copyWith(
        content: '⚠️ Something went wrong while generating a response.$detail Please try again.',
      );
    }
    _updateConversation(conversationId, messages: messages);
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
