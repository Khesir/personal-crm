class Project {
  final String id;
  final String name;
  final String localPath;
  final String projectKey;

  /// Cached filename (e.g. `icon.png`) of the icon stored at
  /// `<localPath>/.avyn/<iconFileName>`, or `null` if none is set. This is a
  /// cache of `.avyn/project.json`'s `icon` field — see
  /// `docs/adr/0004-avyn-folder-project-metadata.md`.
  final String? iconFileName;

  const Project({
    required this.id,
    required this.name,
    required this.localPath,
    required this.projectKey,
    this.iconFileName,
  });

  Project copyWith({
    String? name,
    String? localPath,
    // Tri-state: omit to leave iconFileName untouched, or pass a callback
    // (even one that returns null) to explicitly set/clear it.
    String? Function()? iconFileName,
  }) {
    return Project(
      id: id,
      name: name ?? this.name,
      localPath: localPath ?? this.localPath,
      projectKey: projectKey,
      iconFileName: iconFileName != null ? iconFileName() : this.iconFileName,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'localPath': localPath,
        'projectKey': projectKey,
        'iconFileName': iconFileName,
      };

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['id'] as String,
        name: json['name'] as String,
        localPath: json['localPath'] as String,
        projectKey: json['projectKey'] as String,
        iconFileName: json['iconFileName'] as String?,
      );
}
