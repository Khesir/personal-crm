import 'package:flutter_test/flutter_test.dart';
import 'package:crm/features/settings/domain/model/service_card.dart';
import 'package:crm/features/settings/domain/model/service_cards_cache.dart';

void main() {
  group('ServiceCardsCache', () {
    setUp(() {
      // Reset the singleton's state before each test by loading an empty list.
      ServiceCardsCache.instance.load(const []);
    });

    test('field() falls back to kServiceTypeDefaults when no cards are loaded', () {
      expect(
        ServiceCardsCache.instance.field(ServiceType.ollama, 'baseUrl'),
        'http://localhost:11434',
      );
      expect(
        ServiceCardsCache.instance.field(ServiceType.n8n, 'baseUrl'),
        'http://localhost:5678',
      );
      expect(
        ServiceCardsCache.instance.field(ServiceType.customUrl, 'baseUrl'),
        'http://localhost:3000',
      );
      expect(
        ServiceCardsCache.instance.field(ServiceType.customUrl, 'secret'),
        '',
      );
    });

    test('field() returns an unknown key/type combo as empty string when no default exists', () {
      expect(
        ServiceCardsCache.instance.field(ServiceType.claudeAnthropic, 'apiKey'),
        '',
      );
    });

    test('field() returns the value from the default card of a back-compat type', () {
      final cards = [
        const ServiceCard(
          id: 'n8n-1',
          category: ServiceCategory.services,
          type: ServiceType.n8n,
          name: 'n8n',
          fields: {'baseUrl': 'http://example.com:5678'},
          isDefault: true,
        ),
      ];

      ServiceCardsCache.instance.load(cards);

      expect(
        ServiceCardsCache.instance.field(ServiceType.n8n, 'baseUrl'),
        'http://example.com:5678',
      );
    });

    test('field() returns the value from the only card of a back-compat type when none is marked default', () {
      final cards = [
        const ServiceCard(
          id: 'ollama-1',
          category: ServiceCategory.localLlm,
          type: ServiceType.ollama,
          name: 'Ollama',
          fields: {'baseUrl': 'http://example.com:11434'},
          isDefault: false,
        ),
      ];

      ServiceCardsCache.instance.load(cards);

      expect(
        ServiceCardsCache.instance.field(ServiceType.ollama, 'baseUrl'),
        'http://example.com:11434',
      );
    });

    test('field() prefers the default card when multiple cards of the same type exist', () {
      final cards = [
        const ServiceCard(
          id: 'custom-1',
          category: ServiceCategory.services,
          type: ServiceType.customUrl,
          name: 'First',
          fields: {'baseUrl': 'http://first.example.com'},
          isDefault: false,
        ),
        const ServiceCard(
          id: 'custom-2',
          category: ServiceCategory.services,
          type: ServiceType.customUrl,
          name: 'Second',
          fields: {'baseUrl': 'http://second.example.com', 'secret': 'shh'},
          isDefault: true,
        ),
      ];

      ServiceCardsCache.instance.load(cards);

      expect(
        ServiceCardsCache.instance.field(ServiceType.customUrl, 'baseUrl'),
        'http://second.example.com',
      );
      expect(
        ServiceCardsCache.instance.field(ServiceType.customUrl, 'secret'),
        'shh',
      );
    });

    test('field() falls back to kServiceTypeDefaults when the card exists but the field key is missing', () {
      final cards = [
        const ServiceCard(
          id: 'custom-1',
          category: ServiceCategory.services,
          type: ServiceType.customUrl,
          name: 'Custom',
          fields: {'baseUrl': 'http://example.com:3000'},
          isDefault: true,
        ),
      ];

      ServiceCardsCache.instance.load(cards);

      // 'secret' field not present on the card -> falls back to default ''.
      expect(
        ServiceCardsCache.instance.field(ServiceType.customUrl, 'secret'),
        '',
      );
    });

    test('load() replaces previously cached values', () {
      ServiceCardsCache.instance.load([
        const ServiceCard(
          id: 'n8n-1',
          category: ServiceCategory.services,
          type: ServiceType.n8n,
          name: 'n8n',
          fields: {'baseUrl': 'http://first.example.com'},
          isDefault: true,
        ),
      ]);
      expect(
        ServiceCardsCache.instance.field(ServiceType.n8n, 'baseUrl'),
        'http://first.example.com',
      );

      ServiceCardsCache.instance.load([
        const ServiceCard(
          id: 'n8n-2',
          category: ServiceCategory.services,
          type: ServiceType.n8n,
          name: 'n8n',
          fields: {'baseUrl': 'http://second.example.com'},
          isDefault: true,
        ),
      ]);
      expect(
        ServiceCardsCache.instance.field(ServiceType.n8n, 'baseUrl'),
        'http://second.example.com',
      );
    });
  });
}
