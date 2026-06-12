import 'package:flutter_test/flutter_test.dart';
import 'package:crm/features/settings/domain/model/service_card.dart';

void main() {
  group('ServiceCard', () {
    test('toJson/fromJson round trip preserves fields map and disabledModels', () {
      const card = ServiceCard(
        id: 'n8n-1',
        category: ServiceCategory.services,
        type: ServiceType.n8n,
        name: 'Local n8n',
        fields: {'baseUrl': 'http://localhost:5678'},
        enabled: true,
        isDefault: true,
        disabledModels: ['llama3:8b', 'qwen2.5:7b'],
      );

      final json = card.toJson();
      final restored = ServiceCard.fromJson(json);

      expect(restored.id, card.id);
      expect(restored.category, card.category);
      expect(restored.type, card.type);
      expect(restored.name, card.name);
      expect(restored.fields, card.fields);
      expect(restored.enabled, card.enabled);
      expect(restored.isDefault, card.isDefault);
      expect(restored.disabledModels, card.disabledModels);
    });

    test('fromJson defaults enabled/isDefault/disabledModels when absent', () {
      final json = {
        'id': 'custom-1',
        'category': 'services',
        'type': 'customUrl',
        'name': 'DevCenter',
        'fields': {'baseUrl': 'http://localhost:3000'},
      };

      final card = ServiceCard.fromJson(json);

      expect(card.enabled, isTrue);
      expect(card.isDefault, isFalse);
      expect(card.disabledModels, isEmpty);
    });

    test('copyWith overrides only the provided fields', () {
      const card = ServiceCard(
        id: 'n8n-1',
        category: ServiceCategory.services,
        type: ServiceType.n8n,
        name: 'Local n8n',
        fields: {'baseUrl': 'http://localhost:5678'},
        enabled: true,
        isDefault: false,
        disabledModels: [],
      );

      final updated = card.copyWith(name: 'Renamed', isDefault: true);

      expect(updated.id, card.id);
      expect(updated.category, card.category);
      expect(updated.type, card.type);
      expect(updated.name, 'Renamed');
      expect(updated.fields, card.fields);
      expect(updated.enabled, card.enabled);
      expect(updated.isDefault, isTrue);
      expect(updated.disabledModels, card.disabledModels);
    });
  });

  group('ServiceCategory', () {
    test('value/fromValue round trip for all categories', () {
      for (final category in ServiceCategory.values) {
        expect(ServiceCategory.fromValue(category.value), category);
      }
    });
  });

  group('ServiceType', () {
    test('value/fromValue round trip for all six types', () {
      for (final type in ServiceType.values) {
        expect(ServiceType.fromValue(type.value), type);
      }
      expect(ServiceType.values, hasLength(6));
    });
  });
}
