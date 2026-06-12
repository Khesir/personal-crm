import 'package:flutter_test/flutter_test.dart';
import 'package:crm/core/state/state.dart';
import 'package:crm/features/settings/domain/controller/service_cards_controller.dart';
import 'package:crm/features/settings/domain/model/health_status.dart';
import 'package:crm/features/settings/domain/model/service_card.dart';
import 'package:crm/features/settings/domain/repository/health_check_repository.dart';
import 'package:crm/features/settings/domain/repository/service_cards_repository.dart';

class FakeServiceCardsRepository implements ServiceCardsRepository {
  List<ServiceCard> stored;

  FakeServiceCardsRepository([List<ServiceCard>? initial]) : stored = initial ?? [];

  @override
  Future<List<ServiceCard>> getCards() async => List.unmodifiable(stored);

  @override
  Future<void> saveCards(List<ServiceCard> cards) async {
    stored = List.of(cards);
  }
}

class FakeHealthCheckRepository implements HealthCheckRepository {
  final Map<String, HealthStatus> resultsByCardId;
  final HealthStatus fallback;
  final List<ServiceCard> checkedCards = [];

  FakeHealthCheckRepository({
    this.resultsByCardId = const {},
    this.fallback = HealthStatus.online,
  });

  @override
  Future<HealthStatus> check(ServiceCard card) async {
    checkedCards.add(card);
    return resultsByCardId[card.id] ?? fallback;
  }
}

ServiceCard _n8nCard({String id = 'n8n-1', String name = 'Local n8n', bool isDefault = false}) {
  return ServiceCard(
    id: id,
    category: ServiceCategory.services,
    type: ServiceType.n8n,
    name: name,
    fields: const {'baseUrl': 'http://localhost:5678'},
    isDefault: isDefault,
  );
}

