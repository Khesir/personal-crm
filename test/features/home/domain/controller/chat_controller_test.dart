import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:crm/features/home/domain/controller/chat_controller.dart';
import 'package:crm/features/home/domain/model/chat_conversation.dart';
import 'package:crm/features/home/domain/model/chat_message.dart';
import 'package:crm/features/home/domain/repository/chat_conversations_repository.dart';
import 'package:crm/features/home/domain/repository/ollama_repository.dart';

class FakeOllamaRepository implements OllamaRepository {
  List<String> models;
  List<String> chunksToEmit;

  FakeOllamaRepository({
    this.models = const ['llama3.2'],
    this.chunksToEmit = const [],
  });

  @override
  Future<List<String>> listModels() async => models;

  @override
  Stream<String> streamChat({
    required String model,
    required List<ChatMessage> messages,
  }) {
    return Stream.fromIterable(chunksToEmit);
  }
}

class FakeChatConversationsRepository implements ChatConversationsRepository {
  List<ChatConversation> stored;

  FakeChatConversationsRepository([List<ChatConversation>? initial])
      : stored = initial ?? [];

  @override
  Future<List<ChatConversation>> getConversations() async =>
      List.unmodifiable(stored);

  @override
  Future<void> saveConversations(List<ChatConversation> conversations) async {
    stored = List.of(conversations);
  }
}

void main() {
  group('ChatController', () {
    test('newConversation adds a new conversation to state and selects it', () async {
      final controller = ChatController(
        FakeOllamaRepository(),
        FakeChatConversationsRepository(),
      );
      await controller.load();

      controller.newConversation();

      expect(controller.state.conversations, hasLength(1));
      expect(controller.state.activeConversationId, controller.state.conversations.first.id);

      controller.dispose();
    });

    test('load() populates availableModels and activeModel from listModels()', () async {
      final controller = ChatController(
        FakeOllamaRepository(models: ['llama3.2', 'qwen2.5']),
        FakeChatConversationsRepository(),
      );

      await controller.load();

      expect(controller.state.availableModels, ['llama3.2', 'qwen2.5']);
      expect(controller.state.activeModel, 'llama3.2');

      controller.dispose();
    });

    test('selectModel switches the active model', () async {
      final controller = ChatController(
        FakeOllamaRepository(models: ['llama3.2', 'qwen2.5']),
        FakeChatConversationsRepository(),
      );
      await controller.load();

      controller.selectModel('qwen2.5');

      expect(controller.state.activeModel, 'qwen2.5');

      controller.dispose();
    });

    test('sendMessage streams tokens and accumulates them into the assistant message', () async {
      final controller = ChatController(
        FakeOllamaRepository(chunksToEmit: ['Hel', 'lo', ' world']),
        FakeChatConversationsRepository(),
      );
      await controller.load();
      controller.newConversation();

      await controller.sendMessage('Hi there');

      final messages = controller.state.activeConversation!.messages;
      expect(messages, hasLength(2));
      expect(messages[0].role, ChatRole.user);
      expect(messages[0].content, 'Hi there');
      expect(messages[1].role, ChatRole.assistant);
      expect(messages[1].content, 'Hello world');
      expect(messages[1].streaming, isFalse);
      expect(controller.state.isStreaming, isFalse);

      controller.dispose();
    });

    test('sendMessage marks the assistant message as streaming while tokens arrive', () async {
      final chunkController = StreamController<String>();
      final repo = FakeOllamaRepository();
      final conversationsRepo = FakeChatConversationsRepository();
      final controller = ChatController(repo, conversationsRepo);
      await controller.load();
      controller.newConversation();

      // Override streamChat behavior via a custom fake for this test.
      final streamingController = ChatController(
        _ManualStreamOllamaRepository(chunkController.stream),
        conversationsRepo,
      );
      await streamingController.load();
      streamingController.newConversation();

      final future = streamingController.sendMessage('Hi');
      await Future<void>.delayed(Duration.zero);

      expect(streamingController.state.isStreaming, isTrue);
      final messages = streamingController.state.activeConversation!.messages;
      expect(messages.last.streaming, isTrue);

      chunkController.add('partial');
      await chunkController.close();
      await future;

      expect(streamingController.state.isStreaming, isFalse);
      controller.dispose();
      streamingController.dispose();
    });

    test('persistence round trip via the fake repository', () async {
      final conversationsRepo = FakeChatConversationsRepository();
      final firstController = ChatController(FakeOllamaRepository(), conversationsRepo);
      await firstController.load();
      firstController.newConversation();
      firstController.dispose();

      final secondController = ChatController(FakeOllamaRepository(), conversationsRepo);
      await secondController.load();

      expect(secondController.state.conversations, hasLength(1));
      expect(
        secondController.state.conversations.first.id,
        firstController.state.conversations.first.id,
      );

      secondController.dispose();
    });

    test('sendMessage persists the conversation with the final assistant message', () async {
      final conversationsRepo = FakeChatConversationsRepository();
      final controller = ChatController(
        FakeOllamaRepository(chunksToEmit: ['Hello']),
        conversationsRepo,
      );
      await controller.load();
      controller.newConversation();

      await controller.sendMessage('Hi');

      final reloaded = ChatController(FakeOllamaRepository(), conversationsRepo);
      await reloaded.load();

      final messages = reloaded.state.conversations.first.messages;
      expect(messages, hasLength(2));
      expect(messages[1].content, 'Hello');
      expect(messages[1].streaming, isFalse);

      controller.dispose();
      reloaded.dispose();
    });
  });
}

class _ManualStreamOllamaRepository implements OllamaRepository {
  final Stream<String> chunks;

  _ManualStreamOllamaRepository(this.chunks);

  @override
  Future<List<String>> listModels() async => ['llama3.2'];

  @override
  Stream<String> streamChat({
    required String model,
    required List<ChatMessage> messages,
  }) {
    return chunks;
  }
}
