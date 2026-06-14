import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crm/features/brain/api.dart';
import 'package:crm/features/home/domain/controller/chat_controller.dart';
import 'package:crm/features/home/domain/model/chat_conversation.dart';
import 'package:crm/features/home/domain/model/chat_stream_event.dart';
import 'package:crm/features/home/domain/model/chat_message.dart';
import 'package:crm/features/home/domain/model/tool_definition.dart';
import 'package:crm/features/home/domain/repository/chat_conversations_repository.dart';
import 'package:crm/features/home/domain/repository/chat_model_repository.dart';
import 'package:crm/features/home/presentation/widget/chat_mode_toggle.dart';
import 'package:crm/features/settings/domain/model/project.dart';
import 'package:crm/features/settings/domain/model/service_card.dart';
import 'package:crm/features/settings/domain/repository/projects_repository.dart';
import 'package:crm/features/settings/domain/repository/service_cards_repository.dart';

class _FakeChatModelRepository implements ChatModelRepository {
  @override
  Future<List<String>> listModels() async => ['claude-3-5-sonnet-20241022'];

  @override
  Stream<ChatStreamEvent> streamChat({
    required String model,
    required List<ChatMessage> messages,
    List<ToolDefinition> tools = const [],
  }) {
    return const Stream.empty();
  }
}

class _FakeProjectsRepository implements ProjectsRepository {
  final List<Project> projects;

  _FakeProjectsRepository(this.projects);

  @override
  Future<List<Project>> getProjects() async => List.unmodifiable(projects);

  @override
  Future<void> saveProjects(List<Project> projects) async {}
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

  _FakeChatConversationsRepository(this.stored);

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

const _claudeCard = ServiceCard(
  id: 'claude-1',
  category: ServiceCategory.apiLlm,
  type: ServiceType.claudeAnthropic,
  name: 'Claude',
  fields: {'apiKey': 'sk-ant-test'},
  enabled: true,
);

Project _project({required String id, required String name}) {
  return Project(
    id: id,
    name: name,
    localPath: '/work/$id',
    projectKey: id,
    hasBugReports: false,
    hasAnnouncements: false,
  );
}

ChatConversation _conversation({String? workingProjectId}) {
  final now = DateTime.now();
  return ChatConversation(
    id: 'convo-1',
    title: 'Existing chat',
    createdAt: now,
    updatedAt: now,
    messages: [const ChatMessage(role: ChatRole.user, content: 'hi')],
    workingProjectId: workingProjectId,
  );
}

Future<ChatController> _loadedController({
  required List<ChatConversation> conversations,
  required String activeConversationId,
  List<Project> projects = const [],
}) async {
  final controller = ChatController(
    _FakeServiceCardsRepository([_claudeCard]),
    (_) => _FakeChatModelRepository(),
    _FakeChatConversationsRepository(conversations),
    _FakeBrainRepository(),
    projectsRepository: _FakeProjectsRepository(projects),
  );
  await controller.load();
  controller.selectConversation(activeConversationId);
  return controller;
}

void main() {
  group('ChatModeToggle', () {
    testWidgets('plain conversation: tapping the active "Chat" segment is a no-op', (tester) async {
      final conversation = _conversation();
      final controller = await _loadedController(
        conversations: [conversation],
        activeConversationId: conversation.id,
      );

      await tester.pumpWidget(MaterialApp(
        home: ChatModeToggle(controller: controller, conversation: conversation),
      ));

      await tester.tap(find.text('Chat'));
      await tester.pumpAndSettle();

      expect(controller.state.conversations, hasLength(1));
      expect(controller.state.activeConversationId, conversation.id);

      controller.dispose();
    });

    testWidgets('agent-mode conversation: tapping "Chat" starts a new plain conversation', (tester) async {
      final conversation = _conversation(workingProjectId: 'proj-1');
      final controller = await _loadedController(
        conversations: [conversation],
        activeConversationId: conversation.id,
        projects: [_project(id: 'proj-1', name: 'crm')],
      );

      await tester.pumpWidget(MaterialApp(
        home: ChatModeToggle(controller: controller, conversation: conversation),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Chat'));
      await tester.pumpAndSettle();

      expect(controller.state.conversations, hasLength(2));
      final active = controller.state.activeConversation;
      expect(active, isNotNull);
      expect(active!.id, isNot(conversation.id));
      expect(active.workingProjectId, isNull);

      controller.dispose();
    });

    testWidgets('agent-mode conversation: shows the working project name', (tester) async {
      final conversation = _conversation(workingProjectId: 'proj-1');
      final controller = await _loadedController(
        conversations: [conversation],
        activeConversationId: conversation.id,
        projects: [_project(id: 'proj-1', name: 'crm')],
      );

      await tester.pumpWidget(MaterialApp(
        home: ChatModeToggle(controller: controller, conversation: conversation),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Agent · crm'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('plain conversation: tapping "Agent" opens the project/model picker and creates an '
        'agent-mode conversation on confirm', (tester) async {
      final conversation = _conversation();
      final controller = await _loadedController(
        conversations: [conversation],
        activeConversationId: conversation.id,
        projects: [_project(id: 'proj-1', name: 'crm')],
      );

      await tester.pumpWidget(MaterialApp(
        home: ChatModeToggle(controller: controller, conversation: conversation),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Agent'));
      await tester.pumpAndSettle();

      expect(find.text('Agent mode'), findsOneWidget);

      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(controller.state.conversations, hasLength(2));
      final active = controller.state.activeConversation;
      expect(active, isNotNull);
      expect(active!.id, isNot(conversation.id));
      expect(active.workingProjectId, 'proj-1');

      controller.dispose();
    });

    testWidgets('no active conversation: renders Chat and Agent segments', (tester) async {
      final controller = await _loadedController(conversations: const [], activeConversationId: '');

      await tester.pumpWidget(MaterialApp(
        home: ChatModeToggle(controller: controller, conversation: null),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Chat'), findsOneWidget);
      expect(find.text('Agent'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('plain conversation: tapping "Research" starts a new Deep Research conversation', (tester) async {
      final conversation = _conversation();
      final controller = await _loadedController(
        conversations: [conversation],
        activeConversationId: conversation.id,
      );

      await tester.pumpWidget(MaterialApp(
        home: ChatModeToggle(controller: controller, conversation: conversation),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Research'));
      await tester.pumpAndSettle();

      expect(controller.state.conversations, hasLength(2));
      final active = controller.state.activeConversation;
      expect(active, isNotNull);
      expect(active!.id, isNot(conversation.id));
      expect(active.isDeepResearch, isTrue);

      controller.dispose();
    });

    testWidgets('Deep Research conversation: "Research" segment is selected and tapping it is a no-op', (tester) async {
      final now = DateTime.now();
      final conversation = ChatConversation(
        id: 'research-convo',
        title: 'Research chat',
        createdAt: now,
        updatedAt: now,
        messages: const [],
        isDeepResearch: true,
      );
      final controller = await _loadedController(
        conversations: [conversation],
        activeConversationId: conversation.id,
      );

      await tester.pumpWidget(MaterialApp(
        home: ChatModeToggle(controller: controller, conversation: conversation),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Research'));
      await tester.pumpAndSettle();

      expect(controller.state.conversations, hasLength(1));
      expect(controller.state.activeConversationId, conversation.id);

      controller.dispose();
    });
  });
}
