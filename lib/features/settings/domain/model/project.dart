class Project {
  final String id;
  final String name;
  final String localPath;
  final String projectKey;
  final bool hasBugReports;
  final bool hasAnnouncements;

  const Project({
    required this.id,
    required this.name,
    required this.localPath,
    required this.projectKey,
    required this.hasBugReports,
    required this.hasAnnouncements,
  });

  Project copyWith({
    String? name,
    String? localPath,
    bool? hasBugReports,
    bool? hasAnnouncements,
  }) {
    return Project(
      id: id,
      name: name ?? this.name,
      localPath: localPath ?? this.localPath,
      projectKey: projectKey,
      hasBugReports: hasBugReports ?? this.hasBugReports,
      hasAnnouncements: hasAnnouncements ?? this.hasAnnouncements,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'localPath': localPath,
        'projectKey': projectKey,
        'hasBugReports': hasBugReports,
        'hasAnnouncements': hasAnnouncements,
      };

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['id'] as String,
        name: json['name'] as String,
        localPath: json['localPath'] as String,
        projectKey: json['projectKey'] as String,
        hasBugReports: json['hasBugReports'] as bool? ?? false,
        hasAnnouncements: json['hasAnnouncements'] as bool? ?? false,
      );
}
