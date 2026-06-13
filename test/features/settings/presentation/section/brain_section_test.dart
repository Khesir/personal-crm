import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crm/features/brain/api.dart';
import 'package:crm/features/settings/domain/repository/process_runner.dart';
import 'package:crm/features/settings/presentation/section/brain_section.dart';

class FakeProcessRunner implements ProcessRunner {
  String? lastExecutable;
  List<String>? lastArgs;
  bool? lastRunInShell;

  @override
  Future<ProcessResult> run(
    String executable,
    List<String> args, {
    bool runInShell = false,
  }) async {
    lastExecutable = executable;
    lastArgs = args;
    lastRunInShell = runInShell;
    return ProcessResult(0, 0, '', '');
  }
}

void main() {
  group('BrainSection', () {
    testWidgets('tapping "Open brain folder" calls ProcessRunner.run with resolved path', (
      tester,
    ) async {
      final runner = FakeProcessRunner();

      await tester.pumpWidget(
        MaterialApp(
          home: BrainSection(processRunner: runner),
        ),
      );

      await tester.tap(find.text('Open brain folder'));
      await tester.pump();

      expect(runner.lastExecutable, 'explorer.exe');
      expect(runner.lastArgs, [resolveBrainFolderPath()]);
      expect(runner.lastRunInShell, isTrue);
    });
  });
}
