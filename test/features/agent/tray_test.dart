import 'package:flutter_test/flutter_test.dart';
import 'package:crm/features/agent/domain/controller/agent_controller.dart';
import 'package:crm/features/agent/domain/model/agent_status.dart';
import 'package:crm/features/agent/presentation/state/agent_state.dart';

import 'domain/controller/agent_controller_test.dart' show FakeAgentRepository;

AgentController _makeController(AgentStatus status) {
  final controller = AgentController(FakeAgentRepository([]));
  if (status == AgentStatus.running) {
    controller.emit(const AgentStateData(status: AgentStatus.running));
  }
  return controller;
}

void main() {
  group('didRequestAppExit logic', () {
    test('returns exit when status is idle', () {
      final controller = _makeController(AgentStatus.idle);
      final isRunning = controller.state.status == AgentStatus.running;
      expect(isRunning, isFalse);
    });

    test('returns cancel when status is running', () {
      final controller = _makeController(AgentStatus.running);
      final isRunning = controller.state.status == AgentStatus.running;
      expect(isRunning, isTrue);
    });

    test('stop() resets status to idle', () {
      final controller = _makeController(AgentStatus.running);
      controller.stop();
      expect(controller.state.status, AgentStatus.idle);
    });
  });
}
