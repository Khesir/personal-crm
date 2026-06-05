import 'package:dio/dio.dart';
import '../../presentation/state/analytics_state.dart';

class AnalyticsDatasource {
  final Dio _backendDio;
  final Dio _vercelDio;
  final Dio _lemonDio;
  final String _vercelProjectId;
  final String? _vercelTeamId;

  AnalyticsDatasource({
    required Dio backendDio,
    required Dio vercelDio,
    required Dio lemonDio,
    required String vercelProjectId,
    String? vercelTeamId,
  })  : _backendDio = backendDio,
        _vercelDio = vercelDio,
        _lemonDio = lemonDio,
        _vercelProjectId = vercelProjectId,
        _vercelTeamId = vercelTeamId;

  Future<UserStats> fetchUserStats() async {
    final res = await _backendDio.get('/api/v1/users/admin/stats');
    return UserStats.fromJson(res.data as Map<String, dynamic>);
  }

  Future<VisitStats> fetchVisitStats() async {
    final now = DateTime.now().toUtc();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    final params = <String, dynamic>{
      'projectId': _vercelProjectId,
      'start': thirtyDaysAgo.toIso8601String(),
      'end': now.toIso8601String(),
      'granularity': 'day',
      if (_vercelTeamId != null) 'teamId': _vercelTeamId,
    };

    final res = await _vercelDio.get('/v1/web/analytics/views', queryParameters: params);
    final data = (res.data['data'] as List<dynamic>).cast<Map<String, dynamic>>();

    final today = DateTime.now().toUtc();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final weekAgo = today.subtract(const Duration(days: 7));

    int totalVisits = 0;
    int todayVisits = 0;
    int weekVisits = 0;
    int monthVisits = 0;

    for (final entry in data) {
      final count = (entry['total'] as num?)?.toInt() ?? 0;
      final key = entry['key'] as String? ?? '';
      totalVisits += count;
      monthVisits += count;
      if (key == todayStr) todayVisits = count;
      final entryDate = DateTime.tryParse(key);
      if (entryDate != null && entryDate.isAfter(weekAgo)) weekVisits += count;
    }

    return VisitStats(
      total: totalVisits,
      today: todayVisits,
      thisWeek: weekVisits,
      thisMonth: monthVisits,
    );
  }

  Future<RevenueStats> fetchRevenueStats() async {
    final results = await Future.wait([
      _lemonDio.get('/v1/subscriptions', queryParameters: {
        'filter[status]': 'active',
        'page[size]': 1,
      }),
      _lemonDio.get('/v1/subscriptions', queryParameters: {
        'filter[status]': 'cancelled',
        'page[size]': 1,
      }),
      _lemonDio.get('/v1/subscriptions', queryParameters: {
        'filter[status]': 'on_trial',
        'page[size]': 1,
      }),
      _lemonDio.get('/v1/orders', queryParameters: {
        'filter[status]': 'paid',
        'page[size]': 100,
      }),
    ]);

    int _pageTotal(Response r) =>
        ((r.data['meta']?['page']?['total']) as num?)?.toInt() ?? 0;

    final active = _pageTotal(results[0]);
    final cancelled = _pageTotal(results[1]);
    final trials = _pageTotal(results[2]);

    final orders = (results[3].data['data'] as List<dynamic>).cast<Map<String, dynamic>>();
    double totalRevenue = 0;
    for (final order in orders) {
      final cents = (order['attributes']?['total'] as num?)?.toInt() ?? 0;
      totalRevenue += cents / 100.0;
    }

    return RevenueStats(
      active: active,
      cancelled: cancelled,
      trials: trials,
      totalRevenueDollars: totalRevenue,
    );
  }
}
