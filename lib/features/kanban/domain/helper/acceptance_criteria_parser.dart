final _headingPattern = RegExp(r'^#{1,6}\s');
final _acceptanceCriteriaHeadingPattern =
    RegExp(r'^#{1,6}\s*acceptance criteria', caseSensitive: false);
final _checklistItemPattern = RegExp(r'^\s*-\s\[([ xX])\]\s(.*)$');

class AcceptanceCriteriaItem {
  final String text;
  final bool checked;

  const AcceptanceCriteriaItem({required this.text, required this.checked});
}

/// Parses checklist items (`- [ ]` / `- [x]`) found under an "Acceptance
/// criteria" heading in [body]. Item indices match the order expected by
/// `toggleChecklistItem`.
List<AcceptanceCriteriaItem> parseAcceptanceCriteria(String body) {
  final items = <AcceptanceCriteriaItem>[];
  var inAcceptanceCriteria = false;

  for (final line in body.split('\n')) {
    if (_headingPattern.hasMatch(line)) {
      inAcceptanceCriteria = _acceptanceCriteriaHeadingPattern.hasMatch(line);
      continue;
    }

    if (!inAcceptanceCriteria) continue;

    final match = _checklistItemPattern.firstMatch(line);
    if (match == null) continue;

    items.add(AcceptanceCriteriaItem(
      text: match.group(2)!,
      checked: match.group(1)!.toLowerCase() == 'x',
    ));
  }

  return items;
}

/// Removes the "Acceptance criteria" heading and its checklist items from
/// [body], leaving the surrounding sections intact.
String removeAcceptanceCriteriaSection(String body) {
  final lines = body.split('\n');
  final result = <String>[];
  var inAcceptanceCriteria = false;

  for (final line in lines) {
    if (_headingPattern.hasMatch(line)) {
      inAcceptanceCriteria = _acceptanceCriteriaHeadingPattern.hasMatch(line);
      if (inAcceptanceCriteria) continue;
    }

    if (inAcceptanceCriteria) continue;

    result.add(line);
  }

  return result.join('\n');
}
