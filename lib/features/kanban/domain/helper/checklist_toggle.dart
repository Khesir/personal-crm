const _acceptanceCriteriaHeadingPattern = r'^#{1,6}\s*acceptance criteria';
final _headingPattern = RegExp(r'^#{1,6}\s');
final _checklistItemPattern = RegExp(r'^(\s*-\s\[)([ xX])(\]\s.*)$');

/// Flips the checkbox state of the [index]th acceptance-criteria checklist
/// item (`- [ ]` / `- [x]`) found under an "Acceptance criteria" heading.
///
/// Returns [body] unchanged if [index] is out of range or no "Acceptance
/// criteria" section exists.
String toggleChecklistItem(String body, int index) {
  final lines = body.split('\n');
  var inAcceptanceCriteria = false;
  var currentIndex = 0;

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];

    if (_headingPattern.hasMatch(line)) {
      inAcceptanceCriteria =
          RegExp(_acceptanceCriteriaHeadingPattern, caseSensitive: false)
              .hasMatch(line);
      continue;
    }

    if (!inAcceptanceCriteria) continue;

    final match = _checklistItemPattern.firstMatch(line);
    if (match == null) continue;

    if (currentIndex == index) {
      final isChecked = match.group(2)!.toLowerCase() == 'x';
      final flipped = isChecked ? ' ' : 'x';
      lines[i] = '${match.group(1)}$flipped${match.group(3)}';
      return lines.join('\n');
    }

    currentIndex++;
  }

  return body;
}
