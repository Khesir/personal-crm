enum AgentSkill {
  createIssues('create-issues', 'Create issues'),
  workIssue('work-issue', 'Work issue'),
  createIssueFromBug('create-issue-from-bug', 'Create issue from bug');

  final String id;
  final String label;

  const AgentSkill(this.id, this.label);

  /// The curated subset of skills offered by [SkillPickerDialog]. Other
  /// skills (e.g. [createIssueFromBug]) are triggered directly from their
  /// own entry points instead.
  static const kPickerSkills = [
    AgentSkill.createIssues,
    AgentSkill.workIssue,
  ];
}
