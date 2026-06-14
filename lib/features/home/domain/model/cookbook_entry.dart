import 'package:crm/features/settings/domain/model/model_fit_result.dart';
import 'package:crm/features/settings/domain/model/service_card.dart';

/// A single chat-capable model exposed by an enabled Local LLM service card,
/// aggregated into the Home chat "cookbook" of selectable models.
class CookbookEntry {
  final String cardId;
  final String cardName;
  final ServiceType cardType;
  final String model;
  final bool supportsTools;

  /// How well this model fits the locally detected hardware, computed from
  /// the model name's parsed parameter count/quantization — see issue 018.
  /// Always null for API LLM entries, or if the model name doesn't parse or
  /// hardware detection is unavailable.
  final ModelFitResult? fitResult;

  const CookbookEntry({
    required this.cardId,
    required this.cardName,
    required this.cardType,
    required this.model,
    this.supportsTools = true,
    this.fitResult,
  });

  CookbookEntry copyWith({
    String? cardId,
    String? cardName,
    ServiceType? cardType,
    String? model,
    bool? supportsTools,
    ModelFitResult? fitResult,
  }) {
    return CookbookEntry(
      cardId: cardId ?? this.cardId,
      cardName: cardName ?? this.cardName,
      cardType: cardType ?? this.cardType,
      model: model ?? this.model,
      supportsTools: supportsTools ?? this.supportsTools,
      fitResult: fitResult ?? this.fitResult,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CookbookEntry &&
        other.cardId == cardId &&
        other.cardName == cardName &&
        other.cardType == cardType &&
        other.model == model &&
        other.supportsTools == supportsTools &&
        other.fitResult == fitResult;
  }

  @override
  int get hashCode => Object.hash(cardId, cardName, cardType, model, supportsTools, fitResult);

  @override
  String toString() => 'CookbookEntry(cardId: $cardId, cardName: $cardName, '
      'cardType: $cardType, model: $model, supportsTools: $supportsTools, '
      'fitResult: $fitResult)';
}

/// Returns the entry in [entries] with the highest [CookbookEntry.fitResult]
/// score — used to default a new conversation's model selection to the local
/// model that best fits the user's hardware (see issue 020).
///
/// Entries with a null [CookbookEntry.fitResult] (API entries, or local
/// entries whose name didn't parse / no detected hardware) are not
/// considered. Returns null if no entry qualifies, so callers can fall back
/// to their existing default-entry behavior.
CookbookEntry? recommendedCookbookEntry(List<CookbookEntry> entries) {
  CookbookEntry? best;
  for (final entry in entries) {
    final score = entry.fitResult?.score;
    if (score == null) continue;
    final bestScore = best?.fitResult?.score;
    if (bestScore == null || score > bestScore) best = entry;
  }
  return best;
}
