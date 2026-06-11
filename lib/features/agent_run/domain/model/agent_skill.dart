enum AgentSkill {
  createIssues('create-issues', 'Create issues'),
  workIssue('work-issue', 'Work issue');

  final String id;
  final String label;

  const AgentSkill(this.id, this.label);
}
