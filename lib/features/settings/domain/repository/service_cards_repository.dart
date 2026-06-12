import '../model/service_card.dart';

abstract class ServiceCardsRepository {
  Future<List<ServiceCard>> getCards();

  Future<void> saveCards(List<ServiceCard> cards);
}
