import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crm/features/kanban/domain/helper/markdown_toolbar_action.dart';

void main() {
  group('applyMarkdownAction bold', () {
    test('wraps an existing selection in ** **', () {
      const text = 'hello world';
      const selection = TextSelection(baseOffset: 0, extentOffset: 5);

      final result = applyMarkdownAction(text, selection, MarkdownToolbarAction.bold);

      expect(result.text, '**hello** world');
      expect(result.selection, const TextSelection(baseOffset: 2, extentOffset: 7));
    });

    test('inserts delimiters with placeholder selected when nothing is selected', () {
      const text = 'hello world';
      const selection = TextSelection.collapsed(offset: 5);

      final result = applyMarkdownAction(text, selection, MarkdownToolbarAction.bold);

      expect(result.text, 'hello**bold text** world');
      expect(result.text.substring(result.selection.start, result.selection.end), 'bold text');
    });
  });

  group('applyMarkdownAction italic', () {
    test('wraps an existing selection in * *', () {
      const text = 'hello world';
      const selection = TextSelection(baseOffset: 0, extentOffset: 5);

      final result = applyMarkdownAction(text, selection, MarkdownToolbarAction.italic);

      expect(result.text, '*hello* world');
      expect(result.selection, const TextSelection(baseOffset: 1, extentOffset: 6));
    });

    test('inserts delimiters with placeholder selected when nothing is selected', () {
      const text = '';
      const selection = TextSelection.collapsed(offset: 0);

      final result = applyMarkdownAction(text, selection, MarkdownToolbarAction.italic);

      expect(result.text, '*italic text*');
      expect(result.text.substring(result.selection.start, result.selection.end), 'italic text');
    });
  });

  group('applyMarkdownAction code', () {
    test('wraps an existing selection in ` `', () {
      const text = 'hello world';
      const selection = TextSelection(baseOffset: 6, extentOffset: 11);

      final result = applyMarkdownAction(text, selection, MarkdownToolbarAction.code);

      expect(result.text, 'hello `world`');
      expect(result.selection, const TextSelection(baseOffset: 7, extentOffset: 12));
    });

    test('inserts delimiters with placeholder selected when nothing is selected', () {
      const text = 'abc';
      const selection = TextSelection.collapsed(offset: 3);

      final result = applyMarkdownAction(text, selection, MarkdownToolbarAction.code);

      expect(result.text, 'abc`code`');
      expect(result.text.substring(result.selection.start, result.selection.end), 'code');
    });
  });

  group('applyMarkdownAction quote', () {
    test('prefixes a single selected line with > ', () {
      const text = 'hello world';
      const selection = TextSelection(baseOffset: 0, extentOffset: 5);

      final result = applyMarkdownAction(text, selection, MarkdownToolbarAction.quote);

      expect(result.text, '> hello world');
    });

    test('prefixes every line of a multi-line selection with > ', () {
      const text = 'line one\nline two\nline three';
      const selection = TextSelection(baseOffset: 0, extentOffset: text.length);

      final result = applyMarkdownAction(text, selection, MarkdownToolbarAction.quote);

      expect(result.text, '> line one\n> line two\n> line three');
    });

    test('prefixes the current line when nothing is selected', () {
      const text = 'hello world';
      const selection = TextSelection.collapsed(offset: 3);

      final result = applyMarkdownAction(text, selection, MarkdownToolbarAction.quote);

      expect(result.text, '> hello world');
    });
  });

  group('applyMarkdownAction bulletedList', () {
    test('prefixes a single selected line with - ', () {
      const text = 'item one';
      const selection = TextSelection(baseOffset: 0, extentOffset: 8);

      final result = applyMarkdownAction(text, selection, MarkdownToolbarAction.bulletedList);

      expect(result.text, '- item one');
    });

    test('prefixes every line of a multi-line selection with - ', () {
      const text = 'first\nsecond\nthird';
      const selection = TextSelection(baseOffset: 0, extentOffset: text.length);

      final result = applyMarkdownAction(text, selection, MarkdownToolbarAction.bulletedList);

      expect(result.text, '- first\n- second\n- third');
    });

    test('prefixes the current line when nothing is selected', () {
      const text = 'solo line';
      const selection = TextSelection.collapsed(offset: 0);

      final result = applyMarkdownAction(text, selection, MarkdownToolbarAction.bulletedList);

      expect(result.text, '- solo line');
    });
  });

  group('applyMarkdownAction numberedList', () {
    test('prefixes a single selected line with 1. ', () {
      const text = 'item one';
      const selection = TextSelection(baseOffset: 0, extentOffset: 8);

      final result = applyMarkdownAction(text, selection, MarkdownToolbarAction.numberedList);

      expect(result.text, '1. item one');
    });

    test('numbers every line of a multi-line selection sequentially', () {
      const text = 'first\nsecond\nthird';
      const selection = TextSelection(baseOffset: 0, extentOffset: text.length);

      final result = applyMarkdownAction(text, selection, MarkdownToolbarAction.numberedList);

      expect(result.text, '1. first\n2. second\n3. third');
    });

    test('prefixes the current line when nothing is selected', () {
      const text = 'solo line';
      const selection = TextSelection.collapsed(offset: 0);

      final result = applyMarkdownAction(text, selection, MarkdownToolbarAction.numberedList);

      expect(result.text, '1. solo line');
    });
  });

  group('applyMarkdownAction taskList', () {
    test('prefixes a single selected line with - [ ] ', () {
      const text = 'item one';
      const selection = TextSelection(baseOffset: 0, extentOffset: 8);

      final result = applyMarkdownAction(text, selection, MarkdownToolbarAction.taskList);

      expect(result.text, '- [ ] item one');
    });

    test('prefixes every line of a multi-line selection with - [ ] ', () {
      const text = 'first\nsecond';
      const selection = TextSelection(baseOffset: 0, extentOffset: text.length);

      final result = applyMarkdownAction(text, selection, MarkdownToolbarAction.taskList);

      expect(result.text, '- [ ] first\n- [ ] second');
    });

    test('prefixes the current line when nothing is selected', () {
      const text = 'solo line';
      const selection = TextSelection.collapsed(offset: 0);

      final result = applyMarkdownAction(text, selection, MarkdownToolbarAction.taskList);

      expect(result.text, '- [ ] solo line');
    });
  });

  group('applyMarkdownAction link', () {
    test('uses the current selection as link text and selects the url placeholder', () {
      const text = 'check this out';
      const selection = TextSelection(baseOffset: 6, extentOffset: 10);

      final result = applyMarkdownAction(text, selection, MarkdownToolbarAction.link);

      expect(result.text, 'check [this](url) out');
      expect(result.text.substring(result.selection.start, result.selection.end), 'url');
    });

    test('inserts a placeholder text and selects the url when nothing is selected', () {
      const text = '';
      const selection = TextSelection.collapsed(offset: 0);

      final result = applyMarkdownAction(text, selection, MarkdownToolbarAction.link);

      expect(result.text, '[link text](url)');
      expect(result.text.substring(result.selection.start, result.selection.end), 'url');
    });
  });
}
