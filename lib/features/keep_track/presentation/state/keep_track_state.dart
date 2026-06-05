enum AnnouncementType {
  info,
  warning,
  release,
  update;

  String get value => name;

  String get label => switch (this) {
        AnnouncementType.info => 'Info',
        AnnouncementType.warning => 'Warning',
        AnnouncementType.release => 'Release',
        AnnouncementType.update => 'Update',
      };
}

enum PlatformStatus {
  available,
  comingSoon,
  notAvailable;

  String get value => switch (this) {
        PlatformStatus.available => 'available',
        PlatformStatus.comingSoon => 'coming_soon',
        PlatformStatus.notAvailable => 'not_available',
      };

  String get label => switch (this) {
        PlatformStatus.available => 'Available',
        PlatformStatus.comingSoon => 'Coming Soon',
        PlatformStatus.notAvailable => 'Not Available',
      };

  static PlatformStatus fromValue(String? value) => switch (value) {
        'available' => PlatformStatus.available,
        'coming_soon' => PlatformStatus.comingSoon,
        'not_available' => PlatformStatus.notAvailable,
        _ => PlatformStatus.comingSoon,
      };
}

class WindowsPlatformConfig {
  final PlatformStatus status;
  final String? downloadUrl;

  const WindowsPlatformConfig({required this.status, this.downloadUrl});

  factory WindowsPlatformConfig.fromJson(Map<String, dynamic>? json) =>
      WindowsPlatformConfig(
        status: PlatformStatus.fromValue(json?['status'] as String?),
        downloadUrl: json?['downloadUrl'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'status': status.value,
        if (downloadUrl != null) 'downloadUrl': downloadUrl,
      };
}

class AndroidPlatformConfig {
  final PlatformStatus status;
  final String? apkUrl;
  final String? playStoreUrl;

  const AndroidPlatformConfig({
    required this.status,
    this.apkUrl,
    this.playStoreUrl,
  });

  factory AndroidPlatformConfig.fromJson(Map<String, dynamic>? json) =>
      AndroidPlatformConfig(
        status: PlatformStatus.fromValue(json?['status'] as String?),
        apkUrl: json?['apkUrl'] as String?,
        playStoreUrl: json?['playStoreUrl'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'status': status.value,
        if (apkUrl != null) 'apkUrl': apkUrl,
        if (playStoreUrl != null) 'playStoreUrl': playStoreUrl,
      };
}

class StorePlatformConfig {
  final PlatformStatus status;
  final String? storeUrl;

  const StorePlatformConfig({required this.status, this.storeUrl});

  factory StorePlatformConfig.fromJson(Map<String, dynamic>? json) =>
      StorePlatformConfig(
        status: PlatformStatus.fromValue(json?['status'] as String?),
        storeUrl: json?['storeUrl'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'status': status.value,
        if (storeUrl != null) 'storeUrl': storeUrl,
      };
}

class ReleasePlatforms {
  final WindowsPlatformConfig windows;
  final AndroidPlatformConfig android;
  final StorePlatformConfig macos;
  final StorePlatformConfig ios;

  const ReleasePlatforms({
    required this.windows,
    required this.android,
    required this.macos,
    required this.ios,
  });

  factory ReleasePlatforms.fromJson(Map<String, dynamic>? json) =>
      ReleasePlatforms(
        windows: WindowsPlatformConfig.fromJson(
            json?['windows'] as Map<String, dynamic>?),
        android: AndroidPlatformConfig.fromJson(
            json?['android'] as Map<String, dynamic>?),
        macos: StorePlatformConfig.fromJson(
            json?['macos'] as Map<String, dynamic>?),
        ios: StorePlatformConfig.fromJson(
            json?['ios'] as Map<String, dynamic>?),
      );

  static ReleasePlatforms get defaults => ReleasePlatforms(
        windows: WindowsPlatformConfig(status: PlatformStatus.comingSoon),
        android: AndroidPlatformConfig(status: PlatformStatus.comingSoon),
        macos: StorePlatformConfig(status: PlatformStatus.comingSoon),
        ios: StorePlatformConfig(status: PlatformStatus.comingSoon),
      );
}

class AppRelease {
  final String id;
  final String version;
  final String title;
  final String body;
  final ReleasePlatforms platforms;
  final bool published;
  final DateTime? publishedAt;
  final DateTime createdAt;

  const AppRelease({
    required this.id,
    required this.version,
    required this.title,
    required this.body,
    required this.platforms,
    required this.published,
    this.publishedAt,
    required this.createdAt,
  });

  factory AppRelease.fromJson(Map<String, dynamic> json) => AppRelease(
        id: (json['id'] ?? json['_id']) as String,
        version: json['version'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        platforms: ReleasePlatforms.fromJson(
            json['platforms'] as Map<String, dynamic>?),
        published: json['published'] as bool? ?? false,
        publishedAt: json['publishedAt'] != null
            ? DateTime.parse(json['publishedAt'] as String)
            : null,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class Announcement {
  final String id;
  final String title;
  final String body;
  final AnnouncementType type;
  final bool published;
  final String? ctaLabel;
  final String? ctaUrl;
  final DateTime? publishedAt;
  final DateTime createdAt;

  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.published,
    this.ctaLabel,
    this.ctaUrl,
    this.publishedAt,
    required this.createdAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) => Announcement(
        id: (json['id'] ?? json['_id']) as String,
        title: json['title'] as String,
        body: json['body'] as String,
        type: AnnouncementType.values.firstWhere(
          (e) => e.value == json['type'],
          orElse: () => AnnouncementType.info,
        ),
        published: json['published'] as bool? ?? false,
        ctaLabel: json['ctaLabel'] as String?,
        ctaUrl: json['ctaUrl'] as String?,
        publishedAt: json['publishedAt'] != null
            ? DateTime.parse(json['publishedAt'] as String)
            : null,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
