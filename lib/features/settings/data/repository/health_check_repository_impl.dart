import 'package:dio/dio.dart';

import '../../domain/model/health_status.dart';
import '../../domain/model/service_card.dart';
import '../../domain/repository/health_check_repository.dart';

const _kHealthCheckTimeout = Duration(seconds: 3);

class HealthCheckRepositoryImpl implements HealthCheckRepository {
  @override
  Future<HealthStatus> check(ServiceCard card) async {
    switch (card.type) {
      case ServiceType.n8n:
      case ServiceType.customUrl:
      case ServiceType.searxng:
        return _checkUniformGet(card);
      case ServiceType.ollama:
        return _checkStatusAware(card, '/api/tags');
      case ServiceType.customLocal:
        return _checkStatusAware(card, '/v1/models');
      case ServiceType.claudeAnthropic:
        final apiKey = card.fields['apiKey'];
        if (apiKey == null || apiKey.isEmpty) return HealthStatus.offline;
        return _checkStatusAware(
          card,
          '',
          url: 'https://api.anthropic.com/v1/models',
          headers: {
            'x-api-key': apiKey,
            'anthropic-version': '2023-06-01',
          },
        );
      case ServiceType.groq:
      case ServiceType.gemini:
      case ServiceType.openRouter:
      case ServiceType.openai:
      case ServiceType.deepSeek:
      case ServiceType.mistral:
      case ServiceType.nvidia:
      case ServiceType.openCodeZen:
      case ServiceType.customApi:
        final baseUrl = card.fields['baseUrl'];
        final apiKey = card.fields['apiKey'];
        if (baseUrl == null || baseUrl.isEmpty) return HealthStatus.offline;
        if (apiKey == null || apiKey.isEmpty) return HealthStatus.offline;
        return _checkStatusAware(
          card,
          '/v1/models',
          headers: {'Authorization': 'Bearer $apiKey'},
        );
    }
  }

  /// `GET {baseUrl}` with a short timeout. Any HTTP response (including
  /// 4xx/5xx) counts as online; connection failure/timeout counts as offline.
  Future<HealthStatus> _checkUniformGet(ServiceCard card) async {
    final baseUrl = card.fields['baseUrl'];
    if (baseUrl == null || baseUrl.isEmpty) return HealthStatus.offline;

    final dio = Dio(
      BaseOptions(
        connectTimeout: _kHealthCheckTimeout,
        receiveTimeout: _kHealthCheckTimeout,
      ),
    );

    try {
      await dio.get(baseUrl);
      return HealthStatus.online;
    } on DioException catch (e) {
      if (e.response != null) return HealthStatus.online;
      return HealthStatus.offline;
    } catch (_) {
      return HealthStatus.offline;
    }
  }

  /// `GET {baseUrl}{path}` (or `GET {url}` if provided, overriding `baseUrl`)
  /// with a short timeout and optional extra `headers`. A 2xx response
  /// counts as online; connection failure/timeout counts as offline; any
  /// other HTTP response (4xx/5xx) counts as error.
  Future<HealthStatus> _checkStatusAware(
    ServiceCard card,
    String path, {
    String? url,
    Map<String, String>? headers,
  }) async {
    final target = url ?? card.fields['baseUrl'];
    if (target == null || target.isEmpty) return HealthStatus.offline;

    final dio = Dio(
      BaseOptions(
        connectTimeout: _kHealthCheckTimeout,
        receiveTimeout: _kHealthCheckTimeout,
        headers: headers,
      ),
    );

    try {
      await dio.get(url ?? '$target$path');
      return HealthStatus.online;
    } on DioException catch (e) {
      if (e.response != null) return HealthStatus.error;
      return HealthStatus.offline;
    } catch (_) {
      return HealthStatus.offline;
    }
  }
}
