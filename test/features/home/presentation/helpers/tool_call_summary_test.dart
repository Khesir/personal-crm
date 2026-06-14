import 'package:flutter_test/flutter_test.dart';
import 'package:crm/features/home/domain/model/tool_call.dart';
import 'package:crm/features/home/domain/model/tool_execution_result.dart';
import 'package:crm/features/home/presentation/helpers/tool_call_summary.dart';

void main() {
  group('isWriteOrEditTool', () {
    test('is true for write_file and edit_file', () {
      expect(isWriteOrEditTool('write_file'), isTrue);
      expect(isWriteOrEditTool('edit_file'), isTrue);
    });

    test('is false for read_file, list_dir, and grep', () {
      expect(isWriteOrEditTool('read_file'), isFalse);
      expect(isWriteOrEditTool('list_dir'), isFalse);
      expect(isWriteOrEditTool('grep'), isFalse);
    });
  });

  group('toolCallSummary', () {
    test('shows the path argument for read_file, list_dir, write_file, and edit_file', () {
      expect(toolCallSummary(const ToolCall(id: '1', name: 'read_file', arguments: {'path': 'lib/main.dart'})),
          'lib/main.dart');
      expect(toolCallSummary(const ToolCall(id: '2', name: 'list_dir', arguments: {'path': 'lib'})), 'lib');
      expect(
          toolCallSummary(const ToolCall(
              id: '3', name: 'write_file', arguments: {'path': 'lib/new.dart', 'content': 'hello'})),
          'lib/new.dart');
      expect(
          toolCallSummary(const ToolCall(
              id: '4',
              name: 'edit_file',
              arguments: {'path': 'lib/main.dart', 'old_text': 'a', 'new_text': 'b'})),
          'lib/main.dart');
    });

    test('shows the pattern argument for grep', () {
      expect(
          toolCallSummary(const ToolCall(id: '5', name: 'grep', arguments: {'pattern': 'TODO', 'path': 'lib'})),
          'TODO');
    });

    test('shows the query argument for web_search', () {
      expect(
          toolCallSummary(const ToolCall(id: '8', name: 'web_search', arguments: {'query': 'flutter news'})),
          'flutter news');
    });

    test('shows the command argument for run_command', () {
      expect(
          toolCallSummary(const ToolCall(id: '10', name: 'run_command', arguments: {'command': 'flutter test'})),
          'flutter test');
    });

    test('shows the url argument for fetch_page', () {
      expect(
          toolCallSummary(const ToolCall(id: '12', name: 'fetch_page', arguments: {'url': 'https://example.com'})),
          'https://example.com');
    });

    test('falls back to an empty string when the expected argument is missing', () {
      expect(toolCallSummary(const ToolCall(id: '6', name: 'read_file', arguments: {})), '');
      expect(toolCallSummary(const ToolCall(id: '7', name: 'grep', arguments: {})), '');
      expect(toolCallSummary(const ToolCall(id: '9', name: 'web_search', arguments: {})), '');
      expect(toolCallSummary(const ToolCall(id: '11', name: 'run_command', arguments: {})), '');
      expect(toolCallSummary(const ToolCall(id: '13', name: 'fetch_page', arguments: {})), '');
    });
  });

  group('toolCallWritePreview', () {
    test('builds WriteFileCreation from a write_file call\'s content argument', () {
      final preview = toolCallWritePreview(
          const ToolCall(id: '1', name: 'write_file', arguments: {'path': 'new.dart', 'content': 'hello'}));

      expect(preview, isA<WriteFileCreation>());
      expect((preview as WriteFileCreation).content, 'hello');
    });

    test('builds EditFileChange from an edit_file call\'s old_text/new_text arguments', () {
      final preview = toolCallWritePreview(const ToolCall(
        id: '2',
        name: 'edit_file',
        arguments: {'path': 'main.dart', 'old_text': 'foo', 'new_text': 'bar'},
      ));

      expect(preview, isA<EditFileChange>());
      expect((preview as EditFileChange).oldText, 'foo');
      expect(preview.newText, 'bar');
    });

    test('returns null for read_file, list_dir, and grep', () {
      expect(toolCallWritePreview(const ToolCall(id: '3', name: 'read_file', arguments: {'path': 'a.dart'})), isNull);
      expect(toolCallWritePreview(const ToolCall(id: '4', name: 'list_dir', arguments: {'path': '.'})), isNull);
      expect(toolCallWritePreview(const ToolCall(id: '5', name: 'grep', arguments: {'pattern': 'x'})), isNull);
    });

    test('defaults to empty strings when arguments are missing', () {
      final writePreview = toolCallWritePreview(const ToolCall(id: '6', name: 'write_file', arguments: {'path': 'a.dart'}));
      expect((writePreview as WriteFileCreation).content, '');

      final editPreview = toolCallWritePreview(const ToolCall(id: '7', name: 'edit_file', arguments: {'path': 'a.dart'}));
      expect((editPreview as EditFileChange).oldText, '');
      expect(editPreview.newText, '');
    });
  });
}
