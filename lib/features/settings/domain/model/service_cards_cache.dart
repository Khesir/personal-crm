import 'service_card.dart';

/// Hardcoded fallback values used when no [ServiceCard] of a given type/field
/// exists yet (e.g. fresh install before any cards have been configured).
///
/// Keys are `'<ServiceType.value>.<fieldKey>'`.
const Map<String, String> kServiceTypeDefaults = {
  'ollama.baseUrl': 'http://localhost:11434',
  'n8n.baseUrl': 'http://localhost:5678',
  'customUrl.baseUrl': 'http://localhost:3000',
  'customUrl.secret': '',
  'searxng.baseUrl': 'http://localhost:8080',
};

/// Service types whose default-or-only card is indexed into [ServiceCardsCache]
/// for synchronous lookups by DI factories at startup.
const _kBackCompatTypes = {
  ServiceType.ollama,
  ServiceType.n8n,
  ServiceType.customUrl,
  ServiceType.searxng,
};

/// In-memory, synchronous cache of the back-compat service cards' field
/// values, populated once at startup (after SharedPreferences is ready) and
/// refreshed whenever Settings saves a card.
///
/// This lets DI factories that must remain synchronous (e.g. building a
/// [Dio] client) read configured base URLs/secrets without awaiting
/// SharedPreferences on every call.
class ServiceCardsCache {
  ServiceCardsCache._();

  static final ServiceCardsCache instance = ServiceCardsCache._();

  Map<ServiceType, Map<String, String>> _fieldsByType = {};

  /// Populates the cache from [cards], indexing the default-or-only card per
  /// back-compat type ([ServiceType.ollama], [ServiceType.n8n],
  /// [ServiceType.customUrl]). Replaces any previously cached values.
  void load(List<ServiceCard> cards) {
    final fieldsByType = <ServiceType, Map<String, String>>{};

    for (final type in _kBackCompatTypes) {
      final candidates = cards.where((c) => c.type == type).toList();
      if (candidates.isEmpty) continue;

      final selected = candidates.firstWhere(
        (c) => c.isDefault,
        orElse: () => candidates.first,
      );

      fieldsByType[type] = selected.fields;
    }

    _fieldsByType = fieldsByType;
  }

  /// Returns the value of [key] from the cached default-or-only card of
  /// [type], falling back to [kServiceTypeDefaults] (or `''` if no default
  /// is defined either).
  String field(ServiceType type, String key) {
    final cached = _fieldsByType[type]?[key];
    if (cached != null) return cached;

    return kServiceTypeDefaults['${type.value}.$key'] ?? '';
  }
}
