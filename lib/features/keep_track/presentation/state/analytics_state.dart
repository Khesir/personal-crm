class UserStats {
  final int total;
  final int plus;
  final int newThisWeek;
  final int newThisMonth;
  final int newPlusThisWeek;
  final int newPlusThisMonth;

  const UserStats({
    required this.total,
    required this.plus,
    required this.newThisWeek,
    required this.newThisMonth,
    required this.newPlusThisWeek,
    required this.newPlusThisMonth,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) => UserStats(
        total: json['totalUsers'] as int,
        plus: json['plusUsers'] as int,
        newThisWeek: json['newUsersWeek'] as int,
        newThisMonth: json['newUsersMonth'] as int,
        newPlusThisWeek: json['newPlusWeek'] as int,
        newPlusThisMonth: json['newPlusMonth'] as int,
      );
}

class VisitStats {
  final int total;
  final int today;
  final int thisWeek;
  final int thisMonth;

  const VisitStats({
    required this.total,
    required this.today,
    required this.thisWeek,
    required this.thisMonth,
  });
}

class RevenueStats {
  final int active;
  final int cancelled;
  final int trials;
  final double totalRevenueDollars;

  const RevenueStats({
    required this.active,
    required this.cancelled,
    required this.trials,
    required this.totalRevenueDollars,
  });
}

class AnalyticsData {
  final UserStats users;
  final VisitStats visits;
  final RevenueStats revenue;

  const AnalyticsData({
    required this.users,
    required this.visits,
    required this.revenue,
  });
}
