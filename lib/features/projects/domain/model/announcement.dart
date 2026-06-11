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
