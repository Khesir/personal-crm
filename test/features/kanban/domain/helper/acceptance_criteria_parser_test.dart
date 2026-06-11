import 'package:flutter_test/flutter_test.dart';
import 'package:crm/features/kanban/domain/helper/acceptance_criteria_parser.dart';

void main() {
  group('removeAcceptanceCriteriaSection', () {
    test('removes the Acceptance criteria heading and its items', () {
      const body = '''
## What to build

Some description.

## Acceptance criteria

- [ ] First item
- [x] Second item

## Notes

More text.
''';

      final result = removeAcceptanceCriteriaSection(body);

      expect(result, isNot(contains('Acceptance criteria')));
      expect(result, isNot(contains('First item')));
      expect(result, contains('## What to build'));
      expect(result, contains('## Notes'));
      expect(result, contains('More text.'));
    });

    test('returns body unchanged when there is no Acceptance criteria heading', () {
      const body = '''
## What to build

Some description.
''';

      final result = removeAcceptanceCriteriaSection(body);

      expect(result, body);
    });
  });

  group('parseAcceptanceCriteria', () {
    test('extracts checklist items under the Acceptance criteria heading', () {
      const body = '''
## What to build

Some description.

## Acceptance criteria

- [ ] First item
- [x] Second item

## Notes

More text.
''';

      final items = parseAcceptanceCriteria(body);

      expect(items, hasLength(2));
      expect(items[0].text, 'First item');
      expect(items[0].checked, isFalse);
      expect(items[1].text, 'Second item');
      expect(items[1].checked, isTrue);
    });

    test('returns empty list when there is no Acceptance criteria heading', () {
      const body = '''
## What to build

- [ ] Not under acceptance criteria
''';

      final items = parseAcceptanceCriteria(body);

      expect(items, isEmpty);
    });

    test('stops collecting items at the next heading', () {
      const body = '''
## Acceptance criteria

- [ ] Item one

## Tests required

- [ ] Not a criteria item
''';

      final items = parseAcceptanceCriteria(body);

      expect(items, hasLength(1));
      expect(items[0].text, 'Item one');
    });
  });
}
