import 'package:flutter_test/flutter_test.dart';
import 'package:crm/features/agent/domain/service/agent_server_manager.dart';

void main() {
  test('AgentServerManager instantiates without error', () {
    final manager = AgentServerManager();
    expect(manager.isReady, isFalse);
    expect(manager.hasFailed, isFalse);
  });
}
