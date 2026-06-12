import '../model/health_status.dart';
import '../model/service_card.dart';

abstract class HealthCheckRepository {
  Future<HealthStatus> check(ServiceCard card);
}
