import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:crm/features/home/data/repository/agent_tool_repository_impl.dart';
import 'package:crm/features/home/domain/model/tool_call.dart';
import 'package:crm/features/home/domain/model/tool_execution_result.dart';

void main() {
  late Directory workingDir;
  late Directory referenceDir;
  late Directory unknownDir;
  late AgentToolRepositoryImpl repo;

  setUp(() async {
    workingDir = await Directory.systemTemp.createTemp('agent_tool_working_');
    referenceDir = await Directory.systemTemp.createTemp('agent_tool_reference_');
    unknownDir = await Directory.systemTemp.createTemp('agent_tool_unknown_');
    repo = AgentToolRepositoryImpl();
  });

  tearDown(() async {
    await workingDir.delete(recursive: true);
    await referenceDir.delete(recursive: true);
    await unknownDir.delete(recursive: true);
  });

  Future<ToolExecutionResult> exec(
    ToolCall call, {
    List<String> trusted = const [],
    Map<String, String>? registered,
  }) {
    return repo.execute(
      call,
      workingProjectPath: workingDir.path,
      trustedReferenceProjectPaths: trusted,
      registeredProjectPaths: registered ?? {workingDir.path: 'working-project'},
    );
  }

  group('read_file', () {
    test('returns file contents under the working project', () async {
      final file = File(p.join(workingDir.path, 'hello.txt'));
      await file.writeAsString('hello world');

      final result = await exec(const ToolCall(id: '1', name: 'read_file', arguments: {'path': 'hello.txt'}));

      expect(result, isA<ToolOutput>());
      expect((result as ToolOutput).text, 'hello world');
    });

    test('returns ToolError when file not found', () async {
      final result = await exec(const ToolCall(id: '1', name: 'read_file', arguments: {'path': 'missing.txt'}));

      expect(result, isA<ToolError>());
    });

    test('succeeds for a path under a trusted reference project', () async {
      final file = File(p.join(referenceDir.path, 'ref.txt'));
      await file.writeAsString('reference content');

      final result = await exec(
        ToolCall(id: '1', name: 'read_file', arguments: {'path': p.join(referenceDir.path, 'ref.txt')}),
        trusted: [referenceDir.path],
        registered: {workingDir.path: 'working-project', referenceDir.path: 'reference-project'},
      );

      expect(result, isA<ToolOutput>());
      expect((result as ToolOutput).text, 'reference content');
    });

    test('returns ToolReferenceConfirmationNeeded for a registered but untrusted reference project', () async {
      final file = File(p.join(referenceDir.path, 'ref.txt'));
      await file.writeAsString('reference content');

      final result = await exec(
        ToolCall(id: '1', name: 'read_file', arguments: {'path': p.join(referenceDir.path, 'ref.txt')}),
        registered: {workingDir.path: 'working-project', referenceDir.path: 'reference-project'},
      );

      expect(result, isA<ToolReferenceConfirmationNeeded>());
      final confirmation = result as ToolReferenceConfirmationNeeded;
      expect(confirmation.projectId, 'reference-project');
      expect(confirmation.path, p.normalize(p.join(referenceDir.path, 'ref.txt')));
    });

    test('returns ToolError for a path outside all known project roots', () async {
      final file = File(p.join(unknownDir.path, 'unknown.txt'));
      await file.writeAsString('unknown content');

      final result = await exec(
        ToolCall(id: '1', name: 'read_file', arguments: {'path': p.join(unknownDir.path, 'unknown.txt')}),
        registered: {workingDir.path: 'working-project', referenceDir.path: 'reference-project'},
      );

      expect(result, isA<ToolError>());
    });
  });

  group('list_dir', () {
    test('returns directory entries under the working project', () async {
      await File(p.join(workingDir.path, 'a.txt')).writeAsString('a');
      await Directory(p.join(workingDir.path, 'sub')).create();

      final result = await exec(const ToolCall(id: '1', name: 'list_dir', arguments: {'path': '.'}));

      expect(result, isA<ToolOutput>());
      final text = (result as ToolOutput).text;
      expect(text, contains('a.txt'));
      expect(text, contains('sub/'));
    });

    test('returns ToolError when directory not found', () async {
      final result = await exec(const ToolCall(id: '1', name: 'list_dir', arguments: {'path': 'missing'}));

      expect(result, isA<ToolError>());
    });
  });

  group('grep', () {
    test('returns matching lines with file path and line number', () async {
      await File(p.join(workingDir.path, 'a.txt')).writeAsString('foo\nbar\nfoobar\n');
      await File(p.join(workingDir.path, 'b.txt')).writeAsString('nothing here\n');

      final result = await exec(const ToolCall(id: '1', name: 'grep', arguments: {'pattern': 'foo'}));

      expect(result, isA<ToolOutput>());
      final text = (result as ToolOutput).text;
      expect(text, contains('a.txt:1: foo'));
      expect(text, contains('a.txt:3: foobar'));
      expect(text, isNot(contains('b.txt')));
    });

    test('returns a "no matches" ToolOutput when nothing matches', () async {
      await File(p.join(workingDir.path, 'a.txt')).writeAsString('nothing here\n');

      final result = await exec(const ToolCall(id: '1', name: 'grep', arguments: {'pattern': 'zzz'}));

      expect(result, isA<ToolOutput>());
    });
  });

  group('write_file', () {
    test('returns ToolWriteProposal with file content as preview for a new path', () async {
      final result = await exec(
        const ToolCall(id: '1', name: 'write_file', arguments: {'path': 'new.txt', 'content': 'new content'}),
      );

      expect(result, isA<ToolWriteProposal>());
      final proposal = result as ToolWriteProposal;
      expect(proposal.path, p.normalize(p.join(workingDir.path, 'new.txt')));
      expect(proposal.preview, isA<WriteFileCreation>());
      expect((proposal.preview as WriteFileCreation).content, 'new content');

      expect(await File(proposal.path).exists(), isFalse);
    });

    test('returns ToolError when path already exists', () async {
      await File(p.join(workingDir.path, 'existing.txt')).writeAsString('already here');

      final result = await exec(
        const ToolCall(id: '1', name: 'write_file', arguments: {'path': 'existing.txt', 'content': 'new content'}),
      );

      expect(result, isA<ToolError>());
    });

    test('returns ToolError for a path outside the working project, even a reference project', () async {
      final result = await exec(
        ToolCall(
          id: '1',
          name: 'write_file',
          arguments: {'path': p.join(referenceDir.path, 'new.txt'), 'content': 'x'},
        ),
        trusted: [referenceDir.path],
        registered: {workingDir.path: 'working-project', referenceDir.path: 'reference-project'},
      );

      expect(result, isA<ToolError>());
    });
  });

  group('edit_file', () {
    test('returns ToolWriteProposal with old/new diff when old_text matches exactly once', () async {
      await File(p.join(workingDir.path, 'a.txt')).writeAsString('hello world');

      final result = await exec(
        const ToolCall(
          id: '1',
          name: 'edit_file',
          arguments: {'path': 'a.txt', 'old_text': 'world', 'new_text': 'there'},
        ),
      );

      expect(result, isA<ToolWriteProposal>());
      final proposal = result as ToolWriteProposal;
      expect(proposal.preview, isA<EditFileChange>());
      final change = proposal.preview as EditFileChange;
      expect(change.oldText, 'world');
      expect(change.newText, 'there');

      expect(await File(proposal.path).readAsString(), 'hello world');
    });

    test('returns ToolError when old_text matches zero times', () async {
      await File(p.join(workingDir.path, 'a.txt')).writeAsString('hello world');

      final result = await exec(
        const ToolCall(
          id: '1',
          name: 'edit_file',
          arguments: {'path': 'a.txt', 'old_text': 'missing', 'new_text': 'there'},
        ),
      );

      expect(result, isA<ToolError>());
    });

    test('returns ToolError when old_text matches multiple times', () async {
      await File(p.join(workingDir.path, 'a.txt')).writeAsString('foo foo');

      final result = await exec(
        const ToolCall(
          id: '1',
          name: 'edit_file',
          arguments: {'path': 'a.txt', 'old_text': 'foo', 'new_text': 'bar'},
        ),
      );

      expect(result, isA<ToolError>());
    });

    test('returns ToolError when file not found', () async {
      final result = await exec(
        const ToolCall(
          id: '1',
          name: 'edit_file',
          arguments: {'path': 'missing.txt', 'old_text': 'a', 'new_text': 'b'},
        ),
      );

      expect(result, isA<ToolError>());
    });

    test('returns ToolError for a path outside the working project', () async {
      await File(p.join(referenceDir.path, 'a.txt')).writeAsString('hello world');

      final result = await exec(
        ToolCall(
          id: '1',
          name: 'edit_file',
          arguments: {'path': p.join(referenceDir.path, 'a.txt'), 'old_text': 'world', 'new_text': 'there'},
        ),
        trusted: [referenceDir.path],
        registered: {workingDir.path: 'working-project', referenceDir.path: 'reference-project'},
      );

      expect(result, isA<ToolError>());
    });
  });

  group('applyWrite', () {
    test('WriteFileCreation creates the file with the proposed content', () async {
      final path = p.join(workingDir.path, 'new.txt');
      final result = await repo.applyWrite(ToolWriteProposal(path, const WriteFileCreation('hello')));

      expect(result, isA<ToolOutput>());
      expect(await File(path).readAsString(), 'hello');
      expect((result as ToolOutput).text, contains(path));
    });

    test('EditFileChange replaces the matched text in the existing file', () async {
      final path = p.join(workingDir.path, 'a.txt');
      await File(path).writeAsString('hello world');

      final result = await repo.applyWrite(
        ToolWriteProposal(path, const EditFileChange('world', 'there')),
      );

      expect(result, isA<ToolOutput>());
      expect(await File(path).readAsString(), 'hello there');
    });

    test('EditFileChange returns ToolError if old_text no longer matches exactly once', () async {
      final path = p.join(workingDir.path, 'a.txt');
      await File(path).writeAsString('hello hello');

      final result = await repo.applyWrite(
        ToolWriteProposal(path, const EditFileChange('hello', 'hi')),
      );

      expect(result, isA<ToolError>());
      expect(await File(path).readAsString(), 'hello hello');
    });
  });
}
