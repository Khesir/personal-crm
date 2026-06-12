enum HealthStatus {
  checking,
  online,
  offline,
  error;

  String get value => switch (this) {
        HealthStatus.checking => 'checking',
        HealthStatus.online => 'online',
        HealthStatus.offline => 'offline',
        HealthStatus.error => 'error',
      };

  static HealthStatus fromValue(String value) => switch (value) {
        'online' => HealthStatus.online,
        'offline' => HealthStatus.offline,
        'error' => HealthStatus.error,
        _ => HealthStatus.checking,
      };
}
