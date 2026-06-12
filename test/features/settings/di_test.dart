import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crm/core/config/data_namespace.dart';
import 'package:crm/features/settings/data/datasource/service_cards_local_datasource.dart';
import 'package:crm/features/settings/data/repository/service_cards_repository_impl.dart';
import 'package:crm/features/settings/di.dart';
import 'package:crm/features/settings/domain/model/service_cards_cache.dart';

const _envPrefix = '$kDataNamespace.env_override_';

void main() {
  group('initServiceCardsCache', () {
    setUp(() {
      // Reset the singleton's state before each test.
      ServiceCardsCache.instance.load(const []);
    });

    test(
      'does not auto-create cards from old env_override_ keys, even when no card list exists yet',
      () async {
        SharedPreferences.setMockInitialValues({
          '${_envPrefix}OLLAMA_BASE_URL': 'http://ollama.example.com:11434',
          '${_envPrefix}N8N_BASE_URL': 'http://n8n.example.com:5678',
          '${_envPrefix}DEVCENTER_BACKEND_URL': 'http://devcenter.example.com:3000',
          '${_envPrefix}CRM_SECRET': 'top-secret',
          '${_envPrefix}CLAUDE_API_KEY': 'sk-ant-12345',
        });
        final prefs = await SharedPreferences.getInstance();

        await initServiceCardsCache(prefs);

        final repository = ServiceCardsRepositoryImpl(ServiceCardsLocalDatasource(prefs));
        final cards = await repository.getCards();

        expect(cards, isEmpty);
      },
    );

    test('is a no-op on a fresh install with no card list and no env_override_ keys', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await initServiceCardsCache(prefs);

      final repository = ServiceCardsRepositoryImpl(ServiceCardsLocalDatasource(prefs));
      final cards = await repository.getCards();

      expect(cards, isEmpty);
    });
  });
}
