import 'package:crm/core/state/stream_state.dart';
import 'package:crm/core/state/state.dart';
import '../../data/datasource/analytics_datasource.dart';
import '../../presentation/state/analytics_state.dart';

class AnalyticsState {
  final AsyncState<UserStats> users;
  final AsyncState<VisitStats> visits;
  final AsyncState<RevenueStats> revenue;

  const AnalyticsState({
    this.users = const AsyncLoading(),
    this.visits = const AsyncLoading(),
    this.revenue = const AsyncLoading(),
  });

  AnalyticsState copyWith({
    AsyncState<UserStats>? users,
    AsyncState<VisitStats>? visits,
    AsyncState<RevenueStats>? revenue,
  }) =>
      AnalyticsState(
        users: users ?? this.users,
        visits: visits ?? this.visits,
        revenue: revenue ?? this.revenue,
      );
}

class AnalyticsController extends StreamState<AnalyticsState> {
  final AnalyticsDatasource _datasource;

  AnalyticsController(this._datasource) : super(const AnalyticsState());

  Future<void> load() async {
    emit(const AnalyticsState());

    _datasource.fetchUserStats().then((data) {
      emit(state.copyWith(users: AsyncData(data)));
    }).catchError((e) {
      emit(state.copyWith(users: AsyncError('Failed to load user stats', e)));
    });

    _datasource.fetchVisitStats().then((data) {
      emit(state.copyWith(visits: AsyncData(data)));
    }).catchError((e) {
      emit(state.copyWith(visits: AsyncError('Failed to load visit stats', e)));
    });

    _datasource.fetchRevenueStats().then((data) {
      emit(state.copyWith(revenue: AsyncData(data)));
    }).catchError((e) {
      emit(state.copyWith(revenue: AsyncError('Failed to load revenue stats', e)));
    });
  }
}
