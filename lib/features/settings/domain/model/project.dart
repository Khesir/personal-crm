class Project {
  final String id;
  final String name;
  final String localPath;
  final String projectKey;

  const Project({
    required this.id,
    required this.name,
    required this.localPath,
    required this.projectKey,
  });

  Project copyWith({
    String? name,
    String? localPath,
  }) {
    return Project(
      id: id,
      name: name ?? this.name,
      localPath: localPath ?? this.localPath,
      projectKey: projectKey,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'localPath': localPath,
        'projectKey': projectKey,
      };

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['id'] as String,
        name: json['name'] as String,
        localPath: json['localPath'] as String,
        projectKey: json['projectKey'] as String,
      );
}
