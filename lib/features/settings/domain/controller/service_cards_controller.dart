import 'dart:async';

import 'package:crm/core/state/state.dart';
import '../model/health_status.dart';
import '../model/service_card.dart';
import '../model/service_cards_cache.dart';
import '../repository/health_check_repository.dart';
import '../repository/service_cards_repository.dart';

class ServiceCardsController extends StreamState<AsyncState<List<ServiceCard>>> {
  final ServiceCardsRepository repository;
  final HealthCheckRepository healthCheckRepository;

  final _healthController = StreamController<Map<String, HealthStatus>>.broadcast();
  Map<String, HealthStatus> _healthStatuses = {};

  ServiceCardsController(this.repository, this.healthCheckRepository)
      : super(const AsyncLoading());

  static const _backCompatTypes = {
    ServiceType.ollama,
    ServiceType.n8n,
    ServiceType.customUrl,
  };

  /// Per-card health status, keyed by card id.
  Map<String, HealthStatus> get healthStatuses => Map.unmodifiable(_healthStatuses);

  /// Broadcasts the full health status map whenever any card's status changes.
  Stream<Map<String, HealthStatus>> get healthStream => _healthController.stream;

  void _emitHealth(String cardId, HealthStatus status) {
    _healthStatuses = {..._healthStatuses, cardId: status};
    if (!_healthController.isClosed) {
      _healthController.add(Map.unmodifiable(_healthStatuses));
    }
  }

  Future<void> checkHealth(ServiceCard card) async {
    _emitHealth(card.id, HealthStatus.checking);
    final status = await healthCheckRepository.check(card);
    _emitHealth(card.id, status);
  }

  Future<void> checkAllHealth() async {
    final current = data ?? [];
    await Future.wait(current.map(checkHealth));
  }

  @override
  void dispose() {
    _healthController.close();
    super.dispose();
  }

  Future<void> load() => execute(() => repository.getCards());

  Future<void> addCard(ServiceCard card) async {
    final current = data ?? [];

    var toAdd = card;
    if (_backCompatTypes.contains(card.type) &&
        !current.any((c) => c.type == card.type)) {
      toAdd = card.copyWith(isDefault: true);
    }

    final updated = [...current, toAdd];
    await execute(() async {
      await repository.saveCards(updated);
      ServiceCardsCache.instance.load(updated);
      return updated;
    });
  }

  Future<void> updateCard(ServiceCard card) async {
    final current = data ?? [];
    final updated = [
      for (final existing in current)
        if (existing.id == card.id) card else existing,
    ];
    await execute(() async {
      await repository.saveCards(updated);
      ServiceCardsCache.instance.load(updated);
      return updated;
    });
  }

  Future<void> removeCard(String id) async {
    final current = data ?? [];
    final updated = current.where((c) => c.id != id).toList();
    await execute(() async {
      await repository.saveCards(updated);
      ServiceCardsCache.instance.load(updated);
      return updated;
    });
  }

  Future<void> toggleCardEnabled(String cardId) async {
    final current = data ?? [];
    final updated = [
      for (final card in current)
        if (card.id == cardId) card.copyWith(enabled: !card.enabled) else card,
    ];
    await execute(() async {
      await repository.saveCards(updated);
      ServiceCardsCache.instance.load(updated);
      return updated;
    });
  }

  Future<void> toggleModelEnabled(String cardId, String modelName) async {
    final current = data ?? [];
    final updated = [
      for (final card in current)
        if (card.id == cardId)
          card.copyWith(
            disabledModels: card.disabledModels.contains(modelName)
                ? card.disabledModels.where((m) => m != modelName).toList()
                : [...card.disabledModels, modelName],
          )
        else
          card,
    ];
    await execute(() async {
      await repository.saveCards(updated);
      return updated;
    });
  }

  Future<void> setDefault(ServiceType type, String cardId) async {
    final current = data ?? [];
    final updated = [
      for (final card in current)
        if (card.type == type)
          card.copyWith(isDefault: card.id == cardId)
        else
          card,
    ];
    await execute(() async {
      await repository.saveCards(updated);
      ServiceCardsCache.instance.load(updated);
      return updated;
    });
  }
}
