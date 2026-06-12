import '../../domain/model/service_card.dart';
import '../../domain/repository/service_cards_repository.dart';
import '../datasource/service_cards_local_datasource.dart';

class ServiceCardsRepositoryImpl implements ServiceCardsRepository {
  final ServiceCardsLocalDatasource datasource;

  ServiceCardsRepositoryImpl(this.datasource);

  @override
  Future<List<ServiceCard>> getCards() async {
    final stored = datasource.read();
    return stored.map(ServiceCard.fromJson).toList();
  }

  @override
  Future<void> saveCards(List<ServiceCard> cards) async {
    await datasource.write(cards.map((c) => c.toJson()).toList());
  }
}
