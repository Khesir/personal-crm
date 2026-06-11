import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:crm/features/agent_run/domain/controller/agent_run_controller.dart';
import 'package:crm/features/agent_run/domain/model/agent_event.dart';
import 'package:crm/features/agent_run/domain/model/agent_skill.dart';
import 'package:crm/features/agent_run/domain/repository/agent_run_repository.dart';
import 'package:crm/features/agent_run/presentation/state/agent_run_state.dart';

class FakeAgentRunRepository implements AgentRunRepository {
  final Stream<AgentEvent> Function({
    required String skill,
    required String repoPath,
    Map<String, dynamic>? context,
  }) onRun;

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

void main() {
  group('AgentRunController', () {
    test('start() transitions status to running and appends events as they stream', () async {
      final repo = FakeAgentRunRepository(({required skill, required repoPath, context}) {
        return Stream.fromIterable(<AgentEvent>[
          const AgentThinking('Looking at the issue...'),
        ]);
      });
      final controller = AgentRunController(repo);

      final future = controller.start(
        skill: AgentSkill.workIssue,
        repoPath: '/repo',
        projectName: 'crm',
      );

      expect(controller.state.status, AgentRunStatus.running);

      await future;

      expect(controller.state.events, hasLength(1));
      expect(controller.state.events.first, isA<AgentThinking>());

      controller.dispose();
    });

    test('AgentToolUse and AgentToolResult events are appended in order', () async {
      final repo = FakeAgentRunRepository(({required skill, required repoPath, context}) {
        return Stream.fromIterable(<AgentEvent>[
          const AgentToolUse('Read', '{"file":"a.dart"}'),
          const AgentToolResult('Read', 'contents...'),
        ]);
      });
      final controller = AgentRunController(repo);

      await controller.start(
        skill: AgentSkill.workIssue,
        repoPath: '/repo',
        projectName: 'crm',
      );

      expect(controller.state.events, hasLength(2));
      expect(controller.state.events[0], isA<AgentToolUse>());
      expect(controller.state.events[1], isA<AgentToolResult>());

      controller.dispose();
    });

    test('AgentResult event with success=true sets status to done', () async {
      final repo = FakeAgentRunRepository(({required skill, required repoPath, context}) {
        return Stream.fromIterable(<AgentEvent>[
          const AgentResult('All done', true),
        ]);
      });
      final controller = AgentRunController(repo);

      await controller.start(
        skill: AgentSkill.workIssue,
        repoPath: '/repo',
        projectName: 'crm',
      );

      expect(controller.state.status, AgentRunStatus.done);

      controller.dispose();
    });

    test('AgentResult event with success=false sets status to error', () async {
      final repo = FakeAgentRunRepository(({required skill, required repoPath, context}) {
        return Stream.fromIterable(<AgentEvent>[
          const AgentResult('Something broke', false),
        ]);
      });
      final controller = AgentRunController(repo);

      await controller.start(
        skill: AgentSkill.workIssue,
        repoPath: '/repo',
        projectName: 'crm',
      );

      expect(controller.state.status, AgentRunStatus.error);

      controller.dispose();
    });

    test('stop() halts the run and sets status to stopped', () async {
      final eventsController = StreamController<AgentEvent>();
      final repo = FakeAgentRunRepository(({required skill, required repoPath, context}) {
        return eventsController.stream;
      });
      final controller = AgentRunController(repo);

      final future = controller.start(
        skill: AgentSkill.workIssue,
        repoPath: '/repo',
        projectName: 'crm',
      );

      await Future<void>.delayed(Duration.zero);
      expect(controller.state.status, AgentRunStatus.running);

      controller.stop();

      expect(controller.state.status, AgentRunStatus.stopped);

      eventsController.add(const AgentThinking('should be ignored'));
      await eventsController.close();
      await future;

      expect(controller.state.events, isEmpty);

      controller.dispose();
    });

    test('background() and foreground() toggle without affecting run state', () async {
      final eventsController = StreamController<AgentEvent>();
      final repo = FakeAgentRunRepository(({required skill, required repoPath, context}) {
        return eventsController.stream;
      });
      final controller = AgentRunController(repo);

      final future = controller.start(
        skill: AgentSkill.workIssue,
        repoPath: '/repo',
        projectName: 'crm',
      );
      await Future<void>.delayed(Duration.zero);

      expect(controller.state.isBackgrounded, isFalse);

      controller.background();
      expect(controller.state.isBackgrounded, isTrue);
      expect(controller.state.status, AgentRunStatus.running);

      controller.foreground();
      expect(controller.state.isBackgrounded, isFalse);
      expect(controller.state.status, AgentRunStatus.running);

      await eventsController.close();
      await future;
      controller.dispose();
    });

    test('start() passes skill id, repoPath and context to the repository', () async {
      String? capturedSkill;
      String? capturedRepoPath;
      Map<String, dynamic>? capturedContext;

      final repo = FakeAgentRunRepository(({required skill, required repoPath, context}) {
        capturedSkill = skill;
        capturedRepoPath = repoPath;
        capturedContext = context;
        return const Stream<AgentEvent>.empty();
      });
      final controller = AgentRunController(repo);

      await controller.start(
        skill: AgentSkill.workIssue,
        repoPath: '/repo/path',
        projectName: 'crm',
        context: {'issueId': '006'},
      );

      expect(capturedSkill, 'work-issue');
      expect(capturedRepoPath, '/repo/path');
      expect(capturedContext, {'issueId': '006'});

      controller.dispose();
    });
  });
}
