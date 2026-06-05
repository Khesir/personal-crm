import 'package:dio/dio.dart';

class BaseApi {
  static Dio create({
    required String baseUrl,
    String? crmSecret,
    Duration timeout = const Duration(seconds: 10),
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: timeout,
        receiveTimeout: timeout,
        contentType: 'application/json',
      ),
    );

    if (crmSecret != null) {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            options.headers['x-crm-secret'] = crmSecret;
            handler.next(options);
          },
        ),
      );
    }

    return dio;
  }
}
