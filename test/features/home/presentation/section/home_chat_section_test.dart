import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crm/features/brain/api.dart';
import 'package:crm/features/home/domain/controller/chat_controller.dart';
import 'package:crm/features/home/domain/model/chat_conversation.dart';
import 'package:crm/features/home/domain/model/chat_message.dart';
import 'package:crm/features/home/domain/model/chat_stream_event.dart';
import 'package:crm/features/home/domain/repository/chat_conversations_repository.dart';
import 'package:crm/features/home/domain/repository/chat_model_repository.dart';
import 'package:crm/features/home/domain/model/tool_definition.dart';
import 'package:crm/features/home/presentation/section/home_chat_section.dart';
import 'package:crm/features/settings/domain/model/service_card.dart';
import 'package:crm/features/settings/domain/repository/service_cards_repository.dart';

class _FakeChatModelRepository implements ChatModelRepository {
  @override
  Future<List<String>> listModels() async => ['llama3.2'];

  @override
  Stream<ChatStreamEvent> streamChat({
    required String model,
    required List<ChatMessage> messages,
    List<ToolDefinition> tools = const [],
  }) {
    return const Stream.empty();
  }
}

class _FakeServiceCardsRepository implements ServiceCardsRepository {
  final List<ServiceCard> cards;

  _FakeServiceCardsRepository(this.cards);

  @override
  Future<List<ServiceCard>> getCards() async => List.unmodifiable(cards);

  @override
  Future<void> saveCards(List<ServiceCard> cards) async {}
}

class _FakeChatConversationsRepository implements ChatConversationsRepository {
  List<ChatConversation> stored;

  _FakeChatConversationsRepository([List<ChatConversation>? initial]) : stored = initial ?? [];

  @override
  Future<List<ChatConversation>> getConversations() async => List.unmodifiable(stored);

  @override
  Future<void> saveConversations(List<ChatConversation> conversations) async {
    stored = List.of(conversations);
  }
}

class _FakeBrainRepository implements BrainRepository {
  @override
  Future<String?> buildSystemPrompt() async => null;
}

ChatController _buildController({List<ChatConversation> conversations = const []}) {
  final card = ServiceCard(
    id: 'ollama-1',
    category: ServiceCategory.localLlm,
    type: ServiceType.ollama,
    name: 'Ollama',
    fields: const {},
  );

  return ChatController(
    _FakeServiceCardsRepository([card]),
    (card) => _FakeChatModelRepository(),
    _FakeChatConversationsRepository(conversations),
    _FakeBrainRepository(),
  );
}

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('HomeChatSection', () {
    testWidgets('compact: false shows title header and suggested-prompt chips', (tester) async {
      final controller = _buildController();
      await controller.load();

      await tester.pumpWidget(_wrap(HomeChatSection(controller: controller)));
      await tester.pump();

      expect(find.text('Assistant'), findsOneWidget);
      expect(find.text('New chat'), findsOneWidget);
      expect(find.text('Summarize this codebase'), findsOneWidget);
      expect(find.text('Ask the assistant anything.'), findsNothing);
    });

    testWidgets('compact: true hides title header and suggested-prompt chips, shows placeholder', (
      tester,
    ) async {
      final controller = _buildController();
      await controller.load();

      await tester.pumpWidget(_wrap(HomeChatSection(controller: controller, compact: true)));
      await tester.pump();

      expect(find.text('Assistant'), findsNothing);
      expect(find.text('New chat'), findsNothing);
      expect(find.text('Summarize this codebase'), findsNothing);
      expect(find.text('Ask the assistant anything.'), findsOneWidget);
    });
  });
}
