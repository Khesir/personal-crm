import 'package:crm/core/network/base_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/datasource/keep_track_datasource.dart';
import 'data/datasource/analytics_datasource.dart';
import 'data/datasource/support_datasource.dart';
import 'data/repository/keep_track_repository_impl.dart';
import 'domain/controller/keep_track_controller.dart';
import 'domain/controller/analytics_controller.dart';
import 'domain/controller/support_controller.dart';

Dio _buildBackendDio() {
  final baseUrl = dotenv.env['KEEP_TRACK_BASE_URL']!;
  final crmSecret = dotenv.env['CRM_SECRET']!;
  return BaseApi.create(baseUrl: baseUrl, crmSecret: crmSecret);
}

({
  AnnouncementsController announcements,
  ReleasesController releases,
  AnalyticsController analytics,
}) createKeepTrackControllers() {
  final backendDio = _buildBackendDio();
  final datasource = KeepTrackDatasource(backendDio);
  final repository = KeepTrackRepositoryImpl(datasource);

  final vercelToken = dotenv.env['VERCEL_TOKEN'] ?? '';
  final vercelProjectId = dotenv.env['VERCEL_PROJECT_ID'] ?? '';
  final vercelTeamId = dotenv.env['VERCEL_TEAM_ID'];
  final lemonKey = dotenv.env['LEMON_SQUEEZY_API_KEY'] ?? '';

  final vercelDio = Dio(BaseOptions(baseUrl: 'https://vercel.com/api'))
    ..interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        options.headers['Authorization'] = 'Bearer $vercelToken';
        handler.next(options);
      },
    ));

  final lemonDio = Dio(BaseOptions(baseUrl: 'https://api.lemonsqueezy.com'))
    ..interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        options.headers['Authorization'] = 'Bearer $lemonKey';
        options.headers['Accept'] = 'application/vnd.api+json';
        handler.next(options);
      },
    ));

  final analyticsDatasource = AnalyticsDatasource(
    backendDio: backendDio,
    vercelDio: vercelDio,
    lemonDio: lemonDio,
    vercelProjectId: vercelProjectId,
    vercelTeamId: vercelTeamId,
  );

  return (
    announcements: AnnouncementsController(repository),
    releases: ReleasesController(repository),
    analytics: AnalyticsController(analyticsDatasource),
  );
}

Future<SupportController> createSupportController() async {
  final backendDio = _buildBackendDio();
  final prefs = await SharedPreferences.getInstance();
  return SupportController(SupportDatasource(backendDio), prefs);
}

