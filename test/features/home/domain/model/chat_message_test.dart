import 'package:flutter_test/flutter_test.dart';
import 'package:crm/features/home/domain/model/chat_message.dart';
import 'package:crm/features/home/domain/model/tool_call.dart';

void main() {
  group('ChatRole', () {
    test('value covers all four roles', () {
      expect(ChatRole.user.value, 'user');
      expect(ChatRole.assistant.value, 'assistant');
      expect(ChatRole.system.value, 'system');
      expect(ChatRole.tool.value, 'tool');
    });

    test('fromValue covers all four roles', () {
      expect(ChatRole.fromValue('user'), ChatRole.user);
      expect(ChatRole.fromValue('assistant'), ChatRole.assistant);
      expect(ChatRole.fromValue('system'), ChatRole.system);
      expect(ChatRole.fromValue('tool'), ChatRole.tool);
    });

    test('fromValue falls back to user for unrecognized values', () {
      expect(ChatRole.fromValue('unknown'), ChatRole.user);
    });
  });

  group('ToolCall', () {
    test('toJson/fromJson round trip', () {
      const toolCall = ToolCall(
        id: 'call_1',
        name: 'read_file',
        arguments: {'path': 'lib/main.dart'},
      );

      final json = toolCall.toJson();
      final restored = ToolCall.fromJson(json);

      expect(restored.id, toolCall.id);
      expect(restored.name, toolCall.name);
      expect(restored.arguments, toolCall.arguments);
    });
  });

  group('ChatMessage', () {
    test('fromJson defaults new fields when absent (old shape)', () {
      final oldJson = {
        'role': 'assistant',
        'content': 'Hello',
        'streaming': false,
      };

      final message = ChatMessage.fromJson(oldJson);

      expect(message.role, ChatRole.assistant);
      expect(message.content, 'Hello');
      expect(message.toolCalls, isEmpty);
      expect(message.toolCallId, isNull);
      expect(message.toolName, isNull);
    });

    test('toJson/fromJson round trip for new shape', () {
      const message = ChatMessage(
        role: ChatRole.tool,
        content: 'File contents...',
        toolCalls: [
          ToolCall(id: 'call_1', name: 'read_file', arguments: {'path': 'a.txt'}),
        ],
        toolCallId: 'call_1',
        toolName: 'read_file',
      );

      final json = message.toJson();
      final restored = ChatMessage.fromJson(json);

      expect(restored.role, message.role);
      expect(restored.content, message.content);
      expect(restored.toolCalls.length, 1);
      expect(restored.toolCalls.first.id, 'call_1');
      expect(restored.toolCalls.first.name, 'read_file');
      expect(restored.toolCalls.first.arguments, {'path': 'a.txt'});
      expect(restored.toolCallId, 'call_1');
      expect(restored.toolName, 'read_file');
    });

    test('copyWith updates new fields', () {
      const message = ChatMessage(role: ChatRole.assistant, content: 'Hi');

      final updated = message.copyWith(
        toolCalls: const [ToolCall(id: 'call_1', name: 'read_file')],
        toolCallId: 'call_1',
        toolName: 'read_file',
      );

      expect(updated.toolCalls.length, 1);
      expect(updated.toolCallId, 'call_1');
      expect(updated.toolName, 'read_file');
    });
  });
}
