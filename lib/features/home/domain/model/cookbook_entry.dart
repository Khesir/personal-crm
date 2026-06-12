import 'package:crm/features/settings/domain/model/service_card.dart';

/// A single chat-capable model exposed by an enabled Local LLM service card,
/// aggregated into the Home chat "cookbook" of selectable models.
class CookbookEntry {
  final String cardId;
  final String cardName;
  final ServiceType cardType;
  final String model;

  const CookbookEntry({
    required this.cardId,
    required this.cardName,
    required this.cardType,
    required this.model,
  });

  CookbookEntry copyWith({
    String? cardId,
    String? cardName,
    ServiceType? cardType,
    String? model,
  }) {
    return CookbookEntry(
      cardId: cardId ?? this.cardId,
      cardName: cardName ?? this.cardName,
      cardType: cardType ?? this.cardType,
      model: model ?? this.model,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CookbookEntry &&
        other.cardId == cardId &&
        other.cardName == cardName &&
        other.cardType == cardType &&
        other.model == model;
  }

  @override
  int get hashCode => Object.hash(cardId, cardName, cardType, model);

  @override
  String toString() => 'CookbookEntry(cardId: $cardId, cardName: $cardName, '
      'cardType: $cardType, model: $model)';
}
