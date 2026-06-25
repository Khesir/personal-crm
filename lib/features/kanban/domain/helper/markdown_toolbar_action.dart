import 'package:flutter/material.dart';

enum MarkdownToolbarAction {
  bold,
  italic,
  quote,
  code,
  link,
  bulletedList,
  numberedList,
  taskList,
}

class MarkdownActionResult {
  final String text;
  final TextSelection selection;

  const MarkdownActionResult(this.text, this.selection);
}

const _boldDelimiter = '**';
const _italicDelimiter = '*';
const _codeDelimiter = '`';
const _quotePrefix = '> ';
const _bulletedListPrefix = '- ';
const _taskListPrefix = '- [ ] ';

const _boldPlaceholder = 'bold text';
const _italicPlaceholder = 'italic text';
const _codePlaceholder = 'code';
const _linkTextPlaceholder = 'link text';
const _linkUrlPlaceholder = 'url';

/// Applies [action] to [text] given the current [selection], returning the
/// new text and the selection that should be applied afterward.
///
/// Wrap-style actions (bold/italic/code) wrap the selected text in the
/// relevant delimiters, or insert a delimiter pair with a placeholder
/// selected when nothing is selected. Line-prefix actions (quote/bulleted
/// list/numbered list/task list) prefix every line spanned by [selection],
/// or just the current line when nothing is selected. Link inserts a
/// `[text](url)` template with the url portion selected.
MarkdownActionResult applyMarkdownAction(
  String text,
  TextSelection selection,
  MarkdownToolbarAction action,
) {
  switch (action) {
    case MarkdownToolbarAction.bold:
      return _wrapSelection(text, selection, _boldDelimiter, _boldPlaceholder);
    case MarkdownToolbarAction.italic:
      return _wrapSelection(text, selection, _italicDelimiter, _italicPlaceholder);
    case MarkdownToolbarAction.code:
      return _wrapSelection(text, selection, _codeDelimiter, _codePlaceholder);
    case MarkdownToolbarAction.link:
      return _insertLink(text, selection);
    case MarkdownToolbarAction.quote:
      return _prefixLines(text, selection, _quotePrefix);
    case MarkdownToolbarAction.bulletedList:
      return _prefixLines(text, selection, _bulletedListPrefix);
    case MarkdownToolbarAction.numberedList:
      return _prefixLinesNumbered(text, selection);
    case MarkdownToolbarAction.taskList:
      return _prefixLines(text, selection, _taskListPrefix);
  }
}

MarkdownActionResult _wrapSelection(
  String text,
  TextSelection selection,
  String delimiter,
  String placeholder,
) {
  final start = selection.start;
  final end = selection.end;
  final hasSelection = start != end;
  final inner = hasSelection ? text.substring(start, end) : placeholder;

  final newText = text.replaceRange(start, end, '$delimiter$inner$delimiter');
  final innerStart = start + delimiter.length;
  final innerEnd = innerStart + inner.length;

  return MarkdownActionResult(newText, TextSelection(baseOffset: innerStart, extentOffset: innerEnd));
}

MarkdownActionResult _insertLink(String text, TextSelection selection) {
  final start = selection.start;
  final end = selection.end;
  final hasSelection = start != end;
  final linkText = hasSelection ? text.substring(start, end) : _linkTextPlaceholder;

  final template = '[$linkText]($_linkUrlPlaceholder)';
  final newText = text.replaceRange(start, end, template);

  final urlStart = start + '[$linkText]('.length;
  final urlEnd = urlStart + _linkUrlPlaceholder.length;

  return MarkdownActionResult(newText, TextSelection(baseOffset: urlStart, extentOffset: urlEnd));
}

MarkdownActionResult _prefixLines(String text, TextSelection selection, String prefix) {
  final range = _lineRange(text, selection);
  final lines = text.substring(range.start, range.end).split('\n');
  final prefixed = lines.map((line) => '$prefix$line').join('\n');

  final newText = text.replaceRange(range.start, range.end, prefixed);
  final newSelection = TextSelection(
    baseOffset: range.start,
    extentOffset: range.start + prefixed.length,
  );

  return MarkdownActionResult(newText, newSelection);
}

MarkdownActionResult _prefixLinesNumbered(String text, TextSelection selection) {
  final range = _lineRange(text, selection);
  final lines = text.substring(range.start, range.end).split('\n');
  final prefixed = [
    for (var i = 0; i < lines.length; i++) '${i + 1}. ${lines[i]}',
  ].join('\n');

  final newText = text.replaceRange(range.start, range.end, prefixed);
  final newSelection = TextSelection(
    baseOffset: range.start,
    extentOffset: range.start + prefixed.length,
  );

  return MarkdownActionResult(newText, newSelection);
}

class _LineRange {
  final int start;
  final int end;

  const _LineRange(this.start, this.end);
}

_LineRange _lineRange(String text, TextSelection selection) {
  final selectionStart = selection.start;
  final selectionEnd = selection.end;
  final hasSelection = selectionEnd != selectionStart;

  final lineStart = selectionStart == 0 ? 0 : text.lastIndexOf('\n', selectionStart - 1) + 1;
  final searchFrom = hasSelection ? selectionEnd - 1 : selectionStart;
  final nextNewline = text.indexOf('\n', searchFrom);
  final lineEnd = nextNewline == -1 ? text.length : nextNewline;

  return _LineRange(lineStart, lineEnd);
}
