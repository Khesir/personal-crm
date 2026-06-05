import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:crm/features/portfolio/data/datasource/portfolio_datasource.dart';
import 'package:crm/features/portfolio/data/repository/portfolio_repository_impl.dart';
import 'package:crm/features/portfolio/domain/controller/portfolio_content_controller.dart';

String _resolveBaseUrl() {
  final raw = (dotenv.env['PORTFOLIO_BASE_URL'] ?? 'https://personal-backend-psi.vercel.app')
      .trimRight()
      .replaceAll(RegExp(r'/+$'), '');
  final withApi = raw.endsWith('/api') ? raw : '$raw/api';
  return '$withApi/';
}

Dio _buildPortfolioDio() {
  final baseUrl = _resolveBaseUrl();
  return Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      contentType: 'application/json',
    ),
  )..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers['x-crm-secret'] = dotenv.env['CRM_SECRET'] ?? '';
          handler.next(options);
        },
      ),
    );
}

({
  PortfolioBlogController blogs,
  PortfolioProjectController projects,
  PortfolioExperienceController experiences,
  PortfolioPostController posts,
  PortfolioHomeConfigController homeConfig,
  PortfolioAboutConfigController aboutConfig,
  PortfolioServicesConfigController servicesConfig,
}) createPortfolioControllers() {
  final dio = _buildPortfolioDio();
  final datasource = PortfolioDatasource(dio);
  final repository = PortfolioRepositoryImpl(datasource);

  return (
    blogs: PortfolioBlogController(repository),
    projects: PortfolioProjectController(repository),
    experiences: PortfolioExperienceController(repository),
    posts: PortfolioPostController(repository),
    homeConfig: PortfolioHomeConfigController(datasource),
    aboutConfig: PortfolioAboutConfigController(datasource),
    servicesConfig: PortfolioServicesConfigController(datasource),
  );
}
