import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crm/features/agent/domain/controller/agent_controller.dart';
import 'package:crm/features/agent/presentation/section/agent_settings_section.dart';

import '../../domain/controller/agent_controller_test.dart' show FakeAgentRepository;

void main() {
  testWidgets('shows not running message when server is unavailable', (tester) async {
    final controller = AgentController(_ThrowingConfigRepository());

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: AgentSettingsSection(controller: controller))),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.textContaining('Agent server not running'), findsOneWidget);
  });

  testWidgets('renders fields with current config values from getConfig', (tester) async {
    final repo = FakeAgentRepository([]);
    repo.config = {'provider': 'openai', 'model': 'gpt-4o', 'api_key': 'sk-test'};
    final controller = AgentController(repo);

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: AgentSettingsSection(controller: controller))),
    );
    await tester.pumpAndSettle();

    expect(find.text('gpt-4o'), findsOneWidget);
    expect(find.text('sk-test'), findsOneWidget);
    expect(find.text('OpenAI'), findsOneWidget);
  });

  testWidgets('saving calls setConfig with the edited values', (tester) async {
    final repo = FakeAgentRepository([]);
    repo.config = {'provider': 'ollama', 'model': 'llama3', 'api_key': ''};
    final controller = AgentController(repo);

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: AgentSettingsSection(controller: controller))),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.text('llama3'), 'qwen2.5:3b');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(repo.setConfigCalls.single['model'], 'qwen2.5:3b');
    expect(repo.setConfigCalls.single['provider'], 'ollama');
  });

  testWidgets('changing the port shows the restart note', (tester) async {
    final repo = FakeAgentRepository([]);
    repo.config = {'provider': 'ollama', 'model': 'llama3', 'api_key': ''};
    final controller = AgentController(repo);

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: AgentSettingsSection(controller: controller))),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('takes effect on next server restart'), findsNothing);

    await tester.enterText(find.text('8765'), '9000');
    await tester.pump();

    expect(find.textContaining('takes effect on next server restart'), findsOneWidget);
  });
}

class _ThrowingConfigRepository extends FakeAgentRepository {
  _ThrowingConfigRepository() : super([]);

  @override
  Future<Map<String, dynamic>> getConfig() async {
    throw Exception('connection refused');
  }
}
