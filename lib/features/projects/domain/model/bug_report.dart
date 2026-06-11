enum BugSeverity {
  info,
  warning,
  error,
  critical;

  String get value => name;

  String get label => switch (this) {
        BugSeverity.info => 'Info',
        BugSeverity.warning => 'Warning',
        BugSeverity.error => 'Error',
        BugSeverity.critical => 'Critical',
      };

  static BugSeverity fromValue(String? value) => BugSeverity.values.firstWhere(
        (e) => e.value == value,
        orElse: () => BugSeverity.error,
      );
}

class BugReport {
  final String id;
  final BugSeverity severity;
  final String message;
  final String? stackTrace;
  final String? source;
  final bool resolved;
  final DateTime createdAt;

  const BugReport({
    required this.id,
    required this.severity,
    required this.message,
    this.stackTrace,
    this.source,
    required this.resolved,
    required this.createdAt,
  });

  factory BugReport.fromJson(Map<String, dynamic> json) => BugReport(
        id: (json['id'] ?? json['_id']) as String,
        severity: BugSeverity.fromValue(json['severity'] as String?),
        message: json['message'] as String,
        stackTrace: json['stackTrace'] as String?,
        source: json['source'] as String?,
        resolved: json['resolved'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
