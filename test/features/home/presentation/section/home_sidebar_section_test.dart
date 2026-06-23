import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crm/features/agent/domain/controller/agent_controller.dart';
import 'package:crm/features/agent/domain/model/agent_event.dart';
import 'package:crm/features/agent/domain/model/agent_session_summary.dart';
import 'package:crm/features/home/presentation/section/home_sidebar_section.dart';

import '../../../agent/domain/controller/agent_controller_test.dart' show FakeAgentRepository;

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: SizedBox(width: 240, child: child)));

void main() {
  testWidgets('shows empty hint when there are no sessions', (tester) async {
    final controller = AgentController(FakeAgentRepository([]));

    await tester.pumpWidget(_wrap(HomeSidebarSection(controller: controller)));
    await tester.pumpAndSettle();

    expect(find.text('No conversations yet.'), findsOneWidget);
  });

  testWidgets('renders sessions loaded from the controller', (tester) async {
    final repo = FakeAgentRepository([]);
    repo.sessions = [
      AgentSessionSummary(
        id: 's1',
        title: 'Debug NullPointer',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
    final controller = AgentController(repo);

    await tester.pumpWidget(_wrap(HomeSidebarSection(controller: controller)));
    await tester.pumpAndSettle();

    expect(find.text('Debug NullPointer'), findsOneWidget);
  });

  testWidgets('tapping New chat calls newChat on the controller', (tester) async {
    final repo = FakeAgentRepository([
      const AgentDoneEvent(sessionId: 's1', success: true),
    ]);
    final controller = AgentController(repo);
    await controller.sendMessage('hi');

    await tester.pumpWidget(_wrap(HomeSidebarSection(controller: controller)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('New chat'));
    await tester.pumpAndSettle();

    expect(controller.state.sessionId, isNull);
  });

  testWidgets('tapping a session calls resumeSession on the controller', (tester) async {
    final repo = FakeAgentRepository([]);
    repo.sessions = [
      AgentSessionSummary(
        id: 's1',
        title: 'Debug NullPointer',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
    final controller = AgentController(repo);

    await tester.pumpWidget(_wrap(HomeSidebarSection(controller: controller)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Debug NullPointer'));
    await tester.pumpAndSettle();

    expect(controller.state.sessionId, 's1');
  });
}
