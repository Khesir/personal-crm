import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crm/core/theme/theme.dart';
import 'package:crm/features/settings/domain/model/health_status.dart';
import 'package:crm/features/settings/domain/model/service_card.dart';
import 'package:crm/features/settings/presentation/widget/engine_filter_chips.dart';

const _ollamaCard = ServiceCard(
  id: 'ollama-1',
  category: ServiceCategory.localLlm,
  type: ServiceType.ollama,
  name: 'Ollama',
  fields: {},
);

const _customCard = ServiceCard(
  id: 'custom-1',
  category: ServiceCategory.localLlm,
  type: ServiceType.customLocal,
  name: 'My Custom Engine',
  fields: {},
);

void main() {
  group('EngineFilterChips', () {
    testWidgets('renders "All" plus one chip per engine card with correct labels', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EngineFilterChips(
            engines: const [_ollamaCard, _customCard],
            healthStatuses: const {},
            selectedId: null,
            onSelect: (_) {},
          ),
        ),
      );

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Ollama'), findsOneWidget);
      expect(find.text('My Custom Engine'), findsOneWidget);
    });

    testWidgets('each engine chip indicator color matches its HealthStatus', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EngineFilterChips(
            engines: const [_ollamaCard, _customCard],
            healthStatuses: const {
              'ollama-1': HealthStatus.online,
              // 'custom-1' missing -> muted, same as null.
            },
            selectedId: null,
            onSelect: (_) {},
          ),
        ),
      );

      final ollamaDot = tester.widget<Container>(
        find.byKey(const ValueKey('engine-chip-dot-ollama-1')),
      );
      final customDot = tester.widget<Container>(
        find.byKey(const ValueKey('engine-chip-dot-custom-1')),
      );

      final ollamaDecoration = ollamaDot.decoration as BoxDecoration;
      final customDecoration = customDot.decoration as BoxDecoration;

      expect(ollamaDecoration.color, AppColors.success);
      expect(customDecoration.color, AppColors.textMuted);
    });

    testWidgets('each HealthStatus maps to the same color as _StatusBadge', (tester) async {
      const statuses = {
        'a': HealthStatus.online,
        'b': HealthStatus.offline,
        'c': HealthStatus.error,
        'd': HealthStatus.checking,
      };

      final cards = [
        for (final id in statuses.keys)
          ServiceCard(
            id: id,
            category: ServiceCategory.localLlm,
            type: ServiceType.ollama,
            name: 'Engine $id',
            fields: const {},
          ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: EngineFilterChips(
            engines: cards,
            healthStatuses: statuses,
            selectedId: null,
            onSelect: (_) {},
          ),
        ),
      );

      Color colorFor(String id) {
        final dot = tester.widget<Container>(find.byKey(ValueKey('engine-chip-dot-$id')));
        return (dot.decoration as BoxDecoration).color!;
      }

      expect(colorFor('a'), AppColors.success);
      expect(colorFor('b'), AppColors.textMuted);
      expect(colorFor('c'), AppColors.error);
      expect(colorFor('d'), AppColors.warning);
    });

    testWidgets('tapping an unselected engine chip calls onSelect(card.id)', (tester) async {
      String? selected = 'unset';

      await tester.pumpWidget(
        MaterialApp(
          home: EngineFilterChips(
            engines: const [_ollamaCard, _customCard],
            healthStatuses: const {},
            selectedId: null,
            onSelect: (id) => selected = id,
          ),
        ),
      );

      await tester.tap(find.text('Ollama'));
      await tester.pump();

      expect(selected, 'ollama-1');
    });

    testWidgets('tapping the selected engine chip calls onSelect(null)', (tester) async {
      String? selected = 'unset';

      await tester.pumpWidget(
        MaterialApp(
          home: EngineFilterChips(
            engines: const [_ollamaCard, _customCard],
            healthStatuses: const {},
            selectedId: 'ollama-1',
            onSelect: (id) => selected = id,
          ),
        ),
      );

      await tester.tap(find.text('Ollama'));
      await tester.pump();

      expect(selected, isNull);
    });

    testWidgets('tapping "All" calls onSelect(null)', (tester) async {
      String? selected = 'unset';

      await tester.pumpWidget(
        MaterialApp(
          home: EngineFilterChips(
            engines: const [_ollamaCard, _customCard],
            healthStatuses: const {},
            selectedId: 'ollama-1',
            onSelect: (id) => selected = id,
          ),
        ),
      );

      await tester.tap(find.text('All'));
      await tester.pump();

      expect(selected, isNull);
    });
  });
}
