import 'package:crm/core/network/base_api.dart';
import 'package:crm/features/settings/domain/model/service_card.dart';
import 'package:crm/features/settings/domain/model/service_cards_cache.dart';
import 'data/datasource/announcements_datasource.dart';
import 'data/datasource/bug_reports_datasource.dart';
import 'data/repository/announcements_repository_impl.dart';
import 'data/repository/bug_reports_repository_impl.dart';
import 'domain/controller/announcements_controller.dart';
import 'domain/controller/bug_reports_controller.dart';

String? _customUrlSecret() {
  final secret = ServiceCardsCache.instance.field(ServiceType.customUrl, 'secret');
  return secret.isEmpty ? null : secret;
}

AnnouncementsController createAnnouncementsController(String projectKey) {
  final baseUrl = ServiceCardsCache.instance.field(ServiceType.customUrl, 'baseUrl');
  final crmSecret = _customUrlSecret();
  final dio = BaseApi.create(baseUrl: baseUrl, crmSecret: crmSecret);
  final datasource = AnnouncementsDatasource(dio, projectKey);
  final repository = AnnouncementsRepositoryImpl(datasource);
  return AnnouncementsController(repository);
}

BugReportsController createBugReportsController(String projectKey) {
  final baseUrl = ServiceCardsCache.instance.field(ServiceType.customUrl, 'baseUrl');
  final crmSecret = _customUrlSecret();
  final dio = BaseApi.create(baseUrl: baseUrl, crmSecret: crmSecret);
  final datasource = BugReportsDatasource(dio, projectKey);
  final repository = BugReportsRepositoryImpl(datasource);
  return BugReportsController(repository);
}