void main() {
  group('ServiceCardsController', () {
    test('load() populates state with cards from the repository', () async {
      final repo = FakeServiceCardsRepository([_n8nCard(isDefault: true)]);
      final controller = ServiceCardsController(repo, FakeHealthCheckRepository());

      await controller.load();

      expect(controller.data, hasLength(1));
      expect(controller.data!.first.id, 'n8n-1');

      controller.dispose();
    });

    test('addCard appends a card and persists it via the repository', () async {
      final repo = FakeServiceCardsRepository();
      final controller = ServiceCardsController(repo, FakeHealthCheckRepository());
      await controller.load();

      await controller.addCard(_n8nCard(id: 'n8n-1'));

      expect(controller.data, hasLength(1));
      expect(controller.data!.first.id, 'n8n-1');
      expect(repo.stored, hasLength(1));
      expect(repo.stored.first.id, 'n8n-1');

      controller.dispose();
    });

    test('addCard forces isDefault true for the first card of a back-compat type', () async {
      final repo = FakeServiceCardsRepository();
      final controller = ServiceCardsController(repo, FakeHealthCheckRepository());
      await controller.load();

      await controller.addCard(_n8nCard(id: 'n8n-1', isDefault: false));

      expect(controller.data!.first.isDefault, isTrue);

      controller.dispose();
    });

    test('addCard does not force isDefault for the second card of the same back-compat type', () async {
      final repo = FakeServiceCardsRepository();
      final controller = ServiceCardsController(repo, FakeHealthCheckRepository());
      await controller.load();

      await controller.addCard(_n8nCard(id: 'n8n-1'));
      await controller.addCard(_n8nCard(id: 'n8n-2', name: 'Second n8n', isDefault: true));

      final second = controller.data!.firstWhere((c) => c.id == 'n8n-2');
      expect(second.isDefault, isTrue);

      // Passing isDefault: false for the second card should be respected (not forced true).
      await controller.removeCard('n8n-2');
      await controller.addCard(_n8nCard(id: 'n8n-3', name: 'Third n8n', isDefault: false));
      final third = controller.data!.firstWhere((c) => c.id == 'n8n-3');
      expect(third.isDefault, isFalse);

      controller.dispose();
    });

    test('updateCard replaces the card by id and persists the change', () async {
      final repo = FakeServiceCardsRepository();
      final controller = ServiceCardsController(repo, FakeHealthCheckRepository());
      await controller.load();
      await controller.addCard(_n8nCard(id: 'n8n-1'));

      final original = controller.data!.first;
      final updated = original.copyWith(
        name: 'Renamed n8n',
        fields: {'baseUrl': 'http://localhost:9999'},
      );
      await controller.updateCard(updated);

      expect(controller.data, hasLength(1));
      expect(controller.data!.first.name, 'Renamed n8n');
      expect(controller.data!.first.fields['baseUrl'], 'http://localhost:9999');
      expect(repo.stored.first.name, 'Renamed n8n');

      controller.dispose();
    });

    test('setDefault clears isDefault on other cards of the same type and sets the target', () async {
      final repo = FakeServiceCardsRepository();
      final controller = ServiceCardsController(repo, FakeHealthCheckRepository());
      await controller.load();
      await controller.addCard(_n8nCard(id: 'n8n-1')); // auto-default
      await controller.addCard(_n8nCard(id: 'n8n-2', name: 'Second n8n', isDefault: false));

      await controller.setDefault(ServiceType.n8n, 'n8n-2');

      final first = controller.data!.firstWhere((c) => c.id == 'n8n-1');
      final second = controller.data!.firstWhere((c) => c.id == 'n8n-2');
      expect(first.isDefault, isFalse);
      expect(second.isDefault, isTrue);

      // Persisted too.
      final storedFirst = repo.stored.firstWhere((c) => c.id == 'n8n-1');
      final storedSecond = repo.stored.firstWhere((c) => c.id == 'n8n-2');
      expect(storedFirst.isDefault, isFalse);
      expect(storedSecond.isDefault, isTrue);

      controller.dispose();
    });

    test('setDefault does not affect cards of a different type', () async {
      final repo = FakeServiceCardsRepository();
      final controller = ServiceCardsController(repo, FakeHealthCheckRepository());
      await controller.load();
      await controller.addCard(_n8nCard(id: 'n8n-1')); // auto-default n8n
      await controller.addCard(ServiceCard(
        id: 'custom-1',
        category: ServiceCategory.services,
        type: ServiceType.customUrl,
        name: 'DevCenter',
        fields: const {'baseUrl': 'http://localhost:3000'},
      )); // auto-default customUrl
      await controller.addCard(_n8nCard(id: 'n8n-2', name: 'Second n8n', isDefault: false));

      await controller.setDefault(ServiceType.n8n, 'n8n-2');

      final customCard = controller.data!.firstWhere((c) => c.id == 'custom-1');
      expect(customCard.isDefault, isTrue);

      controller.dispose();
    });

    test('toggleModelEnabled toggles a model name in/out of disabledModels and persists', () async {
      final repo = FakeServiceCardsRepository();
      final controller = ServiceCardsController(repo, FakeHealthCheckRepository());
      await controller.load();
      await controller.addCard(_n8nCard(id: 'n8n-1'));

      await controller.toggleModelEnabled('n8n-1', 'llama3:8b');
      expect(controller.data!.first.disabledModels, contains('llama3:8b'));
      expect(repo.stored.first.disabledModels, contains('llama3:8b'));

      await controller.toggleModelEnabled('n8n-1', 'llama3:8b');
      expect(controller.data!.first.disabledModels, isNot(contains('llama3:8b')));
      expect(repo.stored.first.disabledModels, isNot(contains('llama3:8b')));

      controller.dispose();
    });

    test('toggleCardEnabled flips a card\'s enabled flag and persists, leaving other cards untouched', () async {
      final repo = FakeServiceCardsRepository();
      final controller = ServiceCardsController(repo, FakeHealthCheckRepository());
      await controller.load();
      await controller.addCard(_n8nCard(id: 'n8n-1'));
      await controller.addCard(_n8nCard(id: 'n8n-2', name: 'Other n8n'));

      await controller.toggleCardEnabled('n8n-1');

      final n8n1 = controller.data!.firstWhere((c) => c.id == 'n8n-1');
      final n8n2 = controller.data!.firstWhere((c) => c.id == 'n8n-2');
      expect(n8n1.enabled, isFalse);
      expect(n8n2.enabled, isTrue);
      expect(repo.stored.firstWhere((c) => c.id == 'n8n-1').enabled, isFalse);

      await controller.toggleCardEnabled('n8n-1');
      expect(controller.data!.firstWhere((c) => c.id == 'n8n-1').enabled, isTrue);

      controller.dispose();
    });

    test('persistence round trip via the fake repository', () async {
      final repo = FakeServiceCardsRepository();
      final firstController = ServiceCardsController(repo, FakeHealthCheckRepository());
      await firstController.load();
      await firstController.addCard(_n8nCard(id: 'n8n-1'));
      firstController.dispose();

      final secondController = ServiceCardsController(repo, FakeHealthCheckRepository());
      await secondController.load();

      expect(secondController.data, hasLength(1));
      expect(secondController.data!.first.id, 'n8n-1');
      expect(secondController.data!.first.isDefault, isTrue);

      secondController.dispose();
    });

    test('checkHealth emits checking then the resolved status for the target card', () async {
      final repo = FakeServiceCardsRepository();
      final healthRepo = FakeHealthCheckRepository(
        resultsByCardId: {'n8n-1': HealthStatus.online},
      );
      final controller = ServiceCardsController(repo, healthRepo);
      await controller.load();
      await controller.addCard(_n8nCard(id: 'n8n-1'));

      final emissions = <HealthStatus?>[];
      final sub = controller.healthStream.listen((statuses) {
        emissions.add(statuses['n8n-1']);
      });

      await controller.checkHealth(controller.data!.first);
      await Future<void>.delayed(Duration.zero);

      expect(emissions, containsAllInOrder([HealthStatus.checking, HealthStatus.online]));
      expect(controller.healthStatuses['n8n-1'], HealthStatus.online);

      await sub.cancel();
      controller.dispose();
    });

    test('checkAllHealth checks every current card, targeting each by id', () async {
      final repo = FakeServiceCardsRepository();
      final healthRepo = FakeHealthCheckRepository(
        resultsByCardId: {'n8n-1': HealthStatus.online, 'custom-1': HealthStatus.offline},
      );
      final controller = ServiceCardsController(repo, healthRepo);
      await controller.load();
      await controller.addCard(_n8nCard(id: 'n8n-1'));
      await controller.addCard(ServiceCard(
        id: 'custom-1',
        category: ServiceCategory.services,
        type: ServiceType.customUrl,
        name: 'DevCenter',
        fields: const {'baseUrl': 'http://localhost:3000'},
      ));

      await controller.checkAllHealth();

      expect(controller.healthStatuses['n8n-1'], HealthStatus.online);
      expect(controller.healthStatuses['custom-1'], HealthStatus.offline);
      expect(healthRepo.checkedCards.map((c) => c.id), containsAll(['n8n-1', 'custom-1']));

      controller.dispose();
    });
  });
}
