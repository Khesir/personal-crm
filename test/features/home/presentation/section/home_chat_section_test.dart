import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crm/features/agent/domain/controller/agent_controller.dart';
import 'package:crm/features/agent/domain/model/agent_event.dart';
import 'package:crm/features/agent/domain/model/agent_models_result.dart';
import 'package:crm/features/home/presentation/section/home_chat_section.dart';

import '../../../agent/domain/controller/agent_controller_test.dart' show FakeAgentRepository;

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('shows welcome state with status line when no session is active', (tester) async {
    final repo = FakeAgentRepository([]);
    repo.modelsResult = const AgentModelsResult(
      provider: 'ollama',
      models: [AgentModelInfo(name: 'llama3.2', parameterSize: '3.2B')],
    );
    final controller = AgentController(repo);

    await tester.pumpWidget(_wrap(HomeChatSection(controller: controller)));
    await tester.pumpAndSettle();

    expect(find.textContaining('Welcome back,'), findsOneWidget);
    expect(find.textContaining('Connected to Ollama · 1 model ready locally'), findsOneWidget);
  });

  testWidgets('renders suggested prompt chips that send a message on tap', (tester) async {
    final repo = FakeAgentRepository([
      const AgentDoneEvent(sessionId: 's1', success: true),
    ]);
    final controller = AgentController(repo);

    await tester.pumpWidget(_wrap(HomeChatSection(controller: controller)));
    await tester.pumpAndSettle();

    expect(find.text('Write code'), findsOneWidget);

    await tester.tap(find.text('Write code'));
    await tester.pumpAndSettle();

    expect(controller.state.sessionId, 's1');
  });

  testWidgets('sending a message switches from welcome state to transcript', (tester) async {
    final repo = FakeAgentRepository([
      const AgentTextEvent('Hello there'),
      const AgentDoneEvent(sessionId: 's1', success: true),
    ]);
    final controller = AgentController(repo);

    await tester.pumpWidget(_wrap(HomeChatSection(controller: controller)));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'hi there');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.textContaining('Welcome back,'), findsNothing);
    expect(find.text('Hello there'), findsOneWidget);
  });
}
