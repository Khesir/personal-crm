import 'package:flutter_test/flutter_test.dart';
import 'package:crm/features/home/domain/model/chat_conversation.dart';
import 'package:crm/features/home/domain/model/chat_message.dart';

void main() {
  group('ChatConversation', () {
    test('fromJson defaults new fields when absent (old shape)', () {
      final oldJson = {
        'id': 'conv_1',
        'title': 'Old conversation',
        'createdAt': '2026-01-01T00:00:00.000Z',
        'updatedAt': '2026-01-01T00:00:00.000Z',
        'messages': [
          {'role': 'user', 'content': 'Hi', 'streaming': false},
        ],
      };

      final conversation = ChatConversation.fromJson(oldJson);

      expect(conversation.id, 'conv_1');
      expect(conversation.workingProjectId, isNull);
      expect(conversation.trustedReferenceProjectIds, isEmpty);
      expect(conversation.shellAccessEnabled, isFalse);
      expect(conversation.isDeepResearch, isFalse);
    });

    test('toJson/fromJson round trip for new shape', () {
      final conversation = ChatConversation(
        id: 'conv_1',
        title: 'Agent conversation',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 2),
        messages: const [
          ChatMessage(role: ChatRole.user, content: 'Hi'),
        ],
        workingProjectId: 'proj_1',
        trustedReferenceProjectIds: const ['proj_2', 'proj_3'],
        shellAccessEnabled: true,
        isDeepResearch: true,
      );

      final json = conversation.toJson();
      final restored = ChatConversation.fromJson(json);

      expect(restored.id, conversation.id);
      expect(restored.title, conversation.title);
      expect(restored.workingProjectId, 'proj_1');
      expect(restored.trustedReferenceProjectIds, ['proj_2', 'proj_3']);
      expect(restored.messages.length, 1);
      expect(restored.shellAccessEnabled, isTrue);
      expect(restored.isDeepResearch, isTrue);
    });

    test('copyWith updates new fields', () {
      final conversation = ChatConversation(
        id: 'conv_1',
        title: 'Conversation',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );

      final updated = conversation.copyWith(
        workingProjectId: 'proj_1',
        trustedReferenceProjectIds: const ['proj_2'],
      );

      expect(updated.workingProjectId, 'proj_1');
      expect(updated.trustedReferenceProjectIds, ['proj_2']);
    });

    test('copyWith preserves shellAccessEnabled (immutable after creation)', () {
      final conversation = ChatConversation(
        id: 'conv_1',
        title: 'Conversation',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
        workingProjectId: 'proj_1',
        shellAccessEnabled: true,
      );

      final updated = conversation.copyWith(title: 'Renamed');

      expect(updated.shellAccessEnabled, isTrue);
    });

    test('copyWith preserves isDeepResearch (immutable after creation)', () {
      final conversation = ChatConversation(
        id: 'conv_1',
        title: 'Conversation',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
        isDeepResearch: true,
      );

      final updated = conversation.copyWith(title: 'Renamed');

      expect(updated.isDeepResearch, isTrue);
    });
  });
}
