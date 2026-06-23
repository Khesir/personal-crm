import 'package:flutter_test/flutter_test.dart';
import 'package:crm/features/agent/data/datasource/agent_datasource.dart';
import 'package:crm/features/agent/data/repository/agent_repository_impl.dart';
import 'package:crm/features/agent/domain/model/agent_chat_message.dart';

class _FakeDatasource extends AgentDatasource {
  List<Map<String, dynamic>> sessionsResponse = [];
  List<Map<String, dynamic>> messagesResponse = [];
  Map<String, dynamic> modelsResponse = {'provider': 'ollama', 'models': []};

  @override
  Future<List<Map<String, dynamic>>> listSessions() async => sessionsResponse;

  @override
  Future<List<Map<String, dynamic>>> getSessionMessages(String sessionId) async => messagesResponse;

  @override
  Future<Map<String, dynamic>> listModels() async => modelsResponse;
}

void main() {
  test('maps raw session JSON to AgentSessionSummary correctly', () async {
    final ds = _FakeDatasource();
    ds.sessionsResponse = [
      {
        'id': 's1',
        'title': 'Debug NullPointer',
        'created_at': '2026-06-20T10:00:00.000Z',
        'updated_at': '2026-06-21T12:30:00.000Z',
      },
    ];
    final repo = AgentRepositoryImpl(ds);

    final sessions = await repo.listSessions();

    expect(sessions.single.id, 's1');
    expect(sessions.single.title, 'Debug NullPointer');
    expect(sessions.single.createdAt, DateTime.parse('2026-06-20T10:00:00.000Z'));
    expect(sessions.single.updatedAt, DateTime.parse('2026-06-21T12:30:00.000Z'));
  });

  test('maps raw messages JSON to AgentChatMessage with correct role enum', () async {
    final ds = _FakeDatasource();
    ds.messagesResponse = [
      {'role': 'user', 'content': 'Hi'},
      {'role': 'assistant', 'content': 'Hello there'},
    ];
    final repo = AgentRepositoryImpl(ds);

    final messages = await repo.getSessionMessages('s1');

    expect(messages[0].role, AgentChatRole.user);
    expect(messages[0].content, 'Hi');
    expect(messages[1].role, AgentChatRole.assistant);
    expect(messages[1].content, 'Hello there');
  });

  test('maps raw models JSON to AgentModelsResult', () async {
    final ds = _FakeDatasource();
    ds.modelsResponse = {
      'provider': 'ollama',
      'models': [
        {'name': 'llama3.2', 'parameter_size': '3.2B'},
        {'name': 'qwen2.5:3b', 'parameter_size': '3.1B'},
      ],
    };
    final repo = AgentRepositoryImpl(ds);

    final result = await repo.listModels();

    expect(result.provider, 'ollama');
    expect(result.models.length, 2);
    expect(result.models[0].name, 'llama3.2');
    expect(result.models[0].parameterSize, '3.2B');
  });
}
