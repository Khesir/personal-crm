import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crm/features/agent_run/domain/controller/agent_run_controller.dart';
import 'package:crm/features/agent_run/domain/model/agent_event.dart';
import 'package:crm/features/agent_run/domain/model/agent_skill.dart';
import 'package:crm/features/agent_run/domain/repository/agent_run_repository.dart';
import 'package:crm/features/kanban/presentation/widget/agent_pane.dart';

class FakeAgentRunRepository implements AgentRunRepository {
  final Stream<AgentEvent> Function({
    required String skill,
    required String repoPath,
    Map<String, dynamic>? context,
  })
  onRun;

  FakeAgentRunRepository(this.onRun);

  @override
  Stream<AgentEvent> run({
    required String skill,
    required String repoPath,
    Map<String, dynamic>? context,
  }) {
    return onRun(skill: skill, repoPath: repoPath, context: context);
  }
}

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(height: 240, width: 400, child: child),
    ),
  );
}

void main() {
  group('AgentPane', () {
    testWidgets('shows empty-state message when no controller has ever run', (tester) async {
      await tester.pumpWidget(
        _wrap(const AgentPane(agentRunController: null, projectName: 'personal-crm')),
      );

      expect(find.textContaining('No agent runs yet for personal-crm'), findsOneWidget);
    });

    testWidgets('shows idle prompt with project name when controller is stopped and empty', (
      tester,
    ) async {
      final repo = FakeAgentRunRepository(({required skill, required repoPath, context}) {
        return const Stream<AgentEvent>.empty();
      });
      final controller = AgentRunController(repo);
      controller.stop();

      await tester.pumpWidget(
        _wrap(AgentPane(agentRunController: controller, projectName: 'personal-crm')),
      );

      expect(find.text('➜ '), findsOneWidget);
      expect(find.text('personal-crm'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('renders a transcript of events without overflow', (tester) async {
      final repo = FakeAgentRunRepository(({required skill, required repoPath, context}) {
        return Stream.fromIterable(<AgentEvent>[
          const AgentThinking('Looking at the issue...'),
          const AgentToolUse('Read', '{"file":"a.dart"}'),
          const AgentToolResult('Read', 'contents...'),
          const AgentResult('Done implementing feature', true),
        ]);
      });
      final controller = AgentRunController(repo);

      await controller.start(
        skill: AgentSkill.workIssue,
        repoPath: '/repo',
        projectName: 'personal-crm',
      );

      await tester.pumpWidget(
        _wrap(AgentPane(agentRunController: controller, projectName: 'personal-crm')),
      );
      await tester.pump();

      expect(find.textContaining('Looking at the issue...'), findsOneWidget);
      expect(find.textContaining('Read'), findsWidgets);
      expect(find.textContaining('Done implementing feature'), findsOneWidget);
      expect(tester.takeException(), isNull);

      controller.dispose();
    });

    testWidgets('shows run indicator with skill name while a run is active', (tester) async {
      final eventController = StreamController<AgentEvent>();
      final repo = FakeAgentRunRepository(({required skill, required repoPath, context}) {
        return eventController.stream;
      });
      final runController = AgentRunController(repo);

      unawaited(runController.start(
        skill: AgentSkill.workIssue,
        repoPath: '/repo',
        projectName: 'personal-crm',
      ));

      await tester.pumpWidget(
        _wrap(AgentPane(agentRunController: runController, projectName: 'personal-crm')),
      );
      await tester.pump();

      expect(find.textContaining(AgentSkill.workIssue.label), findsOneWidget);

      await eventController.close();
      runController.dispose();
    });

    testWidgets('hides run indicator when no run is active', (tester) async {
      final repo = FakeAgentRunRepository(({required skill, required repoPath, context}) {
        return const Stream<AgentEvent>.empty();
      });
      final runController = AgentRunController(repo);
      runController.stop();

      await tester.pumpWidget(
        _wrap(AgentPane(agentRunController: runController, projectName: 'personal-crm')),
      );
      await tester.pump();

      expect(find.textContaining(AgentSkill.workIssue.label), findsNothing);

      runController.dispose();
    });
  });
}
